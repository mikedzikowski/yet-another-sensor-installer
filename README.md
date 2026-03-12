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
export FALCON_CLIENT_ID="your-falcon-oauth-client-id" && \
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret" && \
export INSTALL_SENSOR=true && \
export INSTALL_KAC=true && \
export INSTALL_IAR=true && \
export IS_GKE_AUTOPILOT=false && \
export CLUSTERNAME="aks-standard" && \
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

### EKS (Amazon Elastic Kubernetes Service)
```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id" && \
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret" && \
export INSTALL_SENSOR=true && \
export INSTALL_KAC=true && \
export INSTALL_IAR=true && \
export CLUSTERNAME="eks-cluster" && \
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

### GKE Standard (Google Kubernetes Engine)
```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id" && \
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret" && \
export INSTALL_SENSOR=true && \
export INSTALL_KAC=true && \
export INSTALL_IAR=true && \
export CLUSTERNAME="gke-standard" && \
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

### GKE Autopilot
```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id" && \
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret" && \
export INSTALL_SENSOR=true && \
export INSTALL_KAC=true && \
export INSTALL_IAR=true && \
export IS_GKE_AUTOPILOT=true && \
export CLUSTERNAME="gke-auto-pilot" && \
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

> **GKE Autopilot Note**: The script automatically creates an `AllowlistSynchronizer` resource that grants CrowdStrike workloads the necessary permissions to run security operations on GKE Autopilot clusters. This is required due to Autopilot's restrictive security policies.
>
> For more details, see: [GKE Autopilot Security Policies](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-security)

## 🔧 Configuration Options

### Component Selection
```bash
export INSTALL_SENSOR=true     # Enable/disable Falcon Sensor
export INSTALL_KAC=true        # Enable/disable Admission Controller
export INSTALL_IAR=true        # Enable/disable Image Analyzer
export IS_GKE_AUTOPILOT=true   # Enable GKE Autopilot mode
export VERBOSE=true            # Enable detailed output
```

### Download and Run Locally
```bash
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh
chmod +x quick-deploy.sh
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="your-cluster-name"
./quick-deploy.sh
```

## 🏷️ Image Version Selection

### List Available Versions
```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
./quick-deploy.sh list-versions
```

This shows all available image versions for each component:
```
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

### Deploy with Specific Versions
```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="your-cluster-name"

# Specify custom image versions
export FALCON_SENSOR_VERSION="7.33.0-18606-1"
export FALCON_KAC_VERSION="7.34.0-3201"
export FALCON_IAR_VERSION="1.0.22"

./quick-deploy.sh
```

**Version Selection Options:**
- **Latest (default)**: Script automatically uses newest available versions
- **Custom versions**: Set environment variables for specific versions
- **Mixed approach**: Specify versions only for some components, others use latest
- **Version validation**: Script validates specified versions exist before deployment

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

## 🗑️ Cleanup Instructions

### Enhanced Complete Removal (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash -s cleanup
```

The enhanced cleanup automatically removes:
- ✅ **Falcon Platform umbrella chart** deployments
- ✅ **Individual component releases** (falcon-sensor, falcon-kac, falcon-image-analyzer installed separately)
- ✅ **Falcon Operator** installations and Custom Resource Definitions (CRDs)
- ✅ **All namespaces** (falcon-platform, falcon-system, falcon-kac, falcon-image-analyzer, falcon-operator, crowdstrike-*)
- ✅ **ValidatingWebhookConfigurations**
- ✅ **AllowlistSynchronizers** (GKE Autopilot)
- ✅ **Stuck resources** and finalizers

### Manual Cleanup (if automated cleanup fails)
```bash
# Remove Helm releases (platform chart)
helm uninstall falcon-platform -n falcon-platform

# Remove individual component releases (if they exist)
helm uninstall falcon-sensor -n falcon-system --ignore-not-found
helm uninstall falcon-kac -n falcon-kac --ignore-not-found
helm uninstall falcon-image-analyzer -n falcon-image-analyzer --ignore-not-found

# Remove Falcon Operator (if installed)
helm uninstall falcon-operator -n falcon-operator --ignore-not-found

# Delete all Falcon namespaces
kubectl delete namespace falcon-platform falcon-system falcon-kac falcon-image-analyzer falcon-operator --ignore-not-found

# Clean up webhooks and CRDs
kubectl delete validatingwebhookconfigurations -l app.kubernetes.io/instance=falcon-platform --ignore-not-found
kubectl delete crd $(kubectl get crd | grep -E "(falcon|crowdstrike)" | awk '{print $1}') --ignore-not-found

# (GKE Autopilot only) Remove AllowlistSynchronizer
kubectl delete allowlistsynchronizers crowdstrike-synchronizer --ignore-not-found
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