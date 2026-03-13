# CrowdStrike Falcon Simple Deployment

A simplified deployment solution for CrowdStrike Falcon Platform on Kubernetes that requires only **3 environment variables**.

## 🎯 Overview

Deploy the complete CrowdStrike Falcon security platform on Kubernetes with a single command.

**What gets deployed:**
- ✅ **Falcon Sensor** - Runtime protection for Kubernetes nodes
- ✅ **Falcon Kubernetes Admission Controller (KAC)** - Policy enforcement and workload protection
- ✅ **Falcon Image Analyzer** - Container image vulnerability scanning

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

## 📋 Cloud Platform Deployment Examples

### AKS (Azure Kubernetes Service)
```bash
# Standard AKS deployment with interactive version selection
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="aks-production"
export INSTALL_SENSOR=true
export INSTALL_KAC=true
export INSTALL_IAR=true

# Download and run with interactive prompts
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh
chmod +x quick-deploy.sh
./quick-deploy.sh
```

**Non-interactive (automation):**
```bash
# Skip version selection prompts - uses latest versions
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="aks-production"
export SKIP_VERSION_SELECTION=true

curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

### EKS (Amazon Elastic Kubernetes Service)
```bash
# EKS deployment with interactive version selection
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="eks-production"
export INSTALL_SENSOR=true
export INSTALL_KAC=true
export INSTALL_IAR=true

# Download and run with interactive prompts
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh
chmod +x quick-deploy.sh
./quick-deploy.sh
```

**Non-interactive (automation):**
```bash
# Skip version selection prompts - uses latest versions
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="eks-production"
export SKIP_VERSION_SELECTION=true

curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

### GKE Standard (Google Kubernetes Engine)
```bash
# GKE Standard with interactive version selection
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="gke-standard-prod"
export INSTALL_SENSOR=true    # Node protection
export INSTALL_KAC=false      # Skip admission controller
export INSTALL_IAR=true       # Include image analyzer

# Download and run with interactive prompts
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh
chmod +x quick-deploy.sh
./quick-deploy.sh
```

**Non-interactive (automation):**
```bash
# Skip version selection prompts - uses latest versions
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="gke-standard-prod"
export INSTALL_SENSOR=true
export INSTALL_KAC=false
export INSTALL_IAR=true
export SKIP_VERSION_SELECTION=true

curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

### GKE Autopilot 🤖
```bash
# GKE Autopilot with interactive version selection (eBPF recommended)
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="gke-autopilot-prod"
export IS_GKE_AUTOPILOT=true   # REQUIRED for Autopilot
export FALCON_SENSOR_MODE=bpf  # RECOMMENDED for Autopilot
export INSTALL_SENSOR=true
export INSTALL_KAC=true
export INSTALL_IAR=true

# Download and run with interactive prompts
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh
chmod +x quick-deploy.sh
./quick-deploy.sh
```

**Non-interactive (automation):**
```bash
# Skip version selection prompts - uses latest versions
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="gke-autopilot-prod"
export IS_GKE_AUTOPILOT=true
export FALCON_SENSOR_MODE=bpf
export SKIP_VERSION_SELECTION=true

curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

**🔧 GKE Autopilot Special Handling:**

The script automatically configures Autopilot-specific requirements:

1. **AllowlistSynchronizer Creation:**
   ```yaml
   apiVersion: auto.gke.io/v1
   kind: AllowlistSynchronizer
   metadata:
     name: crowdstrike-synchronizer
   spec:
     allowlistPaths:
     - CrowdStrike/falcon-sensor/*
   ```

2. **Security Context Adjustments:**
   - Removes privileged security contexts
   - Configures appropriate capabilities
   - Sets up required resource limits

3. **Workload Identity Integration:**
   - Configures service accounts for Autopilot compatibility
   - Sets up proper RBAC permissions

> **📘 GKE Autopilot Note**: The script detects and automatically handles Autopilot's restrictive security policies. The `AllowlistSynchronizer` grants CrowdStrike workloads necessary permissions for security operations. **eBPF mode is recommended** for optimal compatibility.
>
> **Reference**: [GKE Autopilot Security Policies](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-security)

## 🚀 Additional Deployment Scenarios

### OpenShift / Security-Restricted Environment
```bash
# Interactive version selection for OpenShift or security-restricted Kubernetes
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="openshift-prod"
export FALCON_SENSOR_MODE=bpf  # Required for restricted security contexts
export INSTALL_SENSOR=true
export INSTALL_KAC=true
export INSTALL_IAR=true

# Download and run with interactive prompts
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh
chmod +x quick-deploy.sh
./quick-deploy.sh
```

**Non-interactive (automation):**
```bash
# Skip version selection prompts - uses latest versions
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="openshift-prod"
export FALCON_SENSOR_MODE=bpf
export SKIP_VERSION_SELECTION=true

curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

### Development/Testing Environment
```bash
# Interactive deployment with kernel mode for testing
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="dev-cluster"
export FALCON_SENSOR_MODE=kernel  # Maximum visibility for testing
export INSTALL_SENSOR=true
export INSTALL_KAC=false  # Skip admission controller in dev
export INSTALL_IAR=false  # Skip image analyzer in dev

# Download and run with interactive prompts
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh
chmod +x quick-deploy.sh
./quick-deploy.sh
```

**Non-interactive (automation):**
```bash
# Skip version selection prompts - uses latest versions
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="dev-cluster"
export FALCON_SENSOR_MODE=kernel
export INSTALL_SENSOR=true
export INSTALL_KAC=false
export INSTALL_IAR=false
export SKIP_VERSION_SELECTION=true

curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

## 🔧 Configuration Options

### 📝 Environment Variables Reference

#### **Required Variables**
```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"           # CrowdStrike Falcon OAuth Client ID
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"   # CrowdStrike Falcon OAuth Client Secret
export CLUSTERNAME="your-cluster-name"                          # Kubernetes cluster identifier
```

#### **Component Selection**
```bash
export INSTALL_SENSOR=true           # Enable/disable Falcon Sensor (default: true)
export INSTALL_KAC=true              # Enable/disable Kubernetes Admission Controller (default: true)
export INSTALL_IAR=true              # Enable/disable Image Analyzer (default: true)
```

#### **Platform Configuration**
```bash
export IS_GKE_AUTOPILOT=false        # Enable GKE Autopilot compatibility mode (default: false)
export FALCON_SENSOR_MODE=kernel     # Sensor deployment mode: kernel, bpf (default: kernel)
```

#### **Version Selection**
```bash
export FALCON_SENSOR_VERSION="7.34.0-18708-1"     # Specific Falcon Sensor version (optional)
export FALCON_KAC_VERSION="7.35.0-3302"           # Specific Falcon KAC version (optional)
export FALCON_IAR_VERSION="1.0.12"                # Specific Image Analyzer version (optional)
export SKIP_VERSION_SELECTION=true                # Skip interactive version selection (default: false)
export FORCE_INTERACTIVE=true                     # Force interactive mode in non-TTY environments (default: false)
```

#### **Output and Debugging**
```bash
export VERBOSE=true                  # Enable detailed output and debugging info (default: false)
export SHOW_VERSIONS=true            # Display available versions without deployment (default: false)
```

#### **Advanced Configuration (Auto-Generated)**
```bash
# These are automatically set by the script - do not set manually
export FALCON_CID="auto-detected"                 # Customer ID (retrieved from API)
export ENCODED_DOCKER_CONFIG="auto-generated"     # Registry authentication token
export SENSOR_REGISTRY="auto-detected"            # Falcon Sensor container registry
export SENSOR_IMAGE_TAG="auto-detected"           # Falcon Sensor image tag
export KAC_REGISTRY="auto-detected"               # Falcon KAC container registry
export KAC_IMAGE_TAG="auto-detected"              # Falcon KAC image tag
export IAR_REGISTRY="auto-detected"               # Image Analyzer container registry
export IAR_IMAGE_TAG="auto-detected"              # Image Analyzer image tag
```

#### **Environment Variable Defaults Summary**
| Variable | Default Value | Description |
|----------|---------------|-------------|
| `INSTALL_SENSOR` | `true` | Deploy Falcon Sensor for node protection |
| `INSTALL_KAC` | `true` | Deploy Kubernetes Admission Controller |
| `INSTALL_IAR` | `true` | Deploy Image Analyzer for container scanning |
| `IS_GKE_AUTOPILOT` | `false` | Enable GKE Autopilot specific configurations |
| `FALCON_SENSOR_MODE` | `kernel` | Sensor mode (kernel/bpf) |
| `SKIP_VERSION_SELECTION` | `false` | Skip interactive version prompts |
| `FORCE_INTERACTIVE` | `false` | Force interactive mode in scripts/automation |
| `VERBOSE` | `false` | Show detailed deployment information |
| `SHOW_VERSIONS` | `false` | List available versions only |

#### **Common Configuration Examples**

**Minimal Configuration (Required Only):**

```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="production-cluster"
```

**Automation/CI/CD Pipeline:**

```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="ci-cluster"
export SKIP_VERSION_SELECTION=true              # Use latest versions
export VERBOSE=true                             # Detailed logging for debugging
```

**Specific Version Configuration:**

```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="staging-cluster"
export FALCON_SENSOR_VERSION="7.34.0-18708-1"
export FALCON_KAC_VERSION="7.35.0-3302"
export FALCON_IAR_VERSION="1.0.12"
```

**GKE Autopilot Configuration:**

```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="gke-autopilot-cluster"
export IS_GKE_AUTOPILOT=true
export FALCON_SENSOR_MODE=bpf                   # Recommended for Autopilot
```

**Development/Testing (Sensor Only):**

```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="dev-cluster"
export INSTALL_SENSOR=true
export INSTALL_KAC=false                        # Skip admission controller
export INSTALL_IAR=false                        # Skip image analyzer
export VERBOSE=true                             # Enable debug output
```

### 🔒 Falcon Sensor Mode Options

Choose between different sensor deployment modes:

#### Kernel Mode
```bash
export FALCON_SENSOR_MODE=kernel
```
- **Best for**: Production environments
- **Features**: Full kernel-level access and protection
- **Requirements**: Standard Kubernetes clusters with privileged container support

#### eBPF User Mode
```bash
export FALCON_SENSOR_MODE=bpf
```
- **Best for**: GKE Autopilot, OpenShift, security-restricted environments
- **Features**: eBPF-based monitoring without kernel module
- **Requirements**: Linux kernel 4.15+ with eBPF support

### 🧹 Clear All Variables

To start fresh and unset all CrowdStrike Falcon environment variables:

```bash
# Unset all CrowdStrike Falcon variables
unset FALCON_CLIENT_ID FALCON_CLIENT_SECRET FALCON_CID CLUSTERNAME \
      FALCON_SENSOR_VERSION FALCON_KAC_VERSION FALCON_IAR_VERSION \
      SKIP_VERSION_SELECTION FORCE_INTERACTIVE INSTALL_SENSOR \
      INSTALL_KAC INSTALL_IAR IS_GKE_AUTOPILOT FALCON_SENSOR_MODE \
      VERBOSE SHOW_VERSIONS
```

Use this command to clear your environment before setting new values or switching between different deployments.

### Download and Run Locally
```bash
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh
chmod +x quick-deploy.sh
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="your-cluster-name"
./quick-deploy.sh
```

## 🏷️ Interactive Image Version Selection

### 🎯 Dynamic Version Selection (NEW!)

The script now **dynamically fetches available versions** from CrowdStrike's API in real-time and presents them for interactive selection.

#### Method 1: Interactive Selection (Recommended)

**⚠️ IMPORTANT: Interactive mode requires downloading the script locally**

```bash
# Step 1: Download the script
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh

# Step 2: Make it executable
chmod +x quick-deploy.sh

# Step 3: Set required environment variables
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="your-cluster-name"

# Step 4: Set optional component selections (defaults to true)
export INSTALL_SENSOR=true           # Falcon Sensor (node protection)
export INSTALL_KAC=true              # Kubernetes Admission Controller
export INSTALL_IAR=true              # Image Analyzer
export IS_GKE_AUTOPILOT=false        # Set to true for GKE Autopilot
export FALCON_SENSOR_MODE=kernel     # Sensor mode: kernel, bpf

# Step 5: Run the script locally
./quick-deploy.sh
```

> **📝 Why Download Required?** Interactive prompts need direct access to your terminal's input stream (stdin). When you pipe through `curl | bash`, stdin is consumed by curl and the script can't read your responses.

**Interactive Experience:**

```console
🏷️ Fetching latest available image versions...

Falcon Sensor versions available:
  1    7.31.0-18410-1
  2    7.32.0-18504-1
  3    7.33.0-18606-1
  4    7.34.0-18708-1
  5    7.35.0-18810-1  ← New versions appear automatically

Select Falcon Sensor version (1-5, or 'latest' for newest): 4
✅ Selected Falcon Sensor version: 7.34.0-18708-1

Falcon KAC versions available:
  1    7.33.0-3105
  2    7.34.0-3201
  3    7.35.0-3302

Select Falcon KAC version (1-3, or 'latest' for newest): latest
ℹ️  Using latest Falcon KAC version

Version selections summary:
  Sensor: 7.34.0-18708-1
  KAC: latest
  Image Analyzer: latest

Proceed with these version selections? [Y/n]: y
```

#### Method 2: Force Interactive in Cloud Shell

**For non-TTY environments like Google Cloud Shell, AWS CloudShell, etc.**

```bash
# Step 1: Download the script
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh

# Step 2: Make it executable
chmod +x quick-deploy.sh

# Step 3: Set required environment variables
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="your-cluster-name"

# Step 4: Set optional component selections
export INSTALL_SENSOR=true
export INSTALL_KAC=true
export INSTALL_IAR=true
export IS_GKE_AUTOPILOT=false        # Set to true for GKE Autopilot
export FALCON_SENSOR_MODE=kernel     # Sensor mode: kernel, bpf

# Step 5: Force interactive mode
export FORCE_INTERACTIVE=true

# Step 6: Run the script
./quick-deploy.sh
```

#### Method 3: Skip Interactive (Automation)

```bash
# Uses latest versions automatically - no prompts
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="your-cluster-name"
export SKIP_VERSION_SELECTION=true

curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

#### Method 4: Pre-set Specific Versions

```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="your-cluster-name"

# Pre-set versions (skips interactive selection)
export FALCON_SENSOR_VERSION="7.34.0-18708-1"
export FALCON_KAC_VERSION="7.35.0-3302"
export FALCON_IAR_VERSION="1.0.23"

./quick-deploy.sh
```

### 📋 List Available Versions Only

```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"

./quick-deploy.sh list-versions
```

**Sample Output:**
```console
🛡️ CrowdStrike Falcon Available Image Versions

Falcon Sensor versions:
  7.31.0-18410-1
  7.32.0-18504-1
  7.33.0-18606-1
  7.34.0-18708-1

Falcon KAC versions:
  7.33.0-3105
  7.34.0-3201
  7.35.0-3302

Falcon Image Analyzer versions:
  1.0.20
  1.0.21
  1.0.22
  1.0.23
```

### 🔄 Version Selection Priority

1. **Pre-set environment variables** - Highest priority, skips interactive selection
2. **Interactive selection** - Prompts during deployment (default for TTY)
3. **Latest versions** - Used when no selection made or in non-interactive mode

### ✨ Why Dynamic Versions?

- **🔄 Always Current**: Versions fetched real-time from CrowdStrike API
- **🚀 Zero Maintenance**: New releases appear automatically
- **🎯 Real Selection**: Choose only from available versions
- **📦 Latest Available**: "latest" option gets absolute newest version

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
```
NAMESPACE               NAME                                          READY   STATUS    RESTARTS   AGE
falcon-image-analyzer   falcon-platform-falcon-image-analyzer-xxx    1/1     Running   0          2m
falcon-kac              falcon-kac-xxx-xxx                           3/3     Running   0          2m
falcon-system           falcon-platform-falcon-sensor-xxx            1/1     Running   0          2m
```

## 🗑️ Comprehensive Cleanup Guide

### 🎯 Enhanced One-Command Cleanup (Recommended)

The script now includes **intelligent cleanup** that automatically detects and removes all types of Falcon installations:

```bash
# Complete automated cleanup
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash -s cleanup
```

**What gets automatically removed:**

- ✅ **Falcon Platform umbrella chart** deployments (helm)
- ✅ **Individual component releases** (falcon-sensor, falcon-kac, falcon-image-analyzer)
- ✅ **Falcon Operator** installations and Custom Resource Definitions (CRDs)
- ✅ **All related namespaces** (falcon-platform, falcon-system, falcon-kac, falcon-image-analyzer, falcon-operator, crowdstrike-*)
- ✅ **ValidatingWebhookConfigurations** and admission controllers
- ✅ **AllowlistSynchronizers** (GKE Autopilot specific)
- ✅ **Stuck resources and finalizers** handling
- ✅ **Cross-namespace resource cleanup**

### 📋 Cleanup Scenarios

#### Scenario 1: Platform Chart Installation (Most Common)

```bash
# If you deployed using the umbrella chart (this script)
./quick-deploy.sh cleanup
```

**Sample Output:**
```console
🧹 Cleaning up existing Falcon deployment...

Searching for all Falcon-related releases across all namespaces...
Removing release 'falcon-platform' from namespace 'falcon-platform'...
✅ Falcon Platform umbrella chart deployments

Removing Falcon namespaces...
✅ All namespaces (falcon-platform, falcon-system, falcon-kac, falcon-image-analyzer)

Removing webhook configurations...
✅ ValidatingWebhookConfigurations

✅ Cleanup completed
ℹ️  You can now run the deployment again
```

#### Scenario 2: Mixed Installation Cleanup

```bash
# If you have a combination of platform chart + individual components
./quick-deploy.sh cleanup
```

**Sample Output:**
```console
🧹 Cleaning up existing Falcon deployment...

Found individual Falcon component releases (non-platform chart):
  falcon-sensor      falcon-system        deployed
  falcon-kac         falcon-kac           deployed

⚠️  Individual Falcon component releases cleaned up

Found Falcon Operator releases:
  falcon-operator    falcon-operator      deployed

Found Falcon/CrowdStrike CRDs:
  falconadmissions.falcon.crowdstrike.com
  falconcontainers.falcon.crowdstrike.com

⚠️  Falcon Operator installation cleaned up

✅ Cleanup completed
```

#### Scenario 3: GKE Autopilot Cleanup

```bash
# Automatically handles GKE Autopilot specific resources
./quick-deploy.sh cleanup
```

**Additional cleanup for Autopilot:**
- ✅ Removes `AllowlistSynchronizer` resources
- ✅ Cleans up `WorkloadAllowlist` configurations
- ✅ Handles Autopilot-specific security constraints

### 🔧 Manual Cleanup (Troubleshooting)

If automated cleanup fails or you need granular control:

#### Step 1: Remove Helm Releases

```bash
# Platform chart (umbrella deployment)
helm uninstall falcon-platform -n falcon-platform --ignore-not-found

# Individual components (if they exist)
helm uninstall falcon-sensor -n falcon-system --ignore-not-found
helm uninstall falcon-kac -n falcon-kac --ignore-not-found
helm uninstall falcon-image-analyzer -n falcon-image-analyzer --ignore-not-found

# Falcon Operator
helm uninstall falcon-operator -n falcon-operator --ignore-not-found
```

#### Step 2: Remove Namespaces

```bash
# Delete all Falcon-related namespaces
kubectl delete namespace \
  falcon-platform \
  falcon-system \
  falcon-kac \
  falcon-image-analyzer \
  falcon-operator \
  --ignore-not-found \
  --timeout=120s
```

#### Step 3: Clean Up Webhooks and CRDs

```bash
# Remove validating webhooks
kubectl delete validatingwebhookconfigurations \
  -l app.kubernetes.io/instance=falcon-platform \
  --ignore-not-found

# Remove individual webhook configurations
kubectl delete validatingwebhookconfigurations \
  validating.falcon-kac.crowdstrike.com \
  falcon-kac-validating-webhook \
  --ignore-not-found

# Remove CrowdStrike CRDs
kubectl get crd | grep -E "(falcon|crowdstrike)" | awk '{print $1}' | \
  xargs -r kubectl delete crd --ignore-not-found
```

#### Step 4: GKE Autopilot Specific

```bash
# Remove AllowlistSynchronizer (GKE Autopilot only)
kubectl delete allowlistsynchronizers crowdstrike-synchronizer --ignore-not-found
```

#### Step 5: Force Clean Stuck Resources

```bash
# Remove stuck resources with finalizers
kubectl delete all,pvc,secrets,configmaps \
  -l app.kubernetes.io/instance=falcon-platform \
  --all-namespaces \
  --ignore-not-found \
  --force \
  --grace-period=0
```

### 🔍 Cleanup Verification

```bash
# Verify no Helm releases remain
helm list -A | grep falcon

# Check for remaining namespaces
kubectl get namespace | grep -E "(falcon|crowdstrike)"

# Verify no pods are running
kubectl get pods -A | grep falcon

# Check for remaining webhooks
kubectl get validatingwebhookconfigurations | grep -i crowdstrike

# Verify CRDs are removed
kubectl get crd | grep -E "(falcon|crowdstrike)"
```

### ⚠️ Troubleshooting Common Issues

**Namespace Stuck in Terminating:**
```bash
# Force remove finalizers
kubectl get namespace falcon-system -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw "/api/v1/namespaces/falcon-system/finalize" -f -
```

**Webhook Blocking Operations:**
```bash
# Temporarily disable webhooks
kubectl delete validatingwebhookconfigurations --all
```

**CRDs Won't Delete:**
```bash
# Remove finalizers from CRDs
kubectl patch crd falconadmissions.falcon.crowdstrike.com -p '{"metadata":{"finalizers":[]}}' --type=merge
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

- **Issues**: [GitHub Issues](https://github.com/mikedzikowski/crowdstrike-deployment-simplifier/issues)
- **Documentation**: [CrowdStrike Falcon Helm Charts](https://github.com/CrowdStrike/falcon-helm)
- **Console**: [falcon.crowdstrike.com](https://falcon.crowdstrike.com)