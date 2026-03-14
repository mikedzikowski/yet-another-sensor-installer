# Changelog

## [v1.2.0] - 2026-03-14 - Stable User Mode Default

### 🎯 **Milestone: Stable Working Version**
This version represents a stable, tested deployment solution with improved defaults for modern Kubernetes environments.

### ✨ **Key Features**
- **Simplified Deployment**: Only 3 required environment variables (`FALCON_CLIENT_ID`, `FALCON_CLIENT_SECRET`, `CLUSTERNAME`)
- **Auto-Discovery**: Automatic CID discovery and registry configuration
- **Cloud Detection**: Automatic detection of Falcon cloud regions (US-1, US-2, EU-1, Gov)
- **Platform Support**: Full support for AKS, EKS, GKE Standard, and GKE Autopilot
- **Component Selection**: Modular deployment of Sensor, KAC, and Image Analyzer
- **Interactive/Automated Modes**: Support for both interactive version selection and CI/CD automation

### 🔧 **Major Changes**
- **Default Sensor Mode**: Changed from `kernel` to `bpf` (eBPF user mode)
  - Better compatibility with modern Kubernetes environments
  - Reduced kernel-level dependencies
  - Enhanced security through user-space operation
  - Improved support for containerized workloads

### 🛡️ **Deployed Components**
1. **Falcon Sensor** - Runtime protection for Kubernetes nodes (now defaults to eBPF user mode)
2. **Falcon Kubernetes Admission Controller (KAC)** - Policy enforcement and workload protection
3. **Falcon Image Analyzer** - Container image vulnerability scanning

### 🚀 **Usage**
```bash
export FALCON_CLIENT_ID="your-client-id"
export FALCON_CLIENT_SECRET="your-client-secret"
export CLUSTERNAME="your-cluster-name"

# Quick deployment (uses bpf user mode by default)
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash

# Or download for interactive mode
curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh
chmod +x quick-deploy.sh
./quick-deploy.sh
```

### ⚠️ **Important Notes**
- **Environment Variables**: Existing `FALCON_SENSOR_MODE` environment variables will override the new default
- **Backward Compatibility**: Users can still use kernel mode with `export FALCON_SENSOR_MODE=kernel`
- **GKE Autopilot**: No longer requires explicit `FALCON_SENSOR_MODE=bpf` setting (now default)

### 🧪 **Testing Status**
- ✅ **AKS**: Tested and working with user mode default
- ✅ **Environment Variable Handling**: Verified proper inheritance and overrides
- ✅ **Deployment Components**: All three components (Sensor, KAC, IAR) deploy successfully
- ✅ **Documentation**: Updated README.md with new defaults

### 🔗 **Repository State**
- **Script**: `quick-deploy.sh` - Main deployment automation
- **Documentation**: `README.md` - Comprehensive usage guide
- **Cleanup**: `uninstall-falcon.sh` - Complete cleanup utility
- **License**: MIT License

---

## Previous Versions

### [v1.1.x] - Format and parsing improvements
- Left-aligned sensor status output
- Enhanced falconctl parsing for comma-separated output
- Improved regex patterns for field extraction

### [v1.0.x] - Initial release
- Basic deployment automation
- Kernel mode default
- Multi-platform support