#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Installing ZeroSSL Certificate on AWS EC2 ===${NC}"

# Get the instance IP from Terraform output
INSTANCE_IP=$(cd Terraform && terraform output -raw instance_public_ip)

if [ -z "$INSTANCE_IP" ]; then
  echo "Failed to get instance IP. Make sure your Terraform infrastructure is deployed."
  exit 1
fi

# Check SSH key permissions and fix if needed
KEY_PATH="Terraform/portfolio-key"
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
  chmod 600 $KEY_PATH
fi

# Check if SSL files exist in the ssl directory
SSL_DIR="./ssl"
if [ ! -d "$SSL_DIR" ]; then
  echo -e "${YELLOW}SSL directory not found. Creating one...${NC}"
  mkdir -p "$SSL_DIR"
  echo -e "${YELLOW}Please place your ZeroSSL certificate files in the '$SSL_DIR' directory:${NC}"
  echo "  - certificate.crt (Your domain certificate)"
  echo "  - private.key (Your private key)"
  echo "  - ca_bundle.crt (Certificate Authority bundle)"
  exit 1
fi

# Check for required SSL files
if [ ! -f "$SSL_DIR/certificate.crt" ] || [ ! -f "$SSL_DIR/private.key" ] || [ ! -f "$SSL_DIR/ca_bundle.crt" ]; then
  echo -e "${YELLOW}Missing SSL certificate files in '$SSL_DIR'.${NC}"
  echo "Please ensure you have the following files:"
  echo "  - certificate.crt (Your domain certificate)"
  echo "  - private.key (Your private key)"
  echo "  - ca_bundle.crt (Certificate Authority bundle)"
  exit 1
fi

echo -e "${YELLOW}Step 1: Creating SSL directory on the server...${NC}"
ssh -i $KEY_PATH -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "sudo mkdir -p /etc/nginx/ssl"

echo -e "${YELLOW}Step 2: Uploading SSL certificate files...${NC}"
scp -i $KEY_PATH -o StrictHostKeyChecking=no $SSL_DIR/certificate.crt ubuntu@$INSTANCE_IP:/tmp/
scp -i $KEY_PATH -o StrictHostKeyChecking=no $SSL_DIR/private.key ubuntu@$INSTANCE_IP:/tmp/
scp -i $KEY_PATH -o StrictHostKeyChecking=no $SSL_DIR/ca_bundle.crt ubuntu@$INSTANCE_IP:/tmp/

echo -e "${YELLOW}Step 3: Moving certificate files to the correct location...${NC}"
ssh -i $KEY_PATH -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "sudo mv /tmp/certificate.crt /etc/nginx/ssl/ && \
                                                                sudo mv /tmp/private.key /etc/nginx/ssl/ && \
                                                                sudo mv /tmp/ca_bundle.crt /etc/nginx/ssl/ && \
                                                                sudo chmod 600 /etc/nginx/ssl/*"

echo -e "${YELLOW}Step 4: Configuring Nginx to use SSL...${NC}"
cat > nginx_ssl.conf <<EOL
server {
    listen 80;
    server_name _;
    
    # Redirect all HTTP requests to HTTPS
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name _;
    
    ssl_certificate /etc/nginx/ssl/certificate.crt;
    ssl_certificate_key /etc/nginx/ssl/private.key;
    ssl_trusted_certificate /etc/nginx/ssl/ca_bundle.crt;
    
    # SSL optimization
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    
    # HSTS (uncomment after you confirm everything works)
    # add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    
    location / {
        root /var/www/html/portfolio;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
}
EOL

scp -i $KEY_PATH -o StrictHostKeyChecking=no nginx_ssl.conf ubuntu@$INSTANCE_IP:/tmp/
rm nginx_ssl.conf

ssh -i $KEY_PATH -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "sudo mv /tmp/nginx_ssl.conf /etc/nginx/sites-available/portfolio-ssl && \
                                                                 sudo ln -sf /etc/nginx/sites-available/portfolio-ssl /etc/nginx/sites-enabled/ && \
                                                                 sudo rm -f /etc/nginx/sites-enabled/default && \
                                                                 sudo nginx -t && \
                                                                 sudo systemctl restart nginx"

echo -e "${GREEN}=== ZeroSSL Certificate Installation Complete ===${NC}"
echo "Your website should now be accessible via HTTPS: https://$INSTANCE_IP"
echo "If you have a domain name, make sure it points to this IP address."
