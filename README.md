# CrowdStrike Falcon Simple Deployment

A simplified deployment solution for CrowdStrike Falcon Platform on Kubernetes that requires only **3 environment variables**.

## 🎯 Overview

This repository provides a simple, one-command deployment script for customers who want to deploy the complete CrowdStrike Falcon security platform on Kubernetes without needing deep Kubernetes expertise.

**What gets deployed:**
- ✅ **Falcon Sensor** - Runtime protection for Kubernetes nodes
- ✅ **Falcon Kubernetes Admission Controller (KAC)** - Policy enforcement and workload protection
- ✅ **Falcon Image Analyzer** - Container image vulnerability scanning

## 🚀 Quick Start

### Prerequisites

- **Kubernetes cluster** with kubectl access
- **Helm 3.x** installed
- **curl** utility
- **CrowdStrike Falcon OAuth credentials** with appropriate permissions

### Required Permissions for OAuth Client

Your Falcon OAuth client needs these **specific API scopes**:

| API Scope | Permission Level | Purpose |
|-----------|------------------|---------|
| **Falcon Container CLI** | **Write** | Deploy and manage Falcon containers in Kubernetes |
| **Falcon Container Image** | **Read/Write** | Pull container images and manage registry credentials |
| **Falcon Images Download** | **Read** | Download Falcon sensor and component images |
| **Sensor Download** | **Read** | Access sensor installation packages and metadata |
| **Installation Tokens** | **Read** | Retrieve customer ID (CID) and provisioning tokens |

#### How to Create OAuth Client with Required Scopes

1. **Log into Falcon Console**: Go to [falcon.crowdstrike.com](https://falcon.crowdstrike.com)
2. **Navigate to API Clients**: Go to **Support and resources** → **API Clients & Keys**
3. **Create New Client**: Click **Add new API client**
4. **Configure Client**:
   - **Name**: `Kubernetes Deployment Client`
   - **Description**: `Client for simplified Kubernetes deployments`
5. **Select Required Scopes**: Add the following scopes with specified permissions:
   ```
   ✅ Falcon Container CLI: Write
   ✅ Falcon Container Image: Read/Write
   ✅ Falcon Images Download: Read
   ✅ Sensor Download: Read
   ✅ Installation Tokens: Read
   ```
6. **Save Client**: Copy the **Client ID** and **Client Secret** immediately

#### Environment Variables Required

```bash
export FALCON_CLIENT_ID="your-falcon-oauth-client-id"        # From step 6 above
export FALCON_CLIENT_SECRET="your-falcon-oauth-client-secret" # From step 6 above
export CLUSTERNAME="your-cluster-name"                       # Any descriptive name for your cluster
```

> ⚠️ **Security Note**: The Client Secret is only shown once during creation. Store it securely!

### One-Command Deployment

The script uses environment variables for all configuration. Simply set the required variables and run:

```bash
export FALCON_CLIENT_ID="your-client-id" && \
export FALCON_CLIENT_SECRET="your-client-secret" && \
export CLUSTERNAME="your-cluster-name" && \
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

#### Custom Component Selection

```bash
export FALCON_CLIENT_ID="your-client-id" && \
export FALCON_CLIENT_SECRET="your-client-secret" && \
export CLUSTERNAME="your-cluster-name" && \
export INSTALL_SENSOR=true && \
export INSTALL_KAC=false && \
export INSTALL_IAR=true && \
export IS_GKE_AUTOPILOT=false && \
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

#### Download and Run Locally

```bash
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh && \
chmod +x quick-deploy.sh && \
export FALCON_CLIENT_ID="your-client-id" && \
export FALCON_CLIENT_SECRET="your-client-secret" && \
export CLUSTERNAME="your-cluster-name" && \
./quick-deploy.sh
```

That's it! ✨

## 📋 What the Script Does

The deployment script automatically:

1. **Downloads** the official CrowdStrike `falcon-container-sensor-pull.sh` script
2. **Validates** your environment and prerequisites
3. **Retrieves** your Customer ID (CID) using the official script
4. **Obtains** container registry credentials automatically
5. **Gets** the latest image paths for all Falcon components
6. **Configures** all required Helm values automatically
7. **Deploys** the complete Falcon Platform using the umbrella Helm chart
8. **Verifies** the deployment and shows status
9. **Cleans up** temporary files

### Auto-Discovery Features

- 🔍 **Automatic CID Discovery** - No need to manually find your Customer ID
- 🏗️ **Registry Auto-Configuration** - Automatically configures container registry access
- 🌐 **Cloud Auto-Detection** - Detects your Falcon cloud (US-1, US-2, EU-1, Gov)
- 📦 **Latest Images** - Uses the most current Falcon component images

## 📺 Example Deployment Output

Here's what you'll see when running the deployment:

```bash
$ export FALCON_CLIENT_ID="your-client-id"
$ export FALCON_CLIENT_SECRET="your-client-secret"
$ export CLUSTERNAME="my-k8s-cluster"
$ curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash

🛡️  CrowdStrike Falcon Simple Deployment
────────────────────────────────────────────────────────────────

────────────────────────────────────────────────────────────────
🔧 COMPONENT CONFIGURATION
────────────────────────────────────────────────────────────────

Customization options:
      export INSTALL_SENSOR=false    # disable Sensor
      export INSTALL_KAC=false       # disable KAC
      export INSTALL_IAR=false       # disable IAR
      export IS_GKE_AUTOPILOT=true   # enable GKE Autopilot
      export VERBOSE=true             # enable verbose output

Selected components:
      ✅ Falcon Sensor
      ✅ Falcon KAC
      ✅ Falcon Image Analyzer

Cluster type:
      🖥️  Standard Kubernetes

────────────────────────────────────────────────────────────────
🔧 ENVIRONMENT VALIDATION
────────────────────────────────────────────────────────────────

Environment variables validated
      Cluster: my-k8s-cluster
      Client ID: your-cli...

────────────────────────────────────────────────────────────────
🔧 PREREQUISITES CHECK
────────────────────────────────────────────────────────────────

All prerequisites verified
      ✓ kubectl connected to cluster
      ✓ Helm 3.x available
      ✓ curl available

────────────────────────────────────────────────────────────────
🔧 FALCON SCRIPT DOWNLOAD
────────────────────────────────────────────────────────────────

Official CrowdStrike script downloaded

────────────────────────────────────────────────────────────────
🔧 FALCON CONFIGURATION
────────────────────────────────────────────────────────────────

Falcon configuration retrieved
      ✓ Customer ID acquired
      ✓ Registry access configured
      ✓ All component images resolved

────────────────────────────────────────────────────────────────
🔧 DEPLOYMENT CONFIGURATION
────────────────────────────────────────────────────────────────

Customer configuration:
      CID: 01234567ABCDEF1234567890ABCDEF12-34
      Cluster: my-k8s-cluster

Selected components:
      ✅ Falcon Sensor
      ✅ Falcon KAC
      ✅ Falcon Image Analyzer

Cluster configuration:
      🖥️  Standard Kubernetes

────────────────────────────────────────────────────────────────
🔧 HELM REPOSITORY
────────────────────────────────────────────────────────────────

[SUCCESS] Helm repository configured

────────────────────────────────────────────────────────────────
🔧 FALCON PLATFORM DEPLOYMENT
────────────────────────────────────────────────────────────────

[INFO] Deployment in progress.......... [Creating namespaces].......... [Pulling container images].......... ✓
[SUCCESS] Falcon Platform deployed successfully!

[SUCCESS] 🎉 CrowdStrike Falcon Platform has been successfully deployed!

Components deployed:
  ✅ Falcon Sensor (Node protection)
  ✅ Falcon Kubernetes Admission Controller (Policy enforcement)
  ✅ Falcon Image Analyzer (Container image scanning)

Next steps:
  1. Monitor the deployment: kubectl get pods -A | grep falcon
  2. Check logs if needed: kubectl logs -n <namespace> <pod-name>
  3. View in Falcon Console: https://falcon.crowdstrike.com
```

> **✨ Key Features Shown:**
> - Progress indicators during deployment ("Deployment in progress...")
> - Component selection confirmation
> - Real-time pod status monitoring
> - Clean, organized output with clear success indicators

## 🏗️ Architecture

The script deploys components into dedicated namespaces:

```
Kubernetes Cluster
├── falcon-system/          # Falcon Sensor (DaemonSet)
├── falcon-kac/             # Kubernetes Admission Controller
├── falcon-image-analyzer/  # Image Analysis Runtime Agent
└── falcon-platform/        # Main deployment namespace
```

## 🔧 Advanced Configuration

### Verbose Mode

Enable verbose output for troubleshooting:

```bash
export VERBOSE=true
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
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

After successful deployment, you should see:

```
NAMESPACE               NAME                                          READY   STATUS    RESTARTS   AGE
falcon-image-analyzer   falcon-platform-falcon-image-analyzer-xxx    1/1     Running   0          2m
falcon-kac              falcon-kac-xxx-xxx                           3/3     Running   0          2m
falcon-system           falcon-platform-falcon-sensor-xxx            1/1     Running   0          2m
```

## 🗑️ Cleanup & Uninstallation

### Complete Cleanup

To completely remove CrowdStrike Falcon Platform and all associated resources:

#### Method 1: Single Command Cleanup
```bash
helm uninstall falcon-platform -n falcon-platform && \
kubectl delete namespace falcon-platform falcon-system falcon-kac falcon-image-analyzer --ignore-not-found && \
kubectl delete validatingwebhookconfigurations -l app.kubernetes.io/instance=falcon-platform --ignore-not-found
```

#### Method 2: Step-by-Step Cleanup
```bash
# 1. Remove the Helm release
helm uninstall falcon-platform -n falcon-platform

# 2. Delete all CrowdStrike namespaces
kubectl delete namespace falcon-platform falcon-system falcon-kac falcon-image-analyzer --ignore-not-found

# 3. Clean up ValidatingWebhookConfigurations
kubectl delete validatingwebhookconfigurations -l app.kubernetes.io/instance=falcon-platform --ignore-not-found

# 4. (GKE Autopilot only) Remove AllowlistSynchronizer if present
kubectl delete allowlistsynchronizers crowdstrike-synchronizer --ignore-not-found
```

### Verification of Cleanup

Verify complete removal:

```bash
# Check no Helm releases remain
helm list -A | grep falcon

# Check no namespaces remain
kubectl get namespaces | grep falcon

# Check no pods remain
kubectl get pods -A | grep falcon

# Check no ValidatingWebhookConfigurations remain
kubectl get validatingwebhookconfigurations | grep crowdstrike

# (GKE Autopilot only) Check no AllowlistSynchronizers remain
kubectl get allowlistsynchronizers | grep crowdstrike
```

### Selective Component Removal

If you used component selection during deployment, you can remove specific components:

#### Remove Only Falcon Sensor
```bash
kubectl delete daemonset -n falcon-system falcon-platform-falcon-sensor
kubectl delete namespace falcon-system --ignore-not-found
```

#### Remove Only Falcon KAC
```bash
kubectl delete deployment -n falcon-kac falcon-kac
kubectl delete validatingwebhookconfigurations validating.falcon-kac.crowdstrike.com --ignore-not-found
kubectl delete namespace falcon-kac --ignore-not-found
```

#### Remove Only Falcon Image Analyzer
```bash
kubectl delete deployment -n falcon-image-analyzer falcon-platform-falcon-image-analyzer
kubectl delete namespace falcon-image-analyzer --ignore-not-found
```

> **⚠️ Important**: Always perform complete cleanup in test environments to ensure clean slate for re-deployment testing.

## 🧪 Testing & Validation

### Test with Verbose Output

Enable detailed logging to see what's happening:

```bash
export VERBOSE=true
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="test-cluster"
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

Verbose mode shows:
- API call details and responses
- Image path resolution
- Registry credential generation progress
- Detailed error context when issues occur

### Component Selection Testing

Test different component combinations:

```bash
# Sensor only
export INSTALL_SENSOR=true INSTALL_KAC=false INSTALL_IAR=false

# KAC and IAR only
export INSTALL_SENSOR=false INSTALL_KAC=true INSTALL_IAR=true

# All components (default)
# No exports needed - script defaults to all enabled
```

### Common Issues

#### Authentication Errors
```
[ERROR] Authentication failed: access denied
```
**Solution**: Verify your `FALCON_CLIENT_ID` and `FALCON_CLIENT_SECRET` are correct and have the required permissions.

#### Registry Access Errors
```
[ERROR] Failed to pull image: unauthorized
```
**Solution**: Ensure your OAuth client has "Falcon Container Image: Read/Write" permissions.

#### Pod Startup Issues
```
[WARNING] Timeout waiting for pods to be ready
```
**Solution**:
1. Check if your cluster has sufficient resources
2. Verify network policies allow CrowdStrike registry access
3. Check pod logs: `kubectl logs -n <namespace> <pod-name>`

### Getting Help

1. **Check logs**: `kubectl logs -n falcon-system -l app.kubernetes.io/instance=falcon-platform`
2. **Review events**: `kubectl get events -A | grep falcon`
3. **Validate connectivity**: Ensure your cluster can reach `*.crowdstrike.com`

### Network Requirements

Your cluster needs outbound access to:
- `api.crowdstrike.com` (or your cloud variant)
- `registry.crowdstrike.com`
- `*.crowdstrike.com`

## 🎛️ Customization

### Using Individual Charts

If you need more control, use the individual Helm charts instead:

- [falcon-sensor](https://github.com/CrowdStrike/falcon-helm/tree/main/helm-charts/falcon-sensor)
- [falcon-kac](https://github.com/CrowdStrike/falcon-helm/tree/main/helm-charts/falcon-kac)
- [falcon-image-analyzer](https://github.com/CrowdStrike/falcon-helm/tree/main/helm-charts/falcon-image-analyzer)

### Custom Values

For advanced configuration, customize component deployment:

```bash
# Deploy with custom component selection
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="your-cluster-name"
export INSTALL_SENSOR=true
export INSTALL_KAC=false      # Disable KAC
export INSTALL_IAR=true
export VERBOSE=true           # Enable verbose output
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

Or deploy individual charts directly:

```bash
# Example: Deploy only Falcon Sensor
helm install falcon-sensor crowdstrike/falcon-sensor \
  --namespace falcon-system \
  --create-namespace \
  --set falcon.cid="your-cid" \
  --set image.repository="registry.crowdstrike.com/falcon-sensor/release/falcon-sensor" \
  --set image.tag="latest"
```

## 🤝 Support

- **CrowdStrike Customers**: Use your existing support channels
- **Community Support**: [GitHub Issues](https://github.com/mikedzikowski/crowdstrike-deployment-simplifier/issues)
- **Official Documentation**: [CrowdStrike Falcon Helm Charts](https://github.com/CrowdStrike/falcon-helm)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Resources

- [CrowdStrike Falcon Helm Charts](https://github.com/CrowdStrike/falcon-helm)
- [Falcon Platform Documentation](https://falcon.crowdstrike.com/documentation)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)

---

**⚠️ Important**: This script is designed for production use but always test in a non-production environment first. The script automatically uses the latest component versions - pin specific versions if you need reproducible deployments. 
