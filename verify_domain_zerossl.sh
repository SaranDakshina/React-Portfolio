#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== ZeroSSL Domain Verification Helper ===${NC}"

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

# Ask for verification file information
echo -e "${YELLOW}Please provide the ZeroSSL verification file information:${NC}"
read -p "Verification file name (e.g., .well-known/pki-validation/123456789ABCDEF.txt): " VERIFICATION_FILE
read -p "Verification file content: " VERIFICATION_CONTENT

if [ -z "$VERIFICATION_FILE" ] || [ -z "$VERIFICATION_CONTENT" ]; then
  echo "Verification file name or content cannot be empty."
  exit 1
fi

# Create the directory structure for the verification file
FILE_DIR=$(dirname "$VERIFICATION_FILE")

echo -e "${YELLOW}Step 1: Creating directory structure on the server...${NC}"
ssh -i $KEY_PATH -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "sudo mkdir -p /var/www/html/portfolio/$FILE_DIR"

echo -e "${YELLOW}Step 2: Creating verification file...${NC}"
echo "$VERIFICATION_CONTENT" > verification_content.txt
scp -i $KEY_PATH -o StrictHostKeyChecking=no verification_content.txt ubuntu@$INSTANCE_IP:/tmp/
ssh -i $KEY_PATH -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "sudo mv /tmp/verification_content.txt /var/www/html/portfolio/$VERIFICATION_FILE"
rm verification_content.txt

echo -e "${GREEN}=== Domain Verification File Created ===${NC}"
echo "The verification file has been placed at: http://$INSTANCE_IP/$VERIFICATION_FILE"
echo "You can now complete the domain verification process in your ZeroSSL dashboard."
