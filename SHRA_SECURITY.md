# SHRA Security Guide

## Overview
This guide explains how to securely deploy CrowdStrike Self-hosted Registry Assessment (SHRA) without hardcoding secrets in configuration files.

## Security Best Practices

### 1. Never Commit Secrets
- ✅ Use `shra_values_template.yaml` (included in repo)
- ❌ Never commit `shra_values_*.yaml` files with real credentials
- ✅ Files with secrets are automatically excluded via `.gitignore`

### 2. Environment Variables Approach
The deployment script uses environment variables to securely inject credentials:

```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export SHRA_REGISTRY_TYPE="acr"
export SHRA_REGISTRY_HOST="https://yourregistry.azurecr.io"
export SHRA_REGISTRY_USERNAME="your-username"
export SHRA_REGISTRY_PASSWORD="your-password"
export SHRA_CRON_SCHEDULE="*/5 * * * *"

./quick-deploy.sh
```

### 3. Template System
The `shra_values_template.yaml` file uses environment variable placeholders:
- `${FALCON_CLIENT_ID}` - CrowdStrike API client ID
- `${FALCON_CLIENT_SECRET}` - CrowdStrike API client secret
- `${SHRA_REGISTRY_USERNAME}` - Registry username
- `${SHRA_REGISTRY_PASSWORD}` - Registry password

### 4. Generated Files
The script generates `shra_values.yaml` at runtime using:
- Environment variables (when available)
- Template substitution via `envsubst`
- Automatic warnings for placeholder values

### 5. File Security
- `shra_values_*.yaml` - Excluded from git (contains secrets)
- `shra_values_template.yaml` - Safe to commit (placeholder values only)
- `.gitignore` - Configured to exclude sensitive files

## Usage Examples

### Interactive Deployment
```bash
# Set credentials via environment variables
export FALCON_CLIENT_ID="your-id"
export FALCON_CLIENT_SECRET="your-secret"

# Run with interactive configuration
./quick-deploy.sh
```

### Automated Deployment
```bash
# Set all required environment variables
export FALCON_CLIENT_ID="your-id"
export FALCON_CLIENT_SECRET="your-secret"
export SHRA_REGISTRY_TYPE="acr"
export SHRA_REGISTRY_HOST="https://yourregistry.azurecr.io"
export SHRA_REGISTRY_USERNAME="registry-user"
export SHRA_REGISTRY_PASSWORD="registry-pass"
export SHRA_CRON_SCHEDULE="*/5 * * * *"
export INSTALL_SHRA="true"
export SKIP_VERSION_SELECTION="true"

./quick-deploy.sh
```

## CI/CD Integration
For CI/CD pipelines, store secrets in your platform's secret management:
- GitHub Actions: Repository Secrets
- GitLab CI: Variables (masked)
- Azure DevOps: Variable Groups (secret)
- Jenkins: Credentials Store

## Security Validation
Before committing code, verify:
1. No hardcoded secrets in any files
2. `.gitignore` excludes sensitive files
3. Template files use placeholders only
4. Generated files are excluded from version control