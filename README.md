# CrowdStrike Falcon Simple Deployment

A simplified deployment solution for CrowdStrike Falcon Platform on Kubernetes that requires only **3 environment variables**.

> **⚠️ DISCLAIMER**: This is **NOT an official CrowdStrike tool**. This is a community-created deployment simplifier. Please test thoroughly in non-production environments and use at your own discretion. For official CrowdStrike deployment tools, visit [CrowdStrike Falcon Helm Charts](https://github.com/CrowdStrike/falcon-helm).

## 🎯 Overview

Deploy the complete CrowdStrike Falcon security platform on Kubernetes with a single command.

**What gets deployed:**
- ✅ **Falcon Sensor** - Runtime protection for Kubernetes nodes
- ✅ **Falcon Kubernetes Admission Controller (KAC)** - Policy enforcement and workload protection
- ✅ **Falcon Image Analyzer** - Container image vulnerability scanning
- 🆕 **Falcon SHRA** - Self-hosted Registry Assessment for private registries (NEW: fully automated)

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster with kubectl access
- CrowdStrike Falcon OAuth credentials

### Required OAuth API Scopes

Your Falcon OAuth client needs these permissions:
- **Falcon Container CLI**: Write
- **Falcon Container Image**: Read/Write
- **Falcon Images Download**: Read
- **Sensor Download**: Read
- **Installation Tokens**: Read

Create OAuth client at [falcon.crowdstrike.com](https://falcon.crowdstrike.com) → **Support and resources** → **API Clients & Keys**


## 🚀 Quick Start

### Basic Deployment

```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="your-cluster-name"

curl -sSL https://raw.githubusercontent.com/mikedzikowski/yet-another-sensor-installer/main/quick-deploy.sh | bash
```

### Quick SHRA Deployment (NEW)

Deploy SHRA to scan your private container registries:

```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="your-cluster-name"

# Enable SHRA and configure your registry
export INSTALL_SHRA="true"
export SHRA_REGISTRY_TYPE="acr"  # or ecr, gcr, dockerhub, etc.
export SHRA_REGISTRY_HOST="https://myregistry.azurecr.io"
export SHRA_REGISTRY_USERNAME="myregistry"
export SHRA_REGISTRY_PASSWORD="your-registry-password"

curl -sSL https://raw.githubusercontent.com/mikedzikowski/yet-another-sensor-installer/main/quick-deploy.sh | bash
```

### Interactive Version Selection
```bash
# Download for interactive prompts
curl -sSL https://raw.githubusercontent.com/mikedzikowski/yet-another-sensor-installer/main/quick-deploy.sh -o quick-deploy.sh
chmod +x quick-deploy.sh
./quick-deploy.sh
```

### Platform-Specific Configuration

**Standard Kubernetes (AKS, EKS, GKE Standard):**
```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="your-cluster-name"  # e.g., "aks-prod", "eks-prod", "gke-standard"

curl -sSL https://raw.githubusercontent.com/mikedzikowski/yet-another-sensor-installer/main/quick-deploy.sh | bash
```

**GKE Autopilot:**
```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="gke-autopilot-prod"
export IS_GKE_AUTOPILOT=true

curl -sSL https://raw.githubusercontent.com/mikedzikowski/yet-another-sensor-installer/main/quick-deploy.sh | bash
```

**Component Selection:**
```bash
export INSTALL_SENSOR=true   # Falcon Sensor (default: true)
export INSTALL_KAC=true      # Kubernetes Admission Controller (default: true)
export INSTALL_IAR=true      # Image Analyzer (default: true)
export INSTALL_SHRA=false    # Self-hosted Registry Assessment (default: false)
```

**Automation (skip interactive prompts):**
```bash
export SKIP_VERSION_SELECTION=true
```

## 🔧 Configuration Options

### Required Environment Variables
```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"           # CrowdStrike Falcon OAuth Client ID
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"   # CrowdStrike Falcon OAuth Client Secret
export CLUSTERNAME="your-cluster-name"                          # Kubernetes cluster identifier
```

### Optional Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `INSTALL_SENSOR` | `true` | Deploy Falcon Sensor for node protection |
| `INSTALL_KAC` | `true` | Deploy Kubernetes Admission Controller |
| `INSTALL_IAR` | `true` | Deploy Image Analyzer for container scanning |
| `INSTALL_SHRA` | `false` | Deploy Self-hosted Registry Assessment |
| `IS_GKE_AUTOPILOT` | `false` | Enable GKE Autopilot specific configurations |
| `FALCON_SENSOR_MODE` | `bpf` | Sensor mode (kernel/bpf) |
| `SKIP_VERSION_SELECTION` | `false` | Skip interactive version prompts |
| `VERBOSE` | `false` | Show detailed deployment information |

### Version Control
```bash
export FALCON_SENSOR_VERSION="7.34.0-18708-1"     # Specific Falcon Sensor version (optional)
export FALCON_KAC_VERSION="7.35.0-3302"           # Specific Falcon KAC version (optional)
export FALCON_IAR_VERSION="1.0.12"                # Specific Image Analyzer version (optional)
export FALCON_SHRA_JOB_CONTROLLER_VERSION="1.3.0" # Specific SHRA Job Controller version (optional)
export FALCON_SHRA_EXECUTOR_VERSION="1.3.0"       # Specific SHRA Executor version (optional)
```

## 🏗️ SHRA (Self-hosted Registry Assessment)

**NEW**: Fully automated deployment with flexible configuration for any container registry and cluster!

SHRA scans your private container registries for vulnerabilities and compliance issues. Now supports **15+ registry types** with **zero manual configuration** required after deployment.

### ✨ Quick SHRA Deployment

**Automated - No Manual Configuration Required:**
```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="your-cluster-name"

# Component Selection - SHRA only
export INSTALL_SENSOR="false"
export INSTALL_KAC="false"
export INSTALL_IAR="false"
export INSTALL_SHRA="true"

# Registry Configuration - Azure ACR Example
export SHRA_REGISTRY_TYPE="acr"
export SHRA_REGISTRY_HOST="https://myregistry.azurecr.io"
export SHRA_REGISTRY_USERNAME="myregistry"
export SHRA_REGISTRY_PASSWORD="your-acr-password"
export SHRA_CRON_SCHEDULE="0 2 * * *"  # Daily at 2 AM

./quick-deploy.sh
```

### 🔧 Advanced SHRA Configuration

**All Configuration Options:**
```bash
# Required: CrowdStrike & Cluster
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="your-cluster-name"
export INSTALL_SHRA="true"

# Registry Configuration (Required)
export SHRA_REGISTRY_TYPE="acr"                           # See supported types below
export SHRA_REGISTRY_HOST="https://myregistry.azurecr.io" # Registry URL
export SHRA_REGISTRY_USERNAME="username"                  # Registry username
export SHRA_REGISTRY_PASSWORD="password-or-token"         # Registry password/token
export SHRA_REGISTRY_PORT="443"                          # Default: 443

# Scanning Configuration (Optional)
export SHRA_ALLOWED_REPOS="prod/*,shared/*"              # Repo patterns (empty = all)
export SHRA_CRON_SCHEDULE="0 2 * * *"                   # Default: Daily at 2 AM

# Storage Configuration (Optional - Auto-detected)
export SHRA_STORAGE_CLASS="managed-premium"              # Auto-detected if not set
export SHRA_DB_STORAGE_SIZE="2Gi"                       # Default: 1Gi
export SHRA_ASSESSMENT_STORAGE_SIZE="20Gi"              # Default: 10Gi

# Version Control (Optional - Uses latest)
export FALCON_SHRA_EXECUTOR_VERSION="1.7.0"             # Default: latest
export FALCON_SHRA_JOB_CONTROLLER_VERSION="1.7.0"       # Default: latest
```

### 🏭 Supported Container Registries

| Registry Type | `SHRA_REGISTRY_TYPE` | Example Host |
|---------------|---------------------|--------------|
| **Amazon ECR** | `ecr` | `https://123456789.dkr.ecr.us-east-1.amazonaws.com` |
| **Azure ACR** | `acr` | `https://myregistry.azurecr.io` |
| **Google GCR** | `gcr` | `https://gcr.io/my-project` |
| **Google GAR** | `gar` | `https://us-central1-docker.pkg.dev/my-project` |
| **Docker Hub** | `dockerhub` | `https://registry-1.docker.io` |
| **Harbor** | `harbor` | `https://harbor.company.com` |
| **Quay.io** | `quay` | `https://quay.io` |
| **JFrog Artifactory** | `artifactory` | `https://company.jfrog.io` |
| **Sonatype Nexus** | `nexus` | `https://nexus.company.com` |
| **GitLab Registry** | `gitlab` | `https://registry.gitlab.com` |
| **GitHub Registry** | `github` | `https://ghcr.io` |
| **Custom Registry** | `custom` | `https://registry.example.com` |

### 📋 Real-World Examples

**AWS ECR Production Setup:**
```bash
export SHRA_REGISTRY_TYPE="ecr"
export SHRA_REGISTRY_HOST="https://123456789.dkr.ecr.us-east-1.amazonaws.com"
export SHRA_REGISTRY_USERNAME="AWS"
export SHRA_REGISTRY_PASSWORD="your-ecr-token"
export SHRA_ALLOWED_REPOS="prod/*,shared/*"
export SHRA_STORAGE_CLASS="gp3"
export SHRA_ASSESSMENT_STORAGE_SIZE="50Gi"  # Large registry
```

**Azure ACR Enterprise Setup:**
```bash
export SHRA_REGISTRY_TYPE="acr"
export SHRA_REGISTRY_HOST="https://companyregistry.azurecr.io"
export SHRA_REGISTRY_USERNAME="companyregistry"
export SHRA_REGISTRY_PASSWORD="your-acr-service-principal-password"
export SHRA_CRON_SCHEDULE="0 */6 * * *"  # Every 6 hours
export SHRA_STORAGE_CLASS="managed-premium"
```

**Google GCR Setup:**
```bash
export SHRA_REGISTRY_TYPE="gcr"
export SHRA_REGISTRY_HOST="https://gcr.io/my-company-project"
export SHRA_REGISTRY_USERNAME="_json_key"
export SHRA_REGISTRY_PASSWORD="$(cat /path/to/service-account.json)"
export SHRA_STORAGE_CLASS="ssd"
```

**Harbor Self-Hosted Setup:**
```bash
export SHRA_REGISTRY_TYPE="harbor"
export SHRA_REGISTRY_HOST="https://harbor.company.com"
export SHRA_REGISTRY_USERNAME="robot-account"
export SHRA_REGISTRY_PASSWORD="robot-token"
export SHRA_ALLOWED_REPOS="public/*,team-a/*,team-b/*"
```

**Docker Hub Multi-Repository:**
```bash
export SHRA_REGISTRY_TYPE="dockerhub"
export SHRA_REGISTRY_HOST="https://registry-1.docker.io"
export SHRA_REGISTRY_USERNAME="your-dockerhub-username"
export SHRA_REGISTRY_PASSWORD="your-dockerhub-access-token"
export SHRA_ALLOWED_REPOS="library/nginx,library/alpine,myusername/*"
```

### 🚀 Cross-Cloud Deployment Examples

**AWS EKS with ECR:**
```bash
export CLUSTERNAME="eks-production"
export SHRA_REGISTRY_TYPE="ecr"
export SHRA_STORAGE_CLASS="gp3"  # or auto-detected
```

**Azure AKS with ACR:**
```bash
export CLUSTERNAME="aks-production"
export SHRA_REGISTRY_TYPE="acr"
export SHRA_STORAGE_CLASS="managed-premium"  # or auto-detected
```

**Google GKE with GCR:**
```bash
export CLUSTERNAME="gke-production"
export SHRA_REGISTRY_TYPE="gcr"
export SHRA_STORAGE_CLASS="ssd"  # or auto-detected
```

### ⚙️ Smart Auto-Configuration

**Storage Class Auto-Detection:**
- Automatically detects available storage classes in your cluster
- Prioritizes: `gp2`, `gp3`, `standard`, `ssd`, `fast`, `premium-lrs`, `managed-premium`
- Falls back to first available if none of the priority classes exist
- Uses cluster default if detection fails

**Cross-Platform Compatibility:**
- **AWS EKS**: Auto-detects `gp2`/`gp3` storage
- **Azure AKS**: Auto-detects `default`/`managed-premium` storage
- **Google GKE**: Auto-detects `standard`/`ssd` storage
- **On-premise**: Uses first available storage class

### 📊 Repository Filtering Examples

**Scan Specific Repositories:**
```bash
export SHRA_ALLOWED_REPOS="production/*,shared/base-images"  # Only prod and shared base images
export SHRA_ALLOWED_REPOS="myapp-*"                         # All repos starting with myapp-
export SHRA_ALLOWED_REPOS="library/nginx,library/alpine"    # Specific Docker Hub images
```

**Scan All Repositories:**
```bash
export SHRA_ALLOWED_REPOS=""  # Empty = scan everything accessible
```

### 🕒 Scanning Schedule Examples

```bash
export SHRA_CRON_SCHEDULE="0 2 * * *"      # Daily at 2 AM (default)
export SHRA_CRON_SCHEDULE="0 */6 * * *"    # Every 6 hours
export SHRA_CRON_SCHEDULE="0 9 * * 1"      # Monday at 9 AM (weekly)
export SHRA_CRON_SCHEDULE="*/30 * * * *"   # Every 30 minutes (testing)
export SHRA_CRON_SCHEDULE="0 22 * * 0"     # Sunday at 10 PM (weekly)
```

### 💾 Storage Configuration Examples

**Development/Small Registries:**
```bash
export SHRA_DB_STORAGE_SIZE="500Mi"
export SHRA_ASSESSMENT_STORAGE_SIZE="5Gi"
```

**Production/Large Registries:**
```bash
export SHRA_DB_STORAGE_SIZE="5Gi"
export SHRA_ASSESSMENT_STORAGE_SIZE="100Gi"
```

**High-Performance Setup:**
```bash
export SHRA_STORAGE_CLASS="managed-premium"  # SSD storage
export SHRA_DB_STORAGE_SIZE="2Gi"
export SHRA_ASSESSMENT_STORAGE_SIZE="50Gi"
```

### ✅ Deployment Verification

**Check SHRA Status:**
```bash
# Check SHRA pods
kubectl get pods -n falcon-self-hosted-registry-assessment

# Check SHRA logs
kubectl logs -n falcon-self-hosted-registry-assessment falcon-shra-job-controller-0
kubectl logs -n falcon-self-hosted-registry-assessment falcon-shra-executor-0

# Check SHRA storage
kubectl get pvc -n falcon-self-hosted-registry-assessment

# Check SHRA configuration
kubectl get configmap -n falcon-self-hosted-registry-assessment
```

**Expected SHRA Output:**
```
NAME                           READY   STATUS    RESTARTS   AGE
falcon-shra-executor-0         1/1     Running   0          5m
falcon-shra-job-controller-0   1/1     Running   0          5m
```

### 🔒 Security & Best Practices

**Configuration File Security:**
```bash
# Use configuration file approach for security
cp shra_config_examples.env my_shra_config.env
# Edit my_shra_config.env with your actual values
source my_shra_config.env
./quick-deploy.sh

# Add to .gitignore
echo "my_shra_config.env" >> .gitignore
```

**Credential Management:**
- Never commit real credentials to version control
- Use environment-specific config files (dev, staging, prod)
- Consider using Kubernetes secrets for credentials
- Regularly rotate registry credentials
- Use least-privilege access for registry accounts

### 🚨 SHRA Troubleshooting

**Pod Issues:**
```bash
# Check pod status
kubectl describe pods -n falcon-self-hosted-registry-assessment

# Check events
kubectl get events -n falcon-self-hosted-registry-assessment --sort-by='.lastTimestamp'

# Check storage issues
kubectl describe pvc -n falcon-self-hosted-registry-assessment
```

**Registry Connectivity:**
```bash
# Test registry connectivity
kubectl exec -n falcon-self-hosted-registry-assessment falcon-shra-executor-0 -- nslookup your-registry-host

# Check registry credentials
kubectl get secrets -n falcon-self-hosted-registry-assessment
```

**Storage Issues:**
```bash
# Check available storage classes
kubectl get storageclass

# Check PVC status
kubectl get pvc -n falcon-self-hosted-registry-assessment -o wide
```

### 📖 Advanced Configuration

For advanced SHRA configuration options, see:
- `shra_config_examples.env` - Comprehensive configuration examples
- `falcon-helm-main/helm-charts/falcon-self-hosted-registry-assessment/README.md` - Official documentation
- CrowdStrike Falcon console - SHRA dashboard and results

## 🏷️ Version Selection

### Interactive Selection (Recommended)
Download the script locally to use interactive version selection:

```bash
curl -sSL https://raw.githubusercontent.com/mikedzikowski/yet-another-sensor-installer/main/quick-deploy.sh -o quick-deploy.sh
chmod +x quick-deploy.sh

export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="your-cluster-name"

./quick-deploy.sh
```

### Automated (Latest Versions)
Skip version prompts for CI/CD pipelines:

```bash
export SKIP_VERSION_SELECTION=true
curl -sSL https://raw.githubusercontent.com/mikedzikowski/yet-another-sensor-installer/main/quick-deploy.sh | bash
```

### List Available Versions Only
```bash
./quick-deploy.sh list-versions
```

## 🔍 Verification

### Check Deployment Status
```bash
# View all Falcon pods
kubectl get pods -A | grep falcon

# Check Helm release
helm list -n falcon-platform

# View deployment details
kubectl get deployments,daemonsets -A | grep falcon
```

### Expected Output
```bash
# Standard deployment
NAMESPACE               NAME                                          READY   STATUS    RESTARTS   AGE
falcon-image-analyzer   falcon-platform-falcon-image-analyzer-xxx    1/1     Running   0          2m
falcon-kac              falcon-kac-xxx-xxx                           3/3     Running   0          2m
falcon-system           falcon-platform-falcon-sensor-xxx            1/1     Running   0          2m

# With SHRA enabled
falcon-self-hosted-registry-assessment   falcon-shra-executor-0         1/1     Running   0          2m
falcon-self-hosted-registry-assessment   falcon-shra-job-controller-0   1/1     Running   0          2m
```

## 🗑️ Cleanup

### Automated Cleanup (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/mikedzikowski/yet-another-sensor-installer/main/quick-deploy.sh | bash -s cleanup
```

The script automatically removes:
- Falcon Platform umbrella chart deployments
- Individual component releases (falcon-sensor, falcon-kac, falcon-image-analyzer, falcon-shra)
- All related namespaces and resources (including falcon-self-hosted-registry-assessment)
- Webhook configurations and CRDs
- GKE Autopilot AllowlistSynchronizers

### Manual Cleanup (If Needed)
```bash
# Remove Helm releases
helm uninstall falcon-platform -n falcon-platform --ignore-not-found

# Remove namespaces
kubectl delete namespace falcon-platform falcon-system falcon-kac falcon-image-analyzer --ignore-not-found

# Remove webhooks
kubectl delete validatingwebhookconfigurations -l app.kubernetes.io/instance=falcon-platform --ignore-not-found

# Verify cleanup
helm list -A | grep falcon
kubectl get namespace | grep -E "(falcon|crowdstrike)"
```

## 📺 What the Script Does

1. **Downloads** official CrowdStrike scripts
2. **Validates** environment and prerequisites
3. **Retrieves** Customer ID (CID) and registry credentials
4. **Gets** latest Falcon component images
5. **Deploys** complete Falcon Platform using Helm
6. **Verifies** deployment status
7. **Cleans up** temporary files

### Auto-Discovery Features
- 🔍 **Automatic CID Discovery** - No manual Customer ID lookup needed
- 🏗️ **Registry Auto-Configuration** - Container registry access configured automatically
- 🌐 **Cloud Auto-Detection** - Detects Falcon cloud region (US-1, US-2, EU-1, Gov)
- 📦 **Latest Images** - Uses current Falcon component versions

## 🧪 Troubleshooting

### Common Issues

**Authentication Errors**
```bash
export VERBOSE=true  # Enable detailed logging
./quick-deploy.sh
```

**Pod Startup Issues**
```bash
kubectl logs -n falcon-system -l app.kubernetes.io/instance=falcon-platform
kubectl get events -A | grep falcon
```

**Network Requirements**
- Outbound access to `*.crowdstrike.com`
- Registry access to `registry.crowdstrike.com`

## 🤝 Support

- **Issues**: [GitHub Issues](https://github.com/mikedzikowski/yet-another-sensor-installer/issues)
- **Documentation**: [CrowdStrike Falcon Helm Charts](https://github.com/CrowdStrike/falcon-helm)
- **Console**: [falcon.crowdstrike.com](https://falcon.crowdstrike.com)