#!/bin/bash

# CrowdStrike Falcon Simple Deployment Script
# This script simplifies Falcon Platform deployment to just 3 environment variables
#
# Required Environment Variables:
# - FALCON_CLIENT_ID: Your Falcon OAuth Client ID
# - FALCON_CLIENT_SECRET: Your Falcon OAuth Client Secret
# - CLUSTERNAME: Your Kubernetes cluster name
#
# Usage:
#   export FALCON_CLIENT_ID="your-client-id"
#   export FALCON_CLIENT_SECRET="your-client-secret"
#   export CLUSTERNAME="your-cluster-name"
#   curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh | bash

set -e

# Component selection variables
INSTALL_SENSOR="true"
INSTALL_KAC="true"
INSTALL_IAR="true"
IS_GKE_AUTOPILOT="false"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🛡️  CrowdStrike Falcon Simple Deployment"
echo "========================================"
echo

# Check if running as root (not recommended)
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root is not recommended for this script"
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Interactive component selection
select_components() {
    # Check if running in a pipe (no TTY) or if environment variables are already set
    if [[ ! -t 0 ]] || [[ -n "$INSTALL_SENSOR" ]] || [[ -n "$INSTALL_KAC" ]] || [[ -n "$INSTALL_IAR" ]] || [[ -n "$IS_GKE_AUTOPILOT" ]]; then
        log_warning "Script is running in non-interactive mode."

        if [[ ! -t 0 ]]; then
            log_info "Detected piped execution. Using environment variables or defaults."
            log_info "To use interactive prompts, download and run the script directly:"
            log_info "  curl -sSL https://raw.githubusercontent.com/mikedzikowski/crowdstrike-deployment-simplifier/main/quick-deploy.sh -o quick-deploy.sh"
            log_info "  chmod +x quick-deploy.sh && ./quick-deploy.sh"
        else
            log_info "Environment variables detected. Using provided values."
        fi

        echo
        log_info "Available customization options:"
        log_info "  export INSTALL_SENSOR=false    # to disable Sensor"
        log_info "  export INSTALL_KAC=false       # to disable KAC"
        log_info "  export INSTALL_IAR=false       # to disable IAR"
        log_info "  export IS_GKE_AUTOPILOT=true   # to enable GKE Autopilot"
        echo

        # Use environment variables or defaults
        INSTALL_SENSOR=${INSTALL_SENSOR:-"true"}
        INSTALL_KAC=${INSTALL_KAC:-"true"}
        INSTALL_IAR=${INSTALL_IAR:-"true"}
        IS_GKE_AUTOPILOT=${IS_GKE_AUTOPILOT:-"false"}

        # Log final selections
        log_info "Final component selections:"
        [[ "$INSTALL_SENSOR" == "true" ]] && log_success "✅ Falcon Sensor will be installed" || log_warning "❌ Falcon Sensor disabled"
        [[ "$INSTALL_KAC" == "true" ]] && log_success "✅ Falcon KAC will be installed" || log_warning "❌ Falcon KAC disabled"
        [[ "$INSTALL_IAR" == "true" ]] && log_success "✅ Falcon Image Analyzer will be installed" || log_warning "❌ Falcon Image Analyzer disabled"
        [[ "$IS_GKE_AUTOPILOT" == "true" ]] && log_success "⚙️  GKE Autopilot mode enabled" || log_info "Standard Kubernetes mode"
        echo

        # Validate at least one component is selected
        if [[ "$INSTALL_SENSOR" == "false" && "$INSTALL_KAC" == "false" && "$INSTALL_IAR" == "false" ]]; then
            log_error "At least one component must be selected"
            exit 1
        fi

        return
    fi

    log_info "Component Selection"
    echo "==============================================="
    echo "Choose which CrowdStrike components to install:"
    echo

    # Sensor selection
    read -p "Install Falcon Sensor (Node Protection)? [Y/n]: " -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        INSTALL_SENSOR="false"
        log_warning "Falcon Sensor will NOT be installed"
    else
        log_success "Falcon Sensor will be installed"
    fi

    # KAC selection
    read -p "Install Falcon KAC (Kubernetes Admission Controller)? [Y/n]: " -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        INSTALL_KAC="false"
        log_warning "Falcon KAC will NOT be installed"
    else
        log_success "Falcon KAC will be installed"
    fi

    # IAR selection
    read -p "Install Falcon Image Analyzer (Container Scanning)? [Y/n]: " -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        INSTALL_IAR="false"
        log_warning "Falcon Image Analyzer will NOT be installed"
    else
        log_success "Falcon Image Analyzer will be installed"
    fi

    # GKE Autopilot detection
    echo
    read -p "Is this a GKE Autopilot cluster? [y/N]: " -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        IS_GKE_AUTOPILOT="true"
        log_success "GKE Autopilot mode enabled"
    fi

    # Validate at least one component is selected
    if [[ "$INSTALL_SENSOR" == "false" && "$INSTALL_KAC" == "false" && "$INSTALL_IAR" == "false" ]]; then
        log_error "At least one component must be selected"
        exit 1
    fi

    echo
}

# Validate required environment variables
validate_environment() {
    log_info "Validating environment variables..."

    local missing_vars=()

    if [[ -z "$FALCON_CLIENT_ID" ]]; then
        missing_vars+=("FALCON_CLIENT_ID")
    fi

    if [[ -z "$FALCON_CLIENT_SECRET" ]]; then
        missing_vars+=("FALCON_CLIENT_SECRET")
    fi

    if [[ -z "$CLUSTERNAME" ]]; then
        missing_vars+=("CLUSTERNAME")
    fi

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo
        echo "Please export the required variables first:"
        echo "  export FALCON_CLIENT_ID=\"your-falcon-oauth-client-id\""
        echo "  export FALCON_CLIENT_SECRET=\"your-falcon-oauth-client-secret\""
        echo "  export CLUSTERNAME=\"your-cluster-name\""
        echo
        echo "Then run this script again."
        exit 1
    fi

    log_success "All required environment variables are set"
    log_info "Using CLUSTERNAME: $CLUSTERNAME"
    log_info "Using FALCON_CLIENT_ID: ${FALCON_CLIENT_ID:0:8}..."
    echo
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if kubectl is installed and working
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        echo "Please install kubectl: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi

    # Check kubectl connectivity
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        echo "Please ensure kubectl is configured to connect to your cluster"
        exit 1
    fi

    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log_error "Helm is not installed or not in PATH"
        echo "Please install Helm 3.x: https://helm.sh/docs/intro/install/"
        exit 1
    fi

    # Check helm version (require 3.x)
    local helm_version=$(helm version --short --client 2>/dev/null | cut -d':' -f2 | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ "$helm_version" != "3" ]]; then
        log_error "Helm 3.x is required (found version: $(helm version --short --client 2>/dev/null))"
        exit 1
    fi

    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed or not in PATH"
        echo "Please install curl"
        exit 1
    fi

    log_success "All prerequisites are installed"
}

# Download CrowdStrike falcon-container-sensor-pull.sh script
download_falcon_script() {
    log_info "Downloading CrowdStrike falcon-container-sensor-pull.sh script..."

    if curl -sSL -o falcon-container-sensor-pull.sh "https://github.com/CrowdStrike/falcon-scripts/releases/latest/download/falcon-container-sensor-pull.sh"; then
        chmod +x falcon-container-sensor-pull.sh
        log_success "Downloaded and configured falcon-container-sensor-pull.sh"
    else
        log_error "Failed to download falcon-container-sensor-pull.sh"
        exit 1
    fi
}

# Get Falcon configuration using the official script
get_falcon_configuration() {
    log_info "Retrieving Falcon configuration..."

    # Step 1: Get Falcon CID
    log_info "Getting Falcon Customer ID (CID)..."
    if ! FALCON_CID=$(./falcon-container-sensor-pull.sh -t falcon-sensor --get-cid 2>/dev/null); then
        log_error "Failed to retrieve Falcon CID"
        echo "Please verify your FALCON_CLIENT_ID and FALCON_CLIENT_SECRET are correct"
        exit 1
    fi
    export FALCON_CID
    log_success "Retrieved Falcon CID: ${FALCON_CID:0:8}..."

    # Step 2: Get encoded Docker config pull token
    log_info "Getting Docker registry credentials..."
    if ! ENCODED_DOCKER_CONFIG=$(./falcon-container-sensor-pull.sh -t falcon-sensor --get-pull-token 2>/dev/null); then
        log_error "Failed to retrieve Docker registry credentials"
        exit 1
    fi
    export ENCODED_DOCKER_CONFIG
    log_success "Retrieved Docker registry credentials"

    # Step 3: Get Falcon Sensor image configuration (always fetch for potential use)
    log_info "Getting Falcon Sensor image information..."
    if ! FALCON_IMAGE_FULL_PATH=$(./falcon-container-sensor-pull.sh -t falcon-sensor --get-image-path 2>/dev/null); then
        log_error "Failed to retrieve Falcon Sensor image path"
        exit 1
    fi
    export SENSOR_REGISTRY=$(echo $FALCON_IMAGE_FULL_PATH | cut -d':' -f 1)
    export SENSOR_IMAGE_TAG=$(echo $FALCON_IMAGE_FULL_PATH | cut -d':' -f 2)
    log_success "Retrieved Falcon Sensor image: $SENSOR_REGISTRY:$SENSOR_IMAGE_TAG"

    # Step 4: Get Falcon KAC image configuration (always fetch for potential use)
    log_info "Getting Falcon KAC image information..."
    if ! FALCON_KAC_IMAGE_FULL_PATH=$(./falcon-container-sensor-pull.sh -t falcon-kac --get-image-path 2>/dev/null); then
        log_error "Failed to retrieve Falcon KAC image path"
        exit 1
    fi
    export KAC_REGISTRY=$(echo $FALCON_KAC_IMAGE_FULL_PATH | cut -d':' -f 1)
    export KAC_IMAGE_TAG=$(echo $FALCON_KAC_IMAGE_FULL_PATH | cut -d':' -f 2)
    log_success "Retrieved Falcon KAC image: $KAC_REGISTRY:$KAC_IMAGE_TAG"

    # Step 5: Get Falcon Image Analyzer configuration (always fetch for potential use)
    log_info "Getting Falcon Image Analyzer information..."
    if ! FALCON_IAR_IMAGE_FULL_PATH=$(./falcon-container-sensor-pull.sh -t falcon-imageanalyzer --get-image-path 2>/dev/null); then
        log_error "Failed to retrieve Falcon Image Analyzer image path"
        exit 1
    fi
    export IAR_REGISTRY=$(echo $FALCON_IAR_IMAGE_FULL_PATH | cut -d':' -f 1)
    export IAR_IMAGE_TAG=$(echo $FALCON_IAR_IMAGE_FULL_PATH | cut -d':' -f 2)
    log_success "Retrieved Falcon Image Analyzer image: $IAR_REGISTRY:$IAR_IMAGE_TAG"
}

# Display configuration summary
show_configuration() {
    echo
    log_info "Configuration Summary:"
    echo "=========================================="
    echo "FALCON_CID: $FALCON_CID"
    echo "ENCODED_DOCKER_CONFIG: ${ENCODED_DOCKER_CONFIG:0:50}..." # Show only first 50 chars
    echo ""

    echo "Selected Components:"
    if [[ "$INSTALL_SENSOR" == "true" ]]; then
        echo "  ✅ Falcon Sensor - Image: $SENSOR_REGISTRY:$SENSOR_IMAGE_TAG"
    else
        echo "  ❌ Falcon Sensor (disabled)"
    fi

    if [[ "$INSTALL_KAC" == "true" ]]; then
        echo "  ✅ Falcon KAC - Image: $KAC_REGISTRY:$KAC_IMAGE_TAG"
    else
        echo "  ❌ Falcon KAC (disabled)"
    fi

    if [[ "$INSTALL_IAR" == "true" ]]; then
        echo "  ✅ Falcon Image Analyzer - Image: $IAR_REGISTRY:$IAR_IMAGE_TAG"
    else
        echo "  ❌ Falcon Image Analyzer (disabled)"
    fi

    echo ""
    echo "Cluster Configuration:"
    echo "  - Name: $CLUSTERNAME"
    if [[ "$IS_GKE_AUTOPILOT" == "true" ]]; then
        echo "  - Type: GKE Autopilot ⚙️"
    else
        echo "  - Type: Standard Kubernetes"
    fi
    echo "=========================================="
}

# Add Helm repository
add_helm_repo() {
    log_info "Adding CrowdStrike Helm repository..."

    helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm 2>/dev/null || {
        log_info "Repository already exists, updating..."
    }

    helm repo update
    log_success "Helm repository added and updated"
}

# Configure GKE Autopilot if needed
configure_gke_autopilot() {
    if [[ "$IS_GKE_AUTOPILOT" == "true" ]]; then
        log_info "Configuring GKE Autopilot AllowlistSynchronizer..."

        # Create AllowlistSynchronizer YAML
        cat > allowlist-synchronizer.yaml << EOF
apiVersion: auto.gke.io/v1
kind: AllowlistSynchronizer
metadata:
  name: crowdstrike-synchronizer
spec:
  allowlistPaths:
  - CrowdStrike/falcon-sensor/*
EOF

        # Apply AllowlistSynchronizer
        if kubectl apply -f allowlist-synchronizer.yaml; then
            log_success "AllowlistSynchronizer created successfully"

            # Wait for it to be ready
            log_info "Waiting for AllowlistSynchronizer to be ready..."
            sleep 5

            # Verify AllowlistSynchronizer
            if kubectl get allowlistsynchronizers crowdstrike-synchronizer &>/dev/null; then
                log_success "AllowlistSynchronizer is running"

                # Check WorkloadAllowlists
                if kubectl get workloadallowlists &>/dev/null; then
                    log_success "WorkloadAllowlists have been fetched"
                else
                    log_warning "WorkloadAllowlists may still be loading"
                fi
            else
                log_error "AllowlistSynchronizer failed to start"
                exit 1
            fi
        else
            log_error "Failed to create AllowlistSynchronizer"
            exit 1
        fi

        # Clean up temp file
        rm -f allowlist-synchronizer.yaml
    fi
}

# Deploy Falcon Platform
deploy_falcon() {
    log_info "Deploying Falcon Platform..."

    # Build base Helm command
    local helm_cmd="helm install falcon-platform crowdstrike/falcon-platform --version 1.2.0 \
        --namespace falcon-platform \
        --create-namespace \
        --set createComponentNamespaces=true \
        --set global.falcon.cid=$FALCON_CID \
        --set global.containerRegistry.configJSON=$ENCODED_DOCKER_CONFIG"

    # Add Falcon Sensor settings if enabled
    if [[ "$INSTALL_SENSOR" == "true" ]]; then
        helm_cmd="$helm_cmd \
        --set falcon-sensor.enabled=true \
        --set falcon-sensor.node.image.repository=$SENSOR_REGISTRY \
        --set falcon-sensor.node.image.tag=$SENSOR_IMAGE_TAG"

        # Add GKE Autopilot settings if needed
        if [[ "$IS_GKE_AUTOPILOT" == "true" ]]; then
            helm_cmd="$helm_cmd \
            --set falcon-sensor.node.gke.autopilot=true"
        fi
    else
        helm_cmd="$helm_cmd --set falcon-sensor.enabled=false"
    fi

    # Add Falcon KAC settings if enabled
    if [[ "$INSTALL_KAC" == "true" ]]; then
        helm_cmd="$helm_cmd \
        --set falcon-kac.enabled=true \
        --set falcon-kac.image.repository=$KAC_REGISTRY \
        --set falcon-kac.image.tag=$KAC_IMAGE_TAG"
    else
        helm_cmd="$helm_cmd --set falcon-kac.enabled=false"
    fi

    # Add Falcon Image Analyzer settings if enabled
    if [[ "$INSTALL_IAR" == "true" ]]; then
        helm_cmd="$helm_cmd \
        --set falcon-image-analyzer.deployment.enabled=true \
        --set falcon-image-analyzer.image.repository=$IAR_REGISTRY \
        --set falcon-image-analyzer.image.tag=$IAR_IMAGE_TAG \
        --set falcon-image-analyzer.crowdstrikeConfig.clusterName=$CLUSTERNAME \
        --set falcon-image-analyzer.crowdstrikeConfig.clientID=$FALCON_CLIENT_ID \
        --set falcon-image-analyzer.crowdstrikeConfig.clientSecret=$FALCON_CLIENT_SECRET"
    else
        helm_cmd="$helm_cmd --set falcon-image-analyzer.deployment.enabled=false"
    fi

    # Execute the deployment command
    if eval $helm_cmd; then
        log_success "Falcon Platform deployed successfully!"
    else
        log_error "Failed to deploy Falcon Platform"
        exit 1
    fi
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."

    # Wait for pods to be ready
    log_info "Waiting for pods to be ready (this may take several minutes)..."
    sleep 10

    # Show deployment status
    echo
    log_info "Deployment Status:"
    echo "==================="

    # Show helm release
    helm list -n falcon-platform
    echo

    # Show pods across all falcon namespaces
    echo "Falcon Pods:"
    kubectl get pods -A | grep falcon || echo "No falcon pods found yet"

    log_success "Initial verification complete!"
    echo
    log_info "Note: Pods may take several minutes to fully start and become ready"
}

# Print success message and next steps
print_success() {
    echo
    log_success "🎉 CrowdStrike Falcon Platform has been successfully deployed!"
    echo
    echo "Components deployed:"
    if [[ "$INSTALL_SENSOR" == "true" ]]; then
        echo "  ✅ Falcon Sensor (Node protection)"
    fi
    if [[ "$INSTALL_KAC" == "true" ]]; then
        echo "  ✅ Falcon Kubernetes Admission Controller (Policy enforcement)"
    fi
    if [[ "$INSTALL_IAR" == "true" ]]; then
        echo "  ✅ Falcon Image Analyzer (Container image scanning)"
    fi

    if [[ "$IS_GKE_AUTOPILOT" == "true" ]]; then
        echo "  ⚙️  GKE Autopilot AllowlistSynchronizer configured"
    fi

    echo
    echo "Next steps:"
    echo "  1. Monitor the deployment: kubectl get pods -A | grep falcon"
    echo "  2. Check logs if needed: kubectl logs -n <namespace> <pod-name>"
    echo "  3. View in Falcon Console: https://falcon.crowdstrike.com"
    echo
    echo "For troubleshooting, visit: https://github.com/CrowdStrike/falcon-helm"
}

# Cleanup function
cleanup() {
    if [[ -f "falcon-container-sensor-pull.sh" ]]; then
        rm -f falcon-container-sensor-pull.sh
        log_info "Cleaned up temporary files"
    fi
}

# Main execution
main() {
    # Set trap for cleanup
    trap cleanup EXIT

    check_root
    select_components
    validate_environment
    check_prerequisites
    download_falcon_script
    get_falcon_configuration
    show_configuration
    add_helm_repo
    configure_gke_autopilot
    deploy_falcon
    verify_deployment
    print_success
}

# Trap errors and cleanup
trap 'log_error "Script failed at line $LINENO"; cleanup' ERR

# Run main function
main "$@"