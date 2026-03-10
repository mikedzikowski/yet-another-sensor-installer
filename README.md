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

#### Method 1: Interactive Prompts (Recommended)
```bash
export FALCON_CLIENT_ID="your-client-id" && \
export FALCON_CLIENT_SECRET="your-client-secret" && \
export CLUSTERNAME="your-cluster-name" && \
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh && \
chmod +x quick-deploy.sh && \
./quick-deploy.sh
```

#### Method 2: Piped with Defaults (All Components)
```bash
export FALCON_CLIENT_ID="your-client-id" && \
export FALCON_CLIENT_SECRET="your-client-secret" && \
export CLUSTERNAME="your-cluster-name" && \
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```

#### Method 3: Piped with Custom Component Selection
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

> **⚠️ Note**: Interactive prompts only work with Method 1 (downloaded script). Methods 2 & 3 use environment variables for component selection.

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
========================================

[WARNING] Script is running in non-interactive mode.
[INFO] Detected piped execution. Using environment variables or defaults.

[INFO] Final component selections:
[SUCCESS] ✅ Falcon Sensor will be installed
[SUCCESS] ✅ Falcon KAC will be installed
[SUCCESS] ✅ Falcon Image Analyzer will be installed
[INFO] Standard Kubernetes mode

[INFO] Validating environment variables...
[SUCCESS] All required environment variables are set
[INFO] Using CLUSTERNAME: my-k8s-cluster
[INFO] Using FALCON_CLIENT_ID: your-cli...

[INFO] Checking prerequisites...
[SUCCESS] All prerequisites are installed
[INFO] Downloading CrowdStrike falcon-container-sensor-pull.sh script...
[SUCCESS] Downloaded and configured falcon-container-sensor-pull.sh
[INFO] Retrieving Falcon configuration...
[SUCCESS] Configuration retrieved successfully

[INFO] Configuration Summary:
==========================================
FALCON_CID: 01234567ABCDEF1234567890ABCDEF12-34
ENCODED_DOCKER_CONFIG: eyJhdXRocyI6IHsgInJlZ2lzdHJ5LmNyb3dkc3RyaWtlLmNvbS...

Selected Components:
  ✅ Falcon Sensor - Image: registry.crowdstrike.com/falcon-sensor/release/falcon-sensor:7.34.0-18708-1
  ✅ Falcon KAC - Image: registry.crowdstrike.com/falcon-kac/release/falcon-kac:7.35.0-3302
  ✅ Falcon Image Analyzer - Image: registry.crowdstrike.com/falcon-imageanalyzer/us-1/release/falcon-imageanalyzer:1.0.23

Cluster Configuration:
  - Name: my-k8s-cluster
  - Type: Standard Kubernetes
==========================================
[INFO] Adding CrowdStrike Helm repository...
[SUCCESS] Helm repository added and updated
[INFO] Deploying Falcon Platform...
[INFO] Deployment in progress.......... [Creating namespaces].......... [Pulling container images].......... ✓
[SUCCESS] Falcon Platform deployed successfully!
[INFO] Verifying deployment...
[INFO] Waiting for pods to start.................... ✓

[INFO] Deployment Status:
===================
NAME            NAMESPACE       REVISION        UPDATED                 STATUS          CHART                   APP VERSION
falcon-platform falcon-platform 1               2026-03-10 20:26:53.226 deployed        falcon-platform-1.2.0

Falcon Pods:
falcon-image-analyzer   falcon-platform-falcon-image-analyzer-abc123-def45   1/1     Running             0               30s
falcon-kac              falcon-kac-55694c97f9-xyz89                          3/3     Running             0               30s
falcon-system           falcon-platform-falcon-sensor-node1                  1/1     Running             0               30s
falcon-system           falcon-platform-falcon-sensor-node2                  1/1     Running             0               30s
falcon-system           falcon-platform-falcon-sensor-node3                  1/1     Running             0               30s
[SUCCESS] Initial verification complete!

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

### Custom Falcon Cloud

If auto-detection doesn't work, you can override the Falcon cloud:

```bash
export FALCON_CLOUD="api.us-2.crowdstrike.com"  # US-2
# or
export FALCON_CLOUD="api.eu-1.crowdstrike.com"  # EU-1
# or
export FALCON_CLOUD="api.laggar.gcw.crowdstrike.com"  # Gov
```

### Debug Mode

Enable verbose output for troubleshooting:

```bash
export DEBUG=true
./deploy-falcon.sh
```

### Dry Run

See what would be deployed without actually deploying:

```bash
export DRY_RUN=true
./deploy-falcon.sh
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

## 🧪 Testing the Enhanced Deployment Script

### Prerequisites for Testing

1. **Clean Kubernetes cluster** (or cleaned up existing deployment using instructions above)
2. **Valid CrowdStrike OAuth credentials** with required permissions
3. **kubectl** and **helm** configured and working
4. **Internet access** from cluster to CrowdStrike registry

### Test Scenarios

The enhanced script now supports component selection and GKE Autopilot. Test the following scenarios:

#### Test 1: All Components (Default Behavior)
```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="test-all-components"
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```
**User Responses**: Y, Y, Y, N (Sensor=Yes, KAC=Yes, IAR=Yes, GKE=No)

**Expected Results**:
- ✅ Falcon Sensor DaemonSet in `falcon-system` namespace
- ✅ Falcon KAC Deployment in `falcon-kac` namespace
- ✅ Falcon Image Analyzer Deployment in `falcon-image-analyzer` namespace

#### Test 2: Sensor Only
```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="test-sensor-only"
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```
**User Responses**: Y, N, N, N (Sensor=Yes, KAC=No, IAR=No, GKE=No)

**Expected Results**:
- ✅ Only Falcon Sensor deployed
- ❌ No KAC or IAR components
- Only `falcon-system` namespace created

#### Test 3: KAC + IAR (No Sensor)
```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="test-kac-iar"
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```
**User Responses**: N, Y, Y, N (Sensor=No, KAC=Yes, IAR=Yes, GKE=No)

**Expected Results**:
- ❌ No Sensor DaemonSet
- ✅ Falcon KAC and IAR deployed
- `falcon-kac` and `falcon-image-analyzer` namespaces created

#### Test 4: GKE Autopilot Simulation
```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="test-gke-autopilot"
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash
```
**User Responses**: Y, Y, Y, Y (All components + GKE Autopilot=Yes)

**Expected Results**:
- ✅ All components deployed with GKE Autopilot configurations
- ✅ AllowlistSynchronizer created (will show error on non-GKE clusters - this is expected)
- Helm values include `--set falcon-sensor.node.gke.autopilot=true`

### Testing Commands

#### Pre-Test Cleanup
```bash
# Clean slate before each test
helm uninstall falcon-platform -n falcon-platform --ignore-not-found
kubectl delete namespace falcon-platform falcon-system falcon-kac falcon-image-analyzer --ignore-not-found
kubectl delete validatingwebhookconfigurations -l app.kubernetes.io/instance=falcon-platform --ignore-not-found
kubectl delete allowlistsynchronizers crowdstrike-synchronizer --ignore-not-found
```

#### Validation Commands
```bash
# Check deployment status
kubectl get pods -A | grep falcon

# Verify Helm release
helm list -n falcon-platform

# Check namespaces created
kubectl get namespaces | grep falcon

# Validate component-specific resources
kubectl get daemonsets -A | grep falcon      # Sensor
kubectl get deployments -A | grep falcon     # KAC and IAR
kubectl get validatingwebhookconfigurations | grep crowdstrike  # KAC webhook

# (GKE Autopilot test) Check AllowlistSynchronizer
kubectl get allowlistsynchronizers crowdstrike-synchronizer
```

### Expected Script Output

The enhanced script provides visual feedback:

```
🛡️  CrowdStrike Falcon Simple Deployment
========================================

[INFO] Component Selection
===============================================
Choose which CrowdStrike components to install:

Install Falcon Sensor (Node Protection)? [Y/n]: Y
[SUCCESS] Falcon Sensor will be installed

Install Falcon KAC (Kubernetes Admission Controller)? [Y/n]: Y
[SUCCESS] Falcon KAC will be installed

Install Falcon Image Analyzer (Container Scanning)? [Y/n]: N
[WARNING] Falcon Image Analyzer will NOT be installed

Is this a GKE Autopilot cluster? [y/N]: N

[INFO] Configuration Summary:
==========================================
Selected Components:
  ✅ Falcon Sensor - Image: registry.crowdstrike.com/falcon-sensor/release/falcon-sensor:x.x.x
  ✅ Falcon KAC - Image: registry.crowdstrike.com/falcon-kac/release/falcon-kac:x.x.x
  ❌ Falcon Image Analyzer (disabled)

Cluster Configuration:
  - Name: your-cluster-name
  - Type: Standard Kubernetes
==========================================
```

### Troubleshooting Test Issues

#### Component Selection Not Working
- Ensure you're using the latest script from the repository
- Check that interactive prompts are supported in your environment

#### GKE Autopilot Test Failures (Non-GKE)
- AllowlistSynchronizer creation will fail on non-GKE clusters (expected)
- The script should continue and deploy other components successfully

#### Validation Failures
- Wait 1-2 minutes for pods to fully start
- Check logs: `kubectl logs -n <namespace> <pod-name>`
- Verify cluster resources are sufficient

> **💡 Tip**: Test each scenario in sequence, cleaning up between tests to ensure accurate validation of component selection logic.

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

For advanced configuration, extract the generated values and customize:

```bash
# Generate values file (requires DRY_RUN=true)
export DRY_RUN=true
./deploy-falcon.sh > my-values.yaml

# Deploy with custom values
helm install falcon-platform crowdstrike/falcon-platform \
  -f my-values.yaml \
  --namespace falcon-platform
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
