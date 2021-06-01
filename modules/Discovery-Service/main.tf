
resource "aws_service_discovery_private_dns_namespace" "PrivateNamespace" {
  name = var.Namespace
  vpc  = var.vpc_id
}

resource "aws_service_discovery_service" "DiscoveryService" {
  name = var.DiscoveryName

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.PrivateNamespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    dns_records {
      ttl  = 10
      type = "SRV"
    }

    routing_policy = "MULTIVALUE"
  }
}