# Azure Setup Troubleshooting

## Issue: Regional Restrictions for PostgreSQL Flexible Server

Your Azure subscription appears to have restrictions on which regions can provision PostgreSQL Flexible Servers. This is common with:
- Free tier/trial subscriptions
- Student subscriptions  
- New Azure accounts
- Certain subscription types

## Attempted Solutions

1. ✅ Fixed SKU configuration (B1ms with Burstable tier)
2. ✅ Registered PostgreSQL provider
3. ❌ Tried West US 2 - Restricted
4. ❌ Tried East US - Restricted

## Alternative Solutions

### Option 1: Try Azure Portal (Recommended)

The Azure Portal GUI sometimes shows which regions are available better than CLI:

1. **Go to Azure Portal**: https://portal.azure.com
2. **Create Resource** → Search "PostgreSQL"
3. **Select**: "Azure Database for PostgreSQL flexible server"
4. **Region dropdown**: Will show which regions are available for your subscription
5. **Use available region**, then come back and update script

### Option 2: Use Single Server (Older, but works)

Azure has an older "Single Server" option that has broader regional support:

```bash
# Create using Single Server instead
az postgres server create \
  --resource-group arcl-insights-rg \
  --name arcl-db-single-$(date +%s) \
  --location eastus \
  --admin-user arcladmin \
  --admin-password <password> \
  --sku-name B_Gen5_1 \
  --version 11