# main.tf

terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.46.1"
    }
  }

  # Optional: Specify Terraform backend if needed
  # backend "..." { ... }
}

provider "hcloud" {
  token = var.hcloud_token
}

# Fetch the SSH key by fingerprint
data "hcloud_ssh_key" "ssh_key" {
  fingerprint = var.hcloud_ssh_key_fingerprint
}

# Create the Hetzner server
resource "hcloud_server" "sushi_backend" {
  name        = var.server_name
  server_type = "cpx11"       # Adjust as needed (cx11, cx21, etc.)
  image       = "ubuntu-22.04" # Use the desired base image
  location    = "nbg1"         # Location (e.g., nbg1, fsn1, hel1)
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id]

  # Optional: Add other server configurations as needed
}

# Setup Docker and deploy the container with environment variables
resource "null_resource" "docker_setup" {
  depends_on = [hcloud_server.sushi_backend]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = hcloud_server.sushi_backend.ipv4_address
      user        = "root"
      private_key = (
      var.private_key_content != "" ?
      var.private_key_content :
      file(var.private_key_path)
      )
    }

    inline = [
      # Update and install Docker
      "apt-get update && apt-get install -y docker.io",

      # Pull the specified Docker image
      "docker pull ${var.image}",

      # Run the Docker container with environment variables
      "docker run -d -p 8080:8080 \\",
      "  -e POSTGRES_DSN='${replace(var.postgres_dsn, "'", "\\'")}' \\",
      "  -e CLOUDINARY_URL='${replace(var.cloudinary_url, "'", "\\'")}' \\",
      "  -e TELEGRAM_BOT_TOKEN='${replace(var.telegram_bot_token, "'", "\\'")}' \\",
      "  -e TELEGRAM_ORDERS_CHAT_ID='${replace(var.telegram_orders_chat_id, "'", "\\'")}' \\",
      "  -e TELEGRAM_DELIVERY_CHAT_ID='${replace(var.telegram_delivery_chat_id, "'", "\\'")}' \\",
      "  -e APP_ENV='${replace(var.app_env, "'", "\\'")}' \\",
      "  -e ADMIN_PASSWORD='${replace(var.admin_password, "'", "\\'")}' \\",
      "  -e JWT_SECRET_KEY='${replace(var.jwt_secret_key, "'", "\\'")}' \\",
      "  ${var.image}"
    ]
  }
}
