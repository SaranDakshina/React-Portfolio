#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Setting up SSL with Certbot ===${NC}"

# Step 1: Update package list and install Certbot
echo -e "${YELLOW}Step 1: Updating package list and installing Certbot...${NC}"
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Step 2: Obtain an SSL Certificate
echo -e "${YELLOW}Step 2: Obtaining an SSL certificate...${NC}"
echo -e "${GREEN}You will be prompted to:${NC}"
echo "  - Enter your email address"
echo "  - Agree to the terms of service"
echo "  - Choose whether to share your email address"
echo "  - Choose the domain(s) for your SSL certificate"

# Run Certbot with the Nginx plugin
sudo certbot --nginx

# Step 3: Verify the SSL Certificate
echo -e "${YELLOW}Step 3: Verifying the SSL certificate...${NC}"
sudo certbot certificates

# Step 4: Check Automatic Renewal
echo -e "${YELLOW}Step 4: Checking automatic renewal configuration...${NC}"
sudo systemctl status certbot.timer

echo -e "${GREEN}Certbot has set up automatic renewal via a systemd timer.${NC}"
echo "Certificates will be automatically renewed when they're close to expiration."

# Test the renewal process (dry run)
echo -e "${YELLOW}Testing the renewal process (dry run)...${NC}"
sudo certbot renew --dry-run

echo -e "${GREEN}=== SSL Setup Complete ===${NC}"
echo "You can now access your website using https://"
echo -e "${YELLOW}Don't forget to update your domain's DNS settings to point to your EC2 instance!${NC}"

# Troubleshooting information
echo -e "${GREEN}=== Troubleshooting Tips ===${NC}"
echo "1. Check Certbot logs: sudo journalctl -u certbot"
echo "2. Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "3. Verify Nginx configuration: sudo nginx -t"
echo "4. Restart Nginx if needed: sudo systemctl restart nginx"
