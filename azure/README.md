# Azure Database Setup

This directory contains scripts and configuration for setting up the Azure PostgreSQL database for ARCL Insights.

## 📋 Prerequisites

1. **Azure Account**: Active Azure subscription
2. **Azure CLI**: Install from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
   ```bash
   # macOS
   brew install azure-cli
   
   # Or download installer
   ```
3. **PostgreSQL Client** (optional, for schema verification):
   ```bash
   brew install postgresql
   ```

## 🚀 Quick Start

### Step 1: Login to Azure
```bash
az login
```

### Step 2: Run Setup Script
```bash
cd azure
chmod +x setup-azure.sh
./setup-azure.sh
```

The script will:
1. ✅ Create resource group (`arcl-insights-rg`)
2. ✅ Create PostgreSQL server (Flexible Server, B1ms tier)
3. ✅ Configure firewall rules
4. ✅ Create database (`arcl_insights`)
5. ✅ Apply schema (10 tables, 4 views, triggers)
6. ✅ Save credentials to `.env.azure`

**Duration**: 5-7 minutes

### Step 3: Verify Setup
```bash
# Test connection (password saved in .env.azure)
source .env.azure
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME

# Verify tables
\dt

# Check views
\dv

# Exit
\q
```

## 📁 Files

### `schema.sql`
Complete database schema including:
- **10 Tables**: divisions, teams, players, batting_stats, bowling_stats, matches, scorecards, innings_details, bowling_details, scrape_jobs
- **4 Views**: v_team_rankings, v_top_batsmen, v_top_bowlers, v_match_schedule
- **Indexes**: 20+ for optimal query performance
- **Triggers**: Auto-update `last_updated` timestamps
- **Constraints**: Foreign keys, unique constraints

### `setup-azure.sh`
Automated setup script that:
- Creates all Azure resources
- Configures security (firewall, SSL)
- Applies schema
- Generates secure credentials
- Saves connection details

### `.env.azure` (Generated)
Environment variables file containing:
```bash
DB_HOST=arcl-db-xxxxx.postgres.database.azure.com
DB_PORT=5432
DB_NAME=arcl_insights
DB_USER=arcladmin
DB_PASSWORD=<generated-password>
DATABASE_URL=postgresql://...
```

**⚠️ IMPORTANT**: Add to `.gitignore`! Never commit credentials.

## 💰 Cost Breakdown

### PostgreSQL Flexible Server (B1ms)
- **Compute**: ~$12/month
- **Storage**: 32 GB @ ~$0.12/GB = $3.84/month
- **Backup**: 7-day retention (included)
- **Total**: ~$15-16/month

### Additional Costs
- **Egress**: First 5 GB free, then $0.087/GB
- **Estimate**: <$5/month for typical usage

### **Total Monthly Cost: $20-25**

## 🔧 Manual Setup (Alternative)

If you prefer manual setup via Azure Portal:

1. **Create Resource Group**
   - Name: `arcl-insights-rg`
   - Region: West US 2 (or your preferred)

2. **Create PostgreSQL Flexible Server**
   - Server name: `arcl-db-<unique>`
   - Admin username: `arcladmin`
   - Password: <secure-password>
   - Compute + Storage: Burstable B1ms, 32 GB
   - PostgreSQL version: 14

3. **Configure Networking**
   - Public access: Yes
   - Firewall rules: Add your IP + Azure services

4. **Create Database**
   - Name: `arcl_insights`
   - Collation: Default

5. **Apply Schema**
   ```bash
   psql -h <server>.postgres.database.azure.com \
        -p 5432 \
        -U arcladmin \
        -d arcl_insights \
        -f schema.sql
   ```

## 🔒 Security Best Practices

### 1. Credentials Management
```bash
# Use Azure Key Vault (recommended)
az keyvault create --name arcl-vault --resource-group arcl-insights-rg

az keyvault secret set --vault-name arcl-vault \
  --name "db-connection-string" \
  --value "postgresql://..."

# Or use environment variables (dev only)
export DATABASE_URL="postgresql://..."
```

### 2. Network Security
- Enable SSL (required by default)
- Restrict firewall rules to known IPs
- Consider Private Endpoint for production

### 3. Database Security
```sql
-- Create read-only user for API
CREATE USER arcl_api_user WITH PASSWORD 'secure-password';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO arcl_api_user;

-- Create write user for scrapers
CREATE USER arcl_scraper WITH PASSWORD 'secure-password';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO arcl_scraper;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO arcl_scraper;
```

## 🧪 Testing

### Verify Schema
```sql
-- Check table count
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
-- Should return: 10

-- Check views
SELECT COUNT(*) FROM information_schema.views 
WHERE table_schema = 'public';
-- Should return: 4

-- Check indexes
SELECT tablename, indexname FROM pg_indexes 
WHERE schemaname = 'public';
```

### Insert Test Data
```sql
-- Test division
INSERT INTO divisions (division_id, season_id, name)
VALUES (3, 66, 'Division 3');

-- Test team
INSERT INTO teams (team_id, name, division_id, season_id, rank, wins, losses, points)
VALUES ('abc12345', 'Test Team', 3, 66, 1, 5, 2, 150);

-- Verify
SELECT * FROM v_team_rankings WHERE division_id = 3;
```

## 📊 Monitoring

### Check Database Size
```sql
SELECT 
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
WHERE datname = 'arcl_insights';
```

### Monitor Connections
```sql
SELECT 
    count(*) as connections,
    state
FROM pg_stat_activity
WHERE datname = 'arcl_insights'
GROUP BY state;
```

### View Scrape Job History
```sql
SELECT 
    job_type,
    status,
    records_processed,
    started_at,
    completed_at,
    completed_at - started_at as duration
FROM scrape_jobs
ORDER BY started_at DESC
LIMIT 10;
```

## 🛠️ Troubleshooting

### Connection Issues
```bash
# Test connectivity
telnet <server>.postgres.database.azure.com 5432

# Check firewall rules
az postgres flexible-server firewall-rule list \
  --resource-group arcl-insights-rg \
  --name arcl-db-xxxxx

# Add your current IP
az postgres flexible-server firewall-rule create \
  --resource-group arcl-insights-rg \
  --name arcl-db-xxxxx \
  --rule-name "MyCurrentIP" \
  --start-ip-address $(curl -s ifconfig.me) \
  --end-ip-address $(curl -s ifconfig.me)
```

### Schema Issues
```bash
# Drop and recreate (⚠️ DESTRUCTIVE)
psql -h <server> -U arcladmin -d arcl_insights -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
psql -h <server> -U arcladmin -d arcl_insights -f schema.sql
```

### Performance Issues
```sql
-- Check slow queries
SELECT 
    query,
    mean_exec_time,
    calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Analyze tables
ANALYZE VERBOSE;
```

## 🗑️ Cleanup

To delete all Azure resources:

```bash
# ⚠️ WARNING: This will delete everything!
az group delete --name arcl-insights-rg --yes --no-wait

# Or delete just the database server
az postgres flexible-server delete \
  --resource-group arcl-insights-rg \
  --name arcl-db-xxxxx \
  --yes
```

## 📚 Next Steps

After database setup:
1. ✅ **Phase 1 Complete**: Database ready
2. ⏭️ **Phase 2**: API development (Azure Functions)
3. ⏭️ **Phase 3**: Background scrapers
4. ⏭️ **Phase 4**: iOS app migration
5. ⏭️ **Phase 5**: Deployment & testing

See `docs/AZURE_DATABASE_MIGRATION.md` for full implementation plan.

## 📞 Support

- **Azure Documentation**: https://docs.microsoft.com/en-us/azure/postgresql/
- **PostgreSQL Docs**: https://www.postgresql.org/docs/14/
- **Issues**: Report in GitHub repository

---

**Last Updated**: 2026-02-11
