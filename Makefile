ANSIBLE_DIR := ansible
PLAYBOOK_DIR := playbooks
INVENTORY := inventory.ini
VAULT_PASSWORD_FILE := $(PLAYBOOK_DIR)/vault_pass.txt

.PHONY: build

docker-build:
	docker build -t bulletin-board:latest .

docker-run:
	docker run -d -p 8080:8080 --name bulletin-board

docker-stop:
	docker stop bulletin-board

setup-roles:
	ansible-galaxy install -r requirements.yml --force

lint:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/application-playbook.yml --vault-password-file $(VAULT_PASSWORD_FILE) --syntax-check
	@echo "---------------"
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/observability-playbook.yml --vault-password-file $(VAULT_PASSWORD_FILE) --syntax-check

smoke:
	cd $(ANSIBLE_DIR) && ansible all -i $(INVENTORY) -m ping --vault-password-file $(VAULT_PASSWORD_FILE)
	cd $(ANSIBLE_DIR) && ansible webservers -i $(INVENTORY) -m shell -a "curl -fsS http://127.0.0.1/ >/dev/null" --vault-password-file $(VAULT_PASSWORD_FILE)
	cd $(ANSIBLE_DIR) && ansible webservers -i $(INVENTORY) -m shell -a "curl -fsS http://127.0.0.1:9090/actuator/health/readiness >/dev/null" --vault-password-file $(VAULT_PASSWORD_FILE)
	cd $(ANSIBLE_DIR) && ansible monitoring -i $(INVENTORY) -m shell -a "curl -fsS http://127.0.0.1:9090/-/healthy >/dev/null" --vault-password-file $(VAULT_PASSWORD_FILE)
	cd $(ANSIBLE_DIR) && ansible monitoring -i $(INVENTORY) -m shell -a "curl -fsS http://127.0.0.1:3100/ready >/dev/null" --vault-password-file $(VAULT_PASSWORD_FILE)
	cd $(ANSIBLE_DIR) && ansible monitoring -i $(INVENTORY) -m shell -a "curl -fsS http://127.0.0.1:3000/api/health >/dev/null" --vault-password-file $(VAULT_PASSWORD_FILE)

deploy:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/application-playbook.yml --vault-password-file $(VAULT_PASSWORD_FILE)

observ:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_DIR)/observability-playbook.yml --vault-password-file $(VAULT_PASSWORD_FILE)
