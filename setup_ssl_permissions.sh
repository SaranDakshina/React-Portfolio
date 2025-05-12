#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Setting Up SSL Script Permissions ===${NC}"

# List of script files to set permissions for
SCRIPTS=(
  "install_zerossl.sh"
  "verify_domain_zerossl.sh"
  "deploy.sh"
)

# Set executable permissions for each script
for script in "${SCRIPTS[@]}"; do
  if [ -f "$script" ]; then
    echo -e "Setting executable permissions for ${YELLOW}$script${NC}"
    chmod +x "$script"
    if [ $? -eq 0 ]; then
      echo -e "  ${GREEN}✓ Success${NC}"
    else
      echo -e "  ${RED}✗ Failed to set permissions${NC}"
    fi
  else
    echo -e "${RED}Script not found: $script${NC}"
  fi
done

echo -e "\n${GREEN}=== Instructions ===${NC}"
echo -e "You can now run the scripts using:"
echo -e "  ${YELLOW}./install_zerossl.sh${NC} - To install your SSL certificate"
echo -e "  ${YELLOW}./verify_domain_zerossl.sh${NC} - To perform domain verification"
echo -e "  ${YELLOW}./deploy.sh --with-ssl${NC} - To deploy with SSL enabled"
echo -e "\nIf you encounter 'Permission denied' again, run: ${YELLOW}chmod +x script_name.sh${NC}"

echo -e "\n${YELLOW}Tip:${NC} To run this setup script, first execute: ${YELLOW}chmod +x setup_ssl_permissions.sh${NC}"
echo -e "Then run: ${YELLOW}./setup_ssl_permissions.sh${NC}"
