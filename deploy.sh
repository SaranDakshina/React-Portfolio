#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for Java installation if needed for any build tools
check_java() {
  echo "Checking for Java installation..."
  if ! command -v java &> /dev/null; then
    echo "Java Runtime not found. Some build tools might require Java."
    echo "If you encounter Java-related errors, please install Java from https://www.java.com/download/"
    
    # OS-specific instructions
    if [[ "$OSTYPE" == "darwin"* ]]; then
      echo "On macOS, you can install Java using: brew install --cask temurin"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      echo "On Ubuntu/Debian, you can install Java using: sudo apt install default-jre"
    fi
    echo "Continuing with deployment anyway..."
  else
    echo "Java is installed: $(java -version 2>&1 | head -n 1)"
  fi
}

# Function to display usage instructions
usage() {
  echo "Usage: $0 [--with-ssl]"
  echo "Options:"
  echo "  --with-ssl    Install SSL certificate after deployment"
  echo "  --help        Display this help message"
  exit 1
}

# Parse command line arguments
WITH_SSL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --with-ssl)
      WITH_SSL=true
      shift
      ;;
    --help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Run Java check
check_java

# Build the app locally
echo -e "${GREEN}Building the React app...${NC}"
npm run build

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

echo -e "${GREEN}Deploying to EC2 instance at $INSTANCE_IP...${NC}"

# Upload the built files to the EC2 instance
echo -e "${YELLOW}Uploading files to the server...${NC}"
scp -o StrictHostKeyChecking=no -i $KEY_PATH -r dist/* ubuntu@$INSTANCE_IP:/var/www/html/portfolio/

echo -e "${GREEN}Deployment completed successfully!${NC}"

# Install SSL certificate if requested
if [ "$WITH_SSL" = true ]; then
  if [ -f "./install_zerossl.sh" ]; then
    echo -e "${YELLOW}Installing SSL certificate...${NC}"
    bash ./install_zerossl.sh
  else
    echo -e "${YELLOW}SSL installation script not found. Please run ./install_zerossl.sh separately.${NC}"
  fi
  echo -e "${GREEN}Your portfolio is now accessible at: https://$INSTANCE_IP${NC}"
else
  echo -e "${GREEN}Your portfolio is now accessible at: http://$INSTANCE_IP${NC}"
  echo -e "${YELLOW}To install an SSL certificate, run: ./install_zerossl.sh${NC}"
fi

echo "If you have a domain name, make sure it points to this IP address."
