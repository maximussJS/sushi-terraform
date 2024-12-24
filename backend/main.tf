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
  server_type = "cpx11"         # Adjust as needed (cpx11, cpx21, etc.)
  image       = "ubuntu-22.04"  # Use the desired base image
  location    = "nbg1"          # Location (e.g., nbg1, fsn1, hel1)
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id]
}

# Upload certificates to the server
resource "null_resource" "upload_certs" {
  depends_on = [hcloud_server.sushi_backend]

  provisioner "file" {
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

    source      = "certs"       # Ensure this path is correct relative to your Terraform working directory
    destination = "/certs/"     # This matches the Docker volume mount path
  }

  # Set appropriate permissions after uploading
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
      # Set execute permissions for the certs directory
      "chmod 755 /certs",

      # Set read permissions for certificate files
      "chmod 644 /certs/*",

      # Optional: Verify permissions
      "ls -ld /certs",
      "ls -l /certs"
    ]
  }
}

# Setup Docker and deploy the container with environment variables and mounted certs
resource "null_resource" "docker_setup" {
  depends_on = [
    hcloud_server.sushi_backend,
    null_resource.upload_certs
  ]

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

      # Create the certificates directory if it doesn't exist
      "mkdir -p /certs",

      # Pull the specified Docker image
      "docker pull ${var.image}",

      # Run the Docker container with environment variables and mounted certs directory
      "docker run -d -p 8080:8080 \\",
      "  --env POSTGRES_DSN='${replace(var.postgres_dsn, "'", "\\'")}' \\",
      "  --env CLOUDINARY_URL='${replace(var.cloudinary_url, "'", "\\'")}' \\",
      "  --env TELEGRAM_BOT_TOKEN='${replace(var.telegram_bot_token, "'", "\\'")}' \\",
      "  --env TELEGRAM_ORDERS_CHAT_ID='${replace(var.telegram_orders_chat_id, "'", "\\'")}' \\",
      "  --env TELEGRAM_DELIVERY_CHAT_ID='${replace(var.telegram_delivery_chat_id, "'", "\\'")}' \\",
      "  --env APP_ENV='${replace(var.app_env, "'", "\\'")}' \\",
      "  --env ADMIN_PASSWORD='${replace(var.admin_password, "'", "\\'")}' \\",
      "  --env JWT_SECRET_KEY='${replace(var.jwt_secret_key, "'", "\\'")}' \\",
      "  --env SSL_CERT_PATH='${replace(var.ssl_cert_path, "'", "\\'")}' \\",
      "  --env SSL_KEY_PATH='${replace(var.ssl_key_path, "'", "\\'")}' \\",
      "  -v /certs:/app/certs \\",
      "  ${var.image}"
    ]
  }
}
