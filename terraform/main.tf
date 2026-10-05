# Networks, security groups
resource "yandex_vpc_network" "k8s" {
    name = "bulletin-k8s"
}

resource "yandex_vpc_subnet" "k8s-subnet-private" {
    name = "bulletin-k8s"
    zone = var.server_zone
    network_id = yandex_vpc_network.k8s.id
    v4_cidr_blocks = ["10.10.0.0/24"]
    route_table_id = yandex_vpc_route_table.k8s-private.id
}

resource "yandex_vpc_gateway" "k8s-gateway" {
  name = "bulletin-board-nat"

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "k8s-private" {
  name       = "bulletin-board-k8s-private"
  network_id = yandex_vpc_network.k8s.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.k8s-gateway.id
  }
}

resource "yandex_vpc_security_group" "k8s" {
  network_id = yandex_vpc_network.k8s.id
  name = "k8s"
  description = "kubernetes network security group"
  folder_id = var.yc_folder_id
}

resource "yandex_vpc_security_group_rule" "rule1" {
  security_group_binding = yandex_vpc_security_group.k8s.id
  direction              = "ingress"
  description            = "rule1 description"
  v4_cidr_blocks         = ["10.0.1.0/24", "10.0.2.0/24"] 
  port                   = 8080
  protocol               = "TCP"
}

resource "yandex_vpc_security_group_rule" "rule2" {
  security_group_binding = yandex_vpc_security_group.k8s.id
  direction              = "egress"
  description            = "rule2 description"
  v4_cidr_blocks         = ["10.0.1.0/24"]
  from_port              = 8090
  to_port                = 8099
  protocol               = "UDP"
}

resource "yandex_vpc_network" "lab-net" {
  name = "lab-network"
}