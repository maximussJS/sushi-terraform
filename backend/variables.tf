variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "hcloud_ssh_key_fingerprint" {
  description = "SSH key fingerprint to use for the server"
  type        = string
  sensitive   = true
}

variable "server_name" {
  description = "Sushi Backend API"
  type        = string
  default     = "sushi-backend-api"
}

variable "image" {
  description = "Golang Docker image to run"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private SSH key for connecting to the server"
  type        = string
  default     = "~/.ssh/hetzner_id_rsa"
}

variable "private_key_content" {
  description = "Content of the private SSH key for connecting to the server"
  type        = string
  sensitive   = true
  default     = ""
}


# PostgreSQL Data Source Name
variable "postgres_dsn" {
  description = "PostgreSQL Data Source Name"
  type        = string
}

# Cloudinary URL
variable "cloudinary_url" {
  description = "Cloudinary URL for media management"
  type        = string
}

# Telegram Bot Token
variable "telegram_bot_token" {
  description = "Token for the Telegram bot"
  type        = string
  sensitive   = true
}

# Telegram Orders Chat ID
variable "telegram_orders_chat_id" {
  description = "Chat ID for Telegram orders notifications"
  type        = string
}

# Telegram Delivery Chat ID
variable "telegram_delivery_chat_id" {
  description = "Chat ID for Telegram delivery notifications"
  type        = string
}

# Application Environment
variable "app_env" {
  description = "Application environment (e.g., development, production)"
  type        = string
  default     = "development"
}

# Administrator Password
variable "admin_password" {
  description = "Password for the administrator account"
  type        = string
  sensitive   = true
}

# JWT Secret Key
variable "jwt_secret_key" {
  description = "Secret key for JWT token generation"
  type        = string
  sensitive   = true
}

variable "ssl_cert_path" {
    description = "Path to the SSL certificate"
    type        = string
    default     = "/app/certs/cert.pem"
}

variable "ssl_key_path" {
    description = "Path to the SSL private key"
    type        = string
    default     = "/app/certs/priv.pem"
}
