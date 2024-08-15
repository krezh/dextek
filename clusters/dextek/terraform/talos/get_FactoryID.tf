data "http" "factory_id" {
  url = var.talos_factory_schematic_endpoint

  request_headers = {
    Accept = "application/json"
  }

  request_body       = jsonencode(yamldecode(file("extensions.yaml")))
  method             = "POST"
  request_timeout_ms = 10000 # 10 seconds
  retry {
    attempts = 5
  }

  lifecycle {
    postcondition {
      condition     = contains([201, 204], self.status_code)
      error_message = "Status code invalid"
    }
  }
}

output "factory_id" {
  value = jsondecode(data.http.factory_id.response_body).id
}
