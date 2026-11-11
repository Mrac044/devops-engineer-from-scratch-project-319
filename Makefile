.PHONY: build

docker-build:
	docker build -t bulletin-board:latest .

docker-run:
	docker run -d -p 8080:8080 --name bulletin-board

docker-stop:
	docker stop bulletin-board

.PHONY: terraform-syntax terraform-plan terraform-check terraform-apply terraform-destroy envfile configmap secret deploy

PROJECT_ROOT := $(CURDIR)
TF_DIR := $(PROJECT_ROOT)/terraform
K8S_DIR := $(PROJECT_ROOT)/k8s

envfile:
	@set -eu; \
	command -v terraform >/dev/null; \
	command -v jq >/dev/null; \
	cd "$(TF_DIR)"; \
	outputs="$$(terraform output --json)"; \
	dotenv="$$(printf '%s' "$$outputs" | jq -er 'def required_output($$name): .[$$name].value // error("missing Terraform output: " + $$name); ["DB_HOST=\(required_output("database_host"))", "DB_NAME=\(required_output("database_name"))", "DB_USERNAME=\(required_output("database_username"))", "DB_PASSWORD=\(required_output("database_password"))", "S3_ACCESS_KEY=\(required_output("s3_access_key"))", "S3_SECRET_KEY=\(required_output("s3_secret_key"))", "S3_BUCKET=\(required_output("s3_bucket"))", "S3_REGION=\(required_output("s3_region"))", "S3_ENDPOINT=\(required_output("s3_endpoint"))"] | join("\n")')"; \
	umask 077; \
	touch "$(PROJECT_ROOT)/.env"; \
	chmod 600 "$(PROJECT_ROOT)/.env"; \
	printf '%s\n' "$$dotenv" > "$(PROJECT_ROOT)/.env"

terraform-syntax:
	cd "$(TF_DIR)" && terraform validate

terraform-plan:
	cd "$(TF_DIR)" && terraform plan

terraform-check:
	cd "$(TF_DIR)" && terraform validate && TF_VAR_server_name="check" terraform plan

terraform-apply:
	cd "$(TF_DIR)" && terraform apply

terraform-destroy:
	cd "$(TF_DIR)" && terraform destroy

k8s-configmap: envfile
	@set -eu; \
	command -v kubectl >/dev/null; \
	command -v envsubst >/dev/null; \
	set -a; \
	. "$(PROJECT_ROOT)/.env"; \
	set +a; \
	export DB_HOST DB_NAME S3_BUCKET S3_REGION S3_ENDPOINT; \
	envsubst '$${DB_HOST} $${DB_NAME} $${S3_BUCKET} $${S3_REGION} $${S3_ENDPOINT}' < "$(K8S_DIR)/app-configmap.yml" | kubectl apply -f -

k9s-secret: envfile
	@set -eu; \
	command -v kubectl >/dev/null; \
	command -v envsubst >/dev/null; \
	set -a; \
	. "$(PROJECT_ROOT)/.env"; \
	set +a; \
	export DB_USERNAME DB_PASSWORD S3_ACCESS_KEY S3_SECRET_KEY; \
	envsubst '$${DB_USERNAME} $${DB_PASSWORD} $${S3_ACCESS_KEY} $${S3_SECRET_KEY}' < "$(K8S_DIR)/templates/secret.yml.tpl" | kubectl apply -f -

k8s-apply: envfile
	kubectl apply -f "$(K8S_DIR)/namespace.yml"
	$(MAKE) k8s-configmap
	$(MAKE) k9s-secret
	kubectl apply -f "$(K8S_DIR)/deployment.yml"
	kubectl apply -f "$(K8S_DIR)/service.yml"
	kubectl apply -f "$(K8S_DIR)/nginx-configmap.yml"

