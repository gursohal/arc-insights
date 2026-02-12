#!/bin/bash

# ============================================
# ARCL Insights - Azure Setup Script
# ============================================
# This script sets up Azure PostgreSQL database
# and necessary resources for ARCL Insights app
#
# Prerequisites:
# 1. Azure CLI installed (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
# 2. Logged in: az login
# 3. Active Azure subscription
#
# Usage: ./setup-azure.sh
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "============================================"
echo "  ARCL Insights - Azure Setup"
echo "============================================"
echo -e "${NC}"

# ============================================
# CONFIGURATION
# ============================================

# Change these values as needed
RESOURCE_GROUP="arcl-insights-rg"
LOCATION="westus2"  # Or your preferred region
DB_SERVER_NAME="arcl-db-$(date +%s)"  # Unique name with timestamp
DB_NAME="arcl_insights"
ADMIN_USER="arcladmin"
ADMIN_PASSWORD=""  # Will be generated or prompted

# Database configuration
DB_SKU="Standard_B1ms"  # Burstable tier (~$15-20/month)
DB_STORAGE_SIZE=32  # GB
DB_VERSION="14"

echo -e "${YELLOW}Configuration:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  DB Server: $DB_SERVER_NAME"
echo "  DB Name: $DB_NAME"
echo "  Admin User: $ADMIN_USER"
echo ""

# ============================================
# STEP 1: Check Azure CLI
# ============================================
echo -e "${GREEN}[1/7] Checking Azure CLI...${NC}"
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI not found!${NC}"
    echo "Please install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in. Running 'az login'...${NC}"
    az login
fi

echo -e "${GREEN}✓ Azure CLI ready${NC}"
echo ""

# ============================================
# STEP 2: Create Resource Group
# ============================================
echo -e "${GREEN}[2/7] Creating resource group...${NC}"
if az group show --name $RESOURCE_GROUP &> /dev/null; then
    echo -e "${YELLOW}Resource group already exists${NC}"
else
    az group create \
        --name $RESOURCE_GROUP \
        --location $LOCATION \
        --output table
    echo -e "${GREEN}✓ Resource group created${NC}"
fi
echo ""

# ============================================
# STEP 3: Generate Admin Password
# ============================================
echo -e "${GREEN}[3/7] Setting up database credentials...${NC}"
if [ -z "$ADMIN_PASSWORD" ]; then
    # Generate secure password
    ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    echo -e "${YELLOW}Generated admin password (save this!):${NC}"
    echo -e "${GREEN}$ADMIN_PASSWORD${NC}"
else
    echo "Using provided password"
fi
echo ""

# ============================================
# STEP 4: Create PostgreSQL Server
# ============================================
echo -e "${GREEN}[4/7] Creating PostgreSQL server...${NC}"
echo "This may take 3-5 minutes..."

az postgres flexible-server create \
    --resource-group $RESOURCE_GROUP \
    --name $DB_SERVER_NAME \
    --location $LOCATION \
    --admin-user $ADMIN_USER \
    --admin-password "$ADMIN_PASSWORD" \
    --sku-name $DB_SKU \
    --storage-size $DB_STORAGE_SIZE \
    --version $DB_VERSION \
    --public-access 0.0.0.0 \
    --output table

echo -e "${GREEN}✓ PostgreSQL server created${NC}"
echo ""

# ============================================
# STEP 5: Configure Firewall
# ============================================
echo -e "${GREEN}[5/7] Configuring firewall rules...${NC}"

# Allow Azure services
az postgres flexible-server firewall-rule create \
    --resource-group $RESOURCE_GROUP \
    --name $DB_SERVER_NAME \
    --rule-name "AllowAzureServices" \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0 \
    --output table

# Allow your current IP (for initial setup)
MY_IP=$(curl -s ifconfig.me)
echo "Adding your IP: $MY_IP"
az postgres flexible-server firewall-rule create \
    --resource-group $RESOURCE_GROUP \
    --name $DB_SERVER_NAME \
    --rule-name "MyIP" \
    --start-ip-address $MY_IP \
    --end-ip-address $MY_IP \
    --output table

echo -e "${GREEN}✓ Firewall configured${NC}"
echo ""

# ============================================
# STEP 6: Create Database
# ============================================
echo -e "${GREEN}[6/7] Creating database '$DB_NAME'...${NC}"

az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $DB_SERVER_NAME \
    --database-name $DB_NAME \
    --output table

echo -e "${GREEN}✓ Database created${NC}"
echo ""

# ============================================
# STEP 7: Apply Schema
# ============================================
echo -e "${GREEN}[7/7] Applying database schema...${NC}"

# Build connection string
DB_HOST="${DB_SERVER_NAME}.postgres.database.azure.com"
CONN_STRING="host=$DB_HOST port=5432 dbname=$DB_NAME user=$ADMIN_USER password=$ADMIN_PASSWORD sslmode=require"

echo "Connecting to database..."

# Check if psql is available
if command -v psql &> /dev/null; then
    echo "Running schema.sql..."
    PGPASSWORD="$ADMIN_PASSWORD" psql \
        -h $DB_HOST \
        -p 5432 \
        -U $ADMIN_USER \
        -d $DB_NAME \
        -f ./schema.sql
    
    echo -e "${GREEN}✓ Schema applied successfully${NC}"
else
    echo -e "${YELLOW}Warning: psql not found. Please run schema.sql manually:${NC}"
    echo ""
    echo "  psql -h $DB_HOST -p 5432 -U $ADMIN_USER -d $DB_NAME -f ./schema.sql"
    echo ""
fi
echo ""

# ============================================
# SUMMARY
# ============================================
echo -e "${GREEN}"
echo "============================================"
echo "  ✓ Azure Setup Complete!"
echo "============================================"
echo -e "${NC}"

echo -e "${YELLOW}Database Connection Details:${NC}"
echo "  Host: $DB_HOST"
echo "  Port: 5432"
echo "  Database: $DB_NAME"
echo "  Username: $ADMIN_USER"
echo "  Password: $ADMIN_PASSWORD"
echo ""

echo -e "${YELLOW}Connection String:${NC}"
echo "  postgresql://$ADMIN_USER:$ADMIN_PASSWORD@$DB_HOST:5432/$DB_NAME?sslmode=require"
echo ""

echo -e "${YELLOW}Save these credentials securely!${NC}"
echo "Recommended: Azure Key Vault or .env file"
echo ""

# Save to .env file
ENV_FILE=".env.azure"
cat > $ENV_FILE << EOF
# ARCL Insights Azure Database Configuration
# Generated: $(date)
# DO NOT COMMIT THIS FILE!

DB_HOST=$DB_HOST
DB_PORT=5432
DB_NAME=$DB_NAME
DB_USER=$ADMIN_USER
DB_PASSWORD=$ADMIN_PASSWORD
DB_SSL_MODE=require

# Full connection string
DATABASE_URL=postgresql://$ADMIN_USER:$ADMIN_PASSWORD@$DB_HOST:5432/$DB_NAME?sslmode=require
EOF

echo -e "${GREEN}✓ Credentials saved to $ENV_FILE${NC}"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Test connection: psql -h $DB_HOST -p 5432 -U $ADMIN_USER -d $DB_NAME"
echo "  2. Verify schema: SELECT table_name FROM information_schema.tables WHERE table_schema='public';"
echo "  3. Proceed to Phase 2: API development"
echo ""

echo -e "${YELLOW}Cost Estimate:${NC}"
echo "  PostgreSQL (B1ms + 32GB): ~\$15-20/month"
echo "  Total: ~\$15-20/month"
echo ""

echo -e "${GREEN}Setup complete!${NC}"
