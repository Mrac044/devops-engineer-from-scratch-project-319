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
  
  ingress {

  }

  egress {

  }
}