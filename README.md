# CrowdStrike Falcon Simple Deployment

A simplified deployment solution for CrowdStrike Falcon Platform on Kubernetes that requires only **3 environment variables**.

> **⚠️ DISCLAIMER**: This is **NOT an official CrowdStrike tool**. This is a community-created deployment simplifier. Please test thoroughly in non-production environments and use at your own discretion. For official CrowdStrike deployment tools, visit [CrowdStrike Falcon Helm Charts](https://github.com/CrowdStrike/falcon-helm).

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


## 🚀 Quick Start

### Basic Deployment
```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="your-cluster-name"

curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

### Interactive Version Selection
```bash
# Download for interactive prompts
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh
chmod +x quick-deploy.sh
./quick-deploy.sh
```

### Platform-Specific Configuration

**Standard Kubernetes (AKS, EKS, GKE Standard):**
```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="your-cluster-name"  # e.g., "aks-prod", "eks-prod", "gke-standard"

curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

**GKE Autopilot:**
```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret"
export CLUSTERNAME="gke-autopilot-prod"
export IS_GKE_AUTOPILOT=true
export FALCON_SENSOR_MODE=bpf  # Recommended for Autopilot

curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

**Component Selection:**
```bash
export INSTALL_SENSOR=true   # Falcon Sensor (default: true)
export INSTALL_KAC=true      # Kubernetes Admission Controller (default: true)
export INSTALL_IAR=true      # Image Analyzer (default: true)
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
| `IS_GKE_AUTOPILOT` | `false` | Enable GKE Autopilot specific configurations |
| `FALCON_SENSOR_MODE` | `kernel` | Sensor mode (kernel/bpf) |
| `SKIP_VERSION_SELECTION` | `false` | Skip interactive version prompts |
| `VERBOSE` | `false` | Show detailed deployment information |

### Version Control
```bash
export FALCON_SENSOR_VERSION="7.34.0-18708-1"     # Specific Falcon Sensor version (optional)
export FALCON_KAC_VERSION="7.35.0-3302"           # Specific Falcon KAC version (optional)
export FALCON_IAR_VERSION="1.0.12"                # Specific Image Analyzer version (optional)
```

## 🏷️ Version Selection

### Interactive Selection (Recommended)
Download the script locally to use interactive version selection:

```bash
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh
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
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
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
```
NAMESPACE               NAME                                          READY   STATUS    RESTARTS   AGE
falcon-image-analyzer   falcon-platform-falcon-image-analyzer-xxx    1/1     Running   0          2m
falcon-kac              falcon-kac-xxx-xxx                           3/3     Running   0          2m
falcon-system           falcon-platform-falcon-sensor-xxx            1/1     Running   0          2m
```

## 🗑️ Cleanup

### Automated Cleanup (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash -s cleanup
```

The script automatically removes:
- Falcon Platform umbrella chart deployments
- Individual component releases (falcon-sensor, falcon-kac, falcon-image-analyzer)
- All related namespaces and resources
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

- **Issues**: [GitHub Issues](https://github.com/mikedzikowski/crowdstrike-deployment-simplifier/issues)
- **Documentation**: [CrowdStrike Falcon Helm Charts](https://github.com/CrowdStrike/falcon-helm)
- **Console**: [falcon.crowdstrike.com](https://falcon.crowdstrike.com)