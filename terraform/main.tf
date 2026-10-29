# Networks, security groups

resource "yandex_vpc_network" "k8s" {
    name = "bulletin_k8s"
}

resource "yandex_vpc_subnet" "k8s_subnet_private" {
    name = "bulletin_k8s"
    zone = var.server_zone
    network_id = yandex_vpc_network.k8s.id
    v4_cidr_blocks = ["10.10.0.0/24"]
    route_table_id = yandex_vpc_route_table.k8s_private.id
}

resource "yandex_vpc_gateway" "k8s_gateway" {
  name = "bulletin-board-nat"

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "k8s_private" {
  name       = "bulletin_board_k8s_private"
  network_id = yandex_vpc_network.k8s.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.k8s_gateway.id
  }
}

# Security groups

resource "yandex_vpc_security_group" "k8s" {
  network_id = yandex_vpc_network.k8s.id
  name = "k8s"
  description = "kubernetes network security group"
  folder_id = var.yc_folder_id
}

resource "yandex_vpc_security_group" "mdb" {
  network_id = yandex_vpc_network.k8s.id
  name = "postgresql_app"
  description = "Managed PostgreSQL access security group"
  folder_id = var.yc_folder_id
}

resource "yandex_vpc_security_group_rule" "k8s_http" {
  security_group_binding = yandex_vpc_security_group.k8s.id

  direction       = "ingress"
  protocol        = "TCP"
  v4_cidr_blocks  = ["0.0.0.0/0"]
  port            = 80

  description = "HTTP from internet"
}

resource "yandex_vpc_security_group_rule" "k8s_https" {
  security_group_binding = yandex_vpc_security_group.k8s.id

  direction       = "ingress"
  protocol        = "TCP"
  v4_cidr_blocks  = ["0.0.0.0/0"]
  port            = 443

  description = "HTTPS from internet"
}

resource "yandex_vpc_security_group_rule" "mdb_ingress" {
  security_group_binding = yandex_vpc_security_group.mdb.id

  direction         = "ingress"
  protocol          = "TCP"
  security_group_id = yandex_vpc_security_group.k8s.id
  port              = 6432

  description = "PostgreSQL access from Kubernetes"
}

resource "yandex_vpc_security_group_rule" "k8s_egress" {
  security_group_binding = yandex_vpc_security_group.k8s.id

  direction       = "egress"
  protocol        = "ANY"
  v4_cidr_blocks  = ["0.0.0.0/0"]

  description = "Allow outbound traffic"
}

# Service mdb and mk8s accounts

resource "yandex_iam_service_account" "k8s" {
  name = "k8s"
  description = "Service Managed kubernetes account"
}

resource "yandex_iam_service_account" "k8s_nodes" {
  name = "k8s-nodes"
  description = "Service Managed kubernetes worker nodes"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_agent" {
  folder_id = var.yc_folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_public_admin" {
  folder_id = var.yc_folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "nodes_images_puller" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes.id}"
}

resource "yandex_iam_service_account" "app" {
  name        = "bulletin-board-app"
  description = "Service account for bulletin board application"
}

resource "yandex_resourcemanager_folder_iam_member" "app_storage_editor" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.app.id}"
}

resource "yandex_iam_service_account_static_access_key" "app" {
  service_account_id = yandex_iam_service_account.app.id
  description        = "Static access key for bulletin board S3"
}

# Managed kubernetes cluster

resource "yandex_kubernetes_cluster" "k8s" {
  name = "k8s-cluster"
  description = "Managed kubernetes cluster for bulletin board"

  network_id = yandex_vpc_network.k8s.id

  master {
    zonal {
      zone = var.server_zone
      subnet_id = yandex_vpc_subnet.k8s_subnet_private.id
    }
    public_ip = true
    security_group_ids = [yandex_vpc_security_group.k8s.id]
  }

  service_account_id = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s_nodes.id

  release_channel = "STABLE"

  cluster_ipv4_ranges = ["10.20.0.0/16"]
  service_ipv4_range = "10.30.0.0/16"

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_agent,
    yandex_resourcemanager_folder_iam_member.k8s_public_admin,
    yandex_resourcemanager_folder_iam_member.nodes_images_puller
  ]
}

# Managed database cluster

module "yandex_postgresql" {
  source = "github.com/terraform-yc-modules/terraform-yc-postgresql?ref=1.0.2"

  network_id = yandex_vpc_network.k8s.id

  name        = "bulletin-board-postgresql"
  description = "PostgreSQL cluster for bulletin board application"

  hosts_definition = [
    {
      zone             = var.server_zone
      assign_public_ip = false
      subnet_id        = yandex_vpc_subnet.k8s_subnet_private.id
      resources = {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 20
    }
    }
  ]

  postgresql_config = {
    max_connections = 100
  }

  databases = [
    {
      name   = var.db_name
      owner  = var.db_user
      lc_collate = "en_US.UTF-8"
      lc_type    = "en_US.UTF-8"
    }
  ]

  owners = [
    {
      name       = var.db_user
      conn_limit = 15
    }
  ]
}

# Kubernetes node group

resource "yandex_kubernetes_node_group" "workers" {
  cluster_id = yandex_kubernetes_cluster.k8s.id
  name       = "workers"
  version    = var.kubernetes_version

  instance_template {
    platform_id = var.node_platform_id

    resources {
      cores  = var.node_cpu
      memory = var.node_ram
    }

    boot_disk {
      type = "network-ssd"
      size = var.node_disk_size
    }

    network_interface {
      nat        = false
      subnet_ids = [yandex_vpc_subnet.k8s_subnet_private.id]

      security_group_ids = [
        yandex_vpc_security_group.k8s.id
      ]
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale {
      size = var.node_count
    }
  }

  allocation_policy {
    location {
      zone = var.server_zone
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }

  depends_on = [
    yandex_kubernetes_cluster.k8s
  ]
}

# Application S3

resource "yandex_storage_bucket" "app" {
  bucket = "bulletin-board-s3"
}

# Lockbox

resource "yandex_lockbox_secret" "app" {
  name        = "bulletin_board_app"
  description = "Secrets for bulletin board application"
}