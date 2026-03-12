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

# Component selection variables (can be overridden by environment variables)
# These are used as defaults if environment variables are not set

# Verbose mode (can be enabled with VERBOSE=true environment variable)
VERBOSE=${VERBOSE:-"false"}

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

# Clean logging functions without prefixes
clean_info() { echo -e "${BLUE}$1${NC}"; }
clean_success() { echo -e "${GREEN}$1${NC}"; }
clean_warning() { echo -e "${YELLOW}$1${NC}"; }
clean_error() { echo -e "${RED}$1${NC}"; }

# Progress indicator function
show_progress() {
    local message="$1"
    local duration=${2:-30}
    local interval=2
    local elapsed=0

    echo -ne "${BLUE}[INFO]${NC} $message"

    while [[ $elapsed -lt $duration ]]; do
        echo -ne "."
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    echo " ✓"
}

# Add visual separator function
print_separator() {
    echo "────────────────────────────────────────────────────────────────"
}

# Add section header function
print_section() {
    local title="$1"
    echo
    print_separator
    echo "🔧 $title"
    print_separator
    echo
}

echo
echo "🛡️  CrowdStrike Falcon Simple Deployment"
print_separator
echo

# Check if running as root (not recommended)
check_root() {
    if [[ $EUID -eq 0 ]]; then
        clean_warning "Running as root is not recommended for this script"
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Component selection using environment variables
select_components() {
    print_section "COMPONENT CONFIGURATION"

    # Read environment variables or use defaults
    INSTALL_SENSOR="${INSTALL_SENSOR:-true}"
    INSTALL_KAC="${INSTALL_KAC:-true}"
    INSTALL_IAR="${INSTALL_IAR:-true}"
    IS_GKE_AUTOPILOT="${IS_GKE_AUTOPILOT:-false}"

    # Log selections with better formatting
    clean_info "Selected components:"
    [[ "$INSTALL_SENSOR" == "true" ]] && clean_success "✅ Falcon Sensor" || clean_warning "❌ Falcon Sensor"
    [[ "$INSTALL_KAC" == "true" ]] && clean_success "✅ Falcon KAC" || clean_warning "❌ Falcon KAC"
    [[ "$INSTALL_IAR" == "true" ]] && clean_success "✅ Falcon Image Analyzer" || clean_warning "❌ Falcon Image Analyzer"

    echo
    clean_info "Cluster type:"
    [[ "$IS_GKE_AUTOPILOT" == "true" ]] && clean_success "⚙️  GKE Autopilot" || clean_info "🖥️  Standard Kubernetes"

    # Validate at least one component is selected
    if [[ "$INSTALL_SENSOR" == "false" && "$INSTALL_KAC" == "false" && "$INSTALL_IAR" == "false" ]]; then
        echo
        clean_error "At least one component must be selected"
        exit 1
    fi
}

# Validate required environment variables
validate_environment() {
    print_section "ENVIRONMENT VALIDATION"

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
        clean_error "Missing required variables:"
        for var in "${missing_vars[@]}"; do
            echo "• $var"
        done
        echo
        echo "Set the required variables:"
        echo "export FALCON_CLIENT_ID=\"your-client-id\""
        echo "export FALCON_CLIENT_SECRET=\"your-client-secret\""
        echo "export CLUSTERNAME=\"your-cluster-name\""
        exit 1
    fi

    clean_success "Environment variables validated"
    clean_info "Cluster: $CLUSTERNAME"
    clean_info "Client ID: ${FALCON_CLIENT_ID:0:8}..."
}

# Auto-install Helm if not found
install_helm() {
    clean_info "Helm not found. Installing Helm automatically..."

    # Download the Helm installer script
    local helm_script="get_helm.sh"
    if curl -fsSL -o "$helm_script" https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4; then
        chmod 700 "$helm_script"

        if ./"$helm_script"; then
            # Clean up the installer script
            rm -f "$helm_script"

            clean_success "Helm installed successfully"
            clean_info "Location: $(which helm)"
            clean_info "Version: $(helm version --short 2>/dev/null || helm version | head -n1)"
        else
            clean_error "Failed to install Helm using installer script"
            rm -f "$helm_script"
            clean_info "Please install Helm manually:"
            clean_info "  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4"
            clean_info "  chmod 700 get_helm.sh"
            clean_info "  ./get_helm.sh"
            exit 1
        fi
    else
        clean_error "Failed to download Helm installer script"
        clean_info "Please install Helm manually:"
        clean_info "  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4"
        clean_info "  chmod 700 get_helm.sh"
        clean_info "  ./get_helm.sh"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    print_section "PREREQUISITES CHECK"

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        clean_error "kubectl not found"
        echo "Install: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi

    if ! kubectl cluster-info &> /dev/null; then
        clean_error "Cannot connect to Kubernetes cluster"
        echo "Configure kubectl to connect to your cluster"
        exit 1
    fi

    # Check helm (with auto-install)
    if ! command -v helm &> /dev/null; then
        install_helm
    fi

    # Check helm version (support Helm 3.x and 4.x with backwards compatibility)
    local helm_version_output=""
    local helm_version=""
    local major_version=""

    # Try modern helm version command first (works with both 3.x and 4.x)
    helm_version_output=$(helm version 2>/dev/null | head -n1 || echo "")

    if [[ -n "$helm_version_output" ]]; then
        # Try to extract version using regex for BuildInfo format
        # Handle both full versions (v3.18.0) and truncated versions (v3.18)
        if [[ "$helm_version_output" =~ Version:\"v([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
            major_version="${BASH_REMATCH[1]}"
            helm_version="v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
        elif [[ "$helm_version_output" =~ Version:\"v([0-9]+)\.([0-9]+)\" ]]; then
            # Handle truncated versions like "v3.18"
            major_version="${BASH_REMATCH[1]}"
            helm_version="v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
        fi
    fi

    # Fallback: Try legacy helm version command for older Helm 3.x installations
    if [[ -z "$helm_version" ]]; then
        local legacy_output=$(helm version --short --client 2>/dev/null || echo "")
        if [[ -n "$legacy_output" ]]; then
            # Legacy format: "v3.12.3+g3a31588" or "Client: v3.12.3+g3a31588" or "v3.18"
            if [[ "$legacy_output" =~ v([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
                major_version="${BASH_REMATCH[1]}"
                helm_version="v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
            elif [[ "$legacy_output" =~ v([0-9]+)\.([0-9]+) ]]; then
                # Handle truncated versions
                major_version="${BASH_REMATCH[1]}"
                helm_version="v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
            fi
        fi
    fi

    # Final fallback: Try basic version parsing
    if [[ -z "$helm_version" ]]; then
        local basic_output=$(helm version --short 2>/dev/null || helm version -c 2>/dev/null || echo "")
        if [[ -n "$basic_output" ]]; then
            if [[ "$basic_output" =~ v([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
                major_version="${BASH_REMATCH[1]}"
                helm_version="v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
            elif [[ "$basic_output" =~ v([0-9]+)\.([0-9]+) ]]; then
                # Handle truncated versions
                major_version="${BASH_REMATCH[1]}"
                helm_version="v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
            fi
        fi
    fi

    # Validate we got a version
    if [[ -z "$helm_version" || -z "$major_version" ]]; then
        clean_error "Unable to detect Helm version"
        echo "Helm command output was: '$helm_version_output'"
        echo "Please ensure Helm is properly installed: https://helm.sh/docs/intro/install/"
        exit 1
    fi

    # Check for supported versions (3.x or 4.x)
    if [[ "$major_version" != "3" && "$major_version" != "4" ]]; then
        clean_error "Helm 3.x or 4.x required (found: $helm_version)"
        echo "Install or upgrade Helm: https://helm.sh/docs/intro/install/"
        exit 1
    fi

    # Check curl
    if ! command -v curl &> /dev/null; then
        clean_error "curl not found"
        exit 1
    fi

    clean_success "All prerequisites verified"
    clean_info "✓ kubectl connected to cluster"
    clean_info "✓ Helm $helm_version available"
    clean_info "✓ curl available"
}

# Download CrowdStrike falcon-container-sensor-pull.sh script
download_falcon_script() {
    print_section "FALCON SCRIPT DOWNLOAD"

    if curl -sSL -o falcon-container-sensor-pull.sh "https://github.com/CrowdStrike/falcon-scripts/releases/latest/download/falcon-container-sensor-pull.sh"; then
        chmod +x falcon-container-sensor-pull.sh
        clean_success "Official CrowdStrike script downloaded"
    else
        clean_error "Failed to download falcon-container-sensor-pull.sh"
        exit 1
    fi
}

# Get Falcon configuration using the official script
get_falcon_configuration() {
    print_section "FALCON CONFIGURATION"

    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "Retrieving Falcon API configuration..."
        clean_info "Using Client ID: ${FALCON_CLIENT_ID:0:8}..."
        clean_info "Detecting Falcon cloud region..."
    fi

    # Step 1: Get Falcon CID
    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "Fetching Customer ID (CID)..."
    fi
    if ! FALCON_CID=$(./falcon-container-sensor-pull.sh -t falcon-sensor --get-cid 2>/dev/null); then
        clean_error "Failed to retrieve Falcon CID"
        echo "Verify FALCON_CLIENT_ID and FALCON_CLIENT_SECRET are correct"
        [[ "$VERBOSE" == "true" ]] && echo "API Error: Authentication may have failed"
        exit 1
    fi
    export FALCON_CID
    [[ "$VERBOSE" == "true" ]] && clean_success "Customer ID: ${FALCON_CID:0:20}..."

    # Step 2: Get encoded Docker config pull token
    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "Generating container registry credentials..."
    fi
    if ! ENCODED_DOCKER_CONFIG=$(./falcon-container-sensor-pull.sh -t falcon-sensor --get-pull-token 2>/dev/null); then
        clean_error "Failed to retrieve Docker registry credentials"
        [[ "$VERBOSE" == "true" ]] && echo "API Error: Registry token generation failed"
        exit 1
    fi
    export ENCODED_DOCKER_CONFIG
    [[ "$VERBOSE" == "true" ]] && clean_success "Registry credentials generated (${#ENCODED_DOCKER_CONFIG} chars)"

    # Step 3: Get Falcon Sensor image configuration
    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "Retrieving Falcon Sensor image information..."
    fi
    if ! FALCON_IMAGE_FULL_PATH=$(./falcon-container-sensor-pull.sh -t falcon-sensor --get-image-path 2>/dev/null); then
        clean_error "Failed to retrieve Falcon Sensor image path"
        [[ "$VERBOSE" == "true" ]] && echo "API Error: Sensor image metadata unavailable"
        exit 1
    fi
    export SENSOR_REGISTRY=$(echo $FALCON_IMAGE_FULL_PATH | cut -d':' -f 1)
    export SENSOR_IMAGE_TAG=$(echo $FALCON_IMAGE_FULL_PATH | cut -d':' -f 2)
    [[ "$VERBOSE" == "true" ]] && clean_success "Sensor Image: $SENSOR_REGISTRY:$SENSOR_IMAGE_TAG"

    # Step 4: Get Falcon KAC image configuration
    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "Retrieving Falcon KAC image information..."
    fi
    if ! FALCON_KAC_IMAGE_FULL_PATH=$(./falcon-container-sensor-pull.sh -t falcon-kac --get-image-path 2>/dev/null); then
        clean_error "Failed to retrieve Falcon KAC image path"
        [[ "$VERBOSE" == "true" ]] && echo "API Error: KAC image metadata unavailable"
        exit 1
    fi
    export KAC_REGISTRY=$(echo $FALCON_KAC_IMAGE_FULL_PATH | cut -d':' -f 1)
    export KAC_IMAGE_TAG=$(echo $FALCON_KAC_IMAGE_FULL_PATH | cut -d':' -f 2)
    [[ "$VERBOSE" == "true" ]] && clean_success "KAC Image: $KAC_REGISTRY:$KAC_IMAGE_TAG"

    # Step 5: Get Falcon Image Analyzer configuration
    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "Retrieving Falcon Image Analyzer information..."
    fi
    if ! FALCON_IAR_IMAGE_FULL_PATH=$(./falcon-container-sensor-pull.sh -t falcon-imageanalyzer --get-image-path 2>/dev/null); then
        clean_error "Failed to retrieve Falcon Image Analyzer image path"
        [[ "$VERBOSE" == "true" ]] && echo "API Error: Image Analyzer metadata unavailable"
        exit 1
    fi
    export IAR_REGISTRY=$(echo $FALCON_IAR_IMAGE_FULL_PATH | cut -d':' -f 1)
    export IAR_IMAGE_TAG=$(echo $FALCON_IAR_IMAGE_FULL_PATH | cut -d':' -f 2)
    [[ "$VERBOSE" == "true" ]] && clean_success "IAR Image: $IAR_REGISTRY:$IAR_IMAGE_TAG"

    clean_success "Falcon configuration retrieved"
    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "✓ Customer ID acquired"
        clean_info "✓ Registry access configured"
        clean_info "✓ All component images resolved"
    fi
}

# Display configuration summary
show_configuration() {
    print_section "DEPLOYMENT CONFIGURATION"

    clean_info "Customer configuration:"
    echo "CID: $FALCON_CID"
    echo "Cluster: $CLUSTERNAME"
    if [[ "$VERBOSE" == "true" ]]; then
        echo "Registry token: ${#ENCODED_DOCKER_CONFIG} characters"
        echo "Client ID: ${FALCON_CLIENT_ID:0:12}..."
    fi

    echo
    clean_info "Selected components:"
    if [[ "$INSTALL_SENSOR" == "true" ]]; then
        clean_success "✅ Falcon Sensor"
        [[ "$VERBOSE" == "true" ]] && echo "Image: $SENSOR_REGISTRY:$SENSOR_IMAGE_TAG"
    else
        clean_warning "❌ Falcon Sensor (disabled)"
    fi

    if [[ "$INSTALL_KAC" == "true" ]]; then
        clean_success "✅ Falcon KAC"
        [[ "$VERBOSE" == "true" ]] && echo "Image: $KAC_REGISTRY:$KAC_IMAGE_TAG"
    else
        clean_warning "❌ Falcon KAC (disabled)"
    fi

    if [[ "$INSTALL_IAR" == "true" ]]; then
        clean_success "✅ Falcon Image Analyzer"
        [[ "$VERBOSE" == "true" ]] && echo "Image: $IAR_REGISTRY:$IAR_IMAGE_TAG"
    else
        clean_warning "❌ Falcon Image Analyzer (disabled)"
    fi

    echo
    clean_info "Cluster configuration:"
    if [[ "$IS_GKE_AUTOPILOT" == "true" ]]; then
        clean_success "⚙️  GKE Autopilot mode"
    else
        clean_info "🖥️  Standard Kubernetes"
    fi
}

# Add Helm repository
add_helm_repo() {
    print_section "HELM REPOSITORY"

    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "Adding CrowdStrike Helm repository..."
        helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm 2>/dev/null || {
            clean_info "Repository already exists, updating..."
        }
        clean_info "Updating Helm repositories..."
        helm repo update
        clean_success "Helm repository configured"
        helm repo list | grep crowdstrike
    else
        helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm >/dev/null 2>&1 || {
            clean_info "Repository already exists, updating..."
        }
        helm repo update >/dev/null 2>&1
        clean_success "Helm repository configured"
    fi
}

# Configure GKE Autopilot if needed
configure_gke_autopilot() {
    if [[ "$IS_GKE_AUTOPILOT" == "true" ]]; then
        print_section "GKE AUTOPILOT CONFIGURATION"
        clean_info "Configuring GKE Autopilot AllowlistSynchronizer..."

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
        if kubectl apply -f allowlist-synchronizer.yaml >/dev/null 2>&1; then
            clean_success "AllowlistSynchronizer created successfully"

            # Wait for it to be ready
            clean_info "Waiting for AllowlistSynchronizer to be ready..."
            sleep 5

            # Verify AllowlistSynchronizer
            if kubectl get allowlistsynchronizers crowdstrike-synchronizer >/dev/null 2>&1; then
                if kubectl get workloadallowlists >/dev/null 2>&1; then
                    clean_success "GKE Autopilot configuration complete"
                else
                    clean_warning "WorkloadAllowlists may still be loading"
                fi
            else
                clean_error "AllowlistSynchronizer failed to start"
                exit 1
            fi
        else
            clean_error "Failed to create AllowlistSynchronizer"
            exit 1
        fi

        # Clean up temp file
        rm -f allowlist-synchronizer.yaml
    fi
}

# Check for conflicting resources that could block deployment
check_conflicting_resources() {
    clean_info "Checking for conflicting resources..."

    # Check for conflicting ValidatingWebhookConfigurations
    local conflicting_webhooks=$(kubectl get validatingwebhookconfigurations -o jsonpath='{.items[?(@.metadata.name=="validating.falcon-kac.crowdstrike.com")].metadata.name}' 2>/dev/null || echo "")

    if [[ -n "$conflicting_webhooks" ]]; then
        clean_warning "Found conflicting webhook configuration: $conflicting_webhooks"
        clean_info "This is from a previous Falcon KAC installation"
        clean_info "Removing conflicting webhook..."

        kubectl delete validatingwebhookconfigurations validating.falcon-kac.crowdstrike.com --ignore-not-found 2>/dev/null || true

        # Wait a moment for deletion to complete
        sleep 2

        # Verify removal
        if kubectl get validatingwebhookconfigurations validating.falcon-kac.crowdstrike.com 2>/dev/null; then
            clean_error "Failed to remove conflicting webhook configuration"
            clean_info "Please run cleanup first: ./quick-deploy.sh cleanup"
            exit 1
        else
            clean_success "Conflicting webhook removed successfully"
        fi
    fi
}

# Deploy Falcon Platform
deploy_falcon() {
    print_section "FALCON PLATFORM DEPLOYMENT"

    # Check for and resolve conflicting resources first
    check_conflicting_resources

    # Check if ANY Falcon release already exists (comprehensive detection)
    local existing_release=""
    local release_namespace=""
    local helm_operation="install"
    local target_namespace="falcon-platform"

    # Search for ANY Falcon-related releases across ALL namespaces
    local falcon_releases=$(helm list -A -o json 2>/dev/null | jq -r '.[] | select(.name | test("falcon")) | "\(.name) \(.namespace)"' 2>/dev/null || echo "")

    # Fallback if jq not available - search with grep
    if [[ -z "$falcon_releases" ]]; then
        falcon_releases=$(helm list -A 2>/dev/null | grep -E "(falcon-platform|falcon-kac|falcon-sensor|falcon-helm|falcon-image-analyzer)" || echo "")
    fi

    if [[ -n "$falcon_releases" ]]; then
        # Check if there's a falcon-platform release (umbrella chart)
        local platform_release=$(echo "$falcon_releases" | grep "falcon-platform" | head -n1)

        if [[ -n "$platform_release" ]]; then
            # Found falcon-platform release - we can upgrade it
            existing_release=$(echo "$platform_release" | awk '{print $1}')
            release_namespace=$(echo "$platform_release" | awk '{print $2}')

            clean_info "Found existing falcon-platform release:"
            clean_info "  Release: $existing_release"
            clean_info "  Namespace: $release_namespace"
            clean_info "Proceeding with upgrade instead of fresh install"

            helm_operation="upgrade"
            target_namespace="$release_namespace"
        else
            # Found other Falcon releases (individual components) - require cleanup
            clean_warning "Found existing Falcon component releases that conflict:"
            echo "$falcon_releases" | while read -r line; do
                if [[ -n "$line" ]]; then
                    clean_info "  - $line"
                fi
            done
            clean_warning "Cannot install falcon-platform umbrella chart alongside individual component releases"
            clean_info ""
            clean_info "SOLUTION: Run cleanup first to remove existing component installations:"
            clean_info "  ./quick-deploy.sh cleanup"
            clean_info ""
            clean_info "This will allow a fresh falcon-platform deployment that manages all components."
            exit 1
        fi
    else
        clean_info "No existing Falcon releases found"
        clean_info "Proceeding with fresh installation"
    fi

    # Show current deployment state if upgrading
    if [[ "$helm_operation" == "upgrade" ]]; then
        # Detect currently deployed components by checking for actual running pods
        local existing_sensor=$(kubectl get pods -n falcon-system -l app.kubernetes.io/name=falcon-sensor >/dev/null 2>&1 && echo "true" || echo "false")
        local existing_kac=$(kubectl get pods -n falcon-kac -l app.kubernetes.io/name=falcon-kac >/dev/null 2>&1 && echo "true" || echo "false")
        local existing_iar=$(kubectl get pods -n falcon-image-analyzer -l app.kubernetes.io/name=falcon-image-analyzer >/dev/null 2>&1 && echo "true" || echo "false")

        clean_info "Current deployment state:"
        [[ "$existing_sensor" == "true" ]] && clean_info "Falcon Sensor: Currently deployed" || clean_info "Falcon Sensor: Not deployed"
        [[ "$existing_kac" == "true" ]] && clean_info "Falcon KAC: Currently deployed" || clean_info "Falcon KAC: Not deployed"
        [[ "$existing_iar" == "true" ]] && clean_info "Falcon IAR: Currently deployed" || clean_info "Falcon IAR: Not deployed"
    fi

    # Create component namespaces for NEW components being enabled (if namespaces don't exist)
    if [[ "$INSTALL_SENSOR" == "true" ]]; then
        if ! kubectl get namespace falcon-system >/dev/null 2>&1; then
            clean_info "Creating falcon-system namespace for Sensor deployment..."
            kubectl create namespace falcon-system
        fi
    fi
    if [[ "$INSTALL_KAC" == "true" ]]; then
        if ! kubectl get namespace falcon-kac >/dev/null 2>&1; then
            clean_info "Creating falcon-kac namespace for KAC deployment..."
            kubectl create namespace falcon-kac
        fi
    fi
    if [[ "$INSTALL_IAR" == "true" ]]; then
        if ! kubectl get namespace falcon-image-analyzer >/dev/null 2>&1; then
            clean_info "Creating falcon-image-analyzer namespace for IAR deployment..."
            kubectl create namespace falcon-image-analyzer
        fi
    fi

    # Build helm command based on operation type
    local helm_cmd=""
    if [[ "$helm_operation" == "upgrade" ]]; then
        helm_cmd="helm upgrade --install falcon-platform crowdstrike/falcon-platform --version 1.2.0 \
            --namespace \"$target_namespace\" \
            --set global.falcon.cid=\"$FALCON_CID\" \
            --set global.containerRegistry.configJSON=\"$ENCODED_DOCKER_CONFIG\""
    else
        helm_cmd="helm install falcon-platform crowdstrike/falcon-platform --version 1.2.0 \
            --namespace \"$target_namespace\" \
            --create-namespace \
            --set createComponentNamespaces=true \
            --set global.falcon.cid=\"$FALCON_CID\" \
            --set global.containerRegistry.configJSON=\"$ENCODED_DOCKER_CONFIG\""
    fi

    # Add Falcon Sensor settings if enabled
    if [[ "$INSTALL_SENSOR" == "true" ]]; then
        helm_cmd="$helm_cmd \
        --set falcon-sensor.enabled=true \
        --set falcon-sensor.node.image.repository=\"$SENSOR_REGISTRY\" \
        --set falcon-sensor.node.image.tag=\"$SENSOR_IMAGE_TAG\""

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
        --set falcon-kac.image.repository=\"$KAC_REGISTRY\" \
        --set falcon-kac.image.tag=\"$KAC_IMAGE_TAG\""
    else
        helm_cmd="$helm_cmd --set falcon-kac.enabled=false"
    fi

    # Add Falcon Image Analyzer settings if enabled
    if [[ "$INSTALL_IAR" == "true" ]]; then
        helm_cmd="$helm_cmd \
        --set falcon-image-analyzer.deployment.enabled=true \
        --set falcon-image-analyzer.image.repository=\"$IAR_REGISTRY\" \
        --set falcon-image-analyzer.image.tag=\"$IAR_IMAGE_TAG\" \
        --set falcon-image-analyzer.crowdstrikeConfig.clusterName=\"$CLUSTERNAME\" \
        --set falcon-image-analyzer.crowdstrikeConfig.clientID=\"$FALCON_CLIENT_ID\" \
        --set falcon-image-analyzer.crowdstrikeConfig.clientSecret=\"$FALCON_CLIENT_SECRET\""
    else
        helm_cmd="$helm_cmd --set falcon-image-analyzer.enabled=false"
    fi

    # Execute the deployment command with conditional verbosity and progress indication
    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "Executing helm command:"
        echo "$helm_cmd"
        echo
        if eval $helm_cmd; then
            if [[ "$helm_operation" == "upgrade" ]]; then
                clean_success "Falcon Platform upgraded successfully!"
            else
                clean_success "Falcon Platform deployed successfully!"
            fi
        else
            clean_error "Failed to deploy Falcon Platform"
            exit 1
        fi
    else
        # Run deployment in background and show progress
        eval $helm_cmd >/dev/null 2>&1 &
        local deploy_pid=$!

        # Show progress while deployment is running
        echo -ne "${BLUE}[INFO]${NC} Deployment in progress"
        local dots=0
        while kill -0 $deploy_pid 2>/dev/null; do
            echo -ne "."
            sleep 2
            dots=$((dots + 1))
            # Show encouraging messages every 10 dots (20 seconds)
            if [[ $((dots % 10)) -eq 0 ]]; then
                case $((dots / 10)) in
                    1) echo -ne " [Creating namespaces]" ;;
                    2) echo -ne " [Pulling container images]" ;;
                    3) echo -ne " [Starting pods]" ;;
                    *) echo -ne " [Finalizing deployment]" ;;
                esac
            fi
        done

        # Check deployment result
        if wait $deploy_pid; then
            echo " ✓"
            if [[ "$helm_operation" == "upgrade" ]]; then
                clean_success "Falcon Platform upgraded successfully!"
            else
                clean_success "Falcon Platform deployed successfully!"
            fi
        else
            echo " ✗"
            clean_error "Failed to deploy Falcon Platform"
            clean_info "Re-running deployment with verbose output for troubleshooting..."
            eval $helm_cmd
            exit 1
        fi
    fi
}

# Verify deployment
verify_deployment() {
    clean_info "Verifying deployment..."

    # Wait for pods to be ready with progress indicator (10 seconds total)
    echo -ne "${BLUE}[INFO]${NC} Waiting for pods to start"
    for i in {1..10}; do
        echo -ne "."
        sleep 1
    done
    echo " ✓"

    # Show deployment status
    echo
    clean_info "Deployment Status:"
    echo "==================="

    # Show helm release using the correct namespace
    helm list -n ${target_namespace:-falcon-platform}
    echo

    # Show pods across all falcon namespaces
    echo "Falcon Pods:"
    kubectl get pods -A | grep falcon || echo "No falcon pods found yet"

    clean_success "Initial verification complete!"
    echo
    clean_info "Note: Pods may take several minutes to fully start and become ready"
}

# Print success message and next steps
print_success() {
    echo
    clean_success "🎉 CrowdStrike Falcon Platform has been successfully deployed!"
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

# Cleanup function for stuck deployments
cleanup_deployment() {
    clean_info "🧹 Cleaning up existing Falcon deployment..."

    # Find and remove ALL falcon-related releases in ANY namespace
    clean_info "Searching for all Falcon-related releases across all namespaces..."
    local releases_found=false

    # Get all releases and filter for any falcon-related ones
    while IFS= read -r release_line; do
        if [[ -n "$release_line" && ("$release_line" == *"falcon-platform"* || "$release_line" == *"falcon-kac"* || "$release_line" == *"falcon-sensor"* || "$release_line" == *"falcon-helm"* || "$release_line" == *"falcon-image-analyzer"*) ]]; then
            releases_found=true
            local release_name=$(echo "$release_line" | awk '{print $1}')
            local release_ns=$(echo "$release_line" | awk '{print $2}')

            clean_info "Removing release '$release_name' from namespace '$release_ns'..."
            helm uninstall "$release_name" -n "$release_ns" --ignore-not-found || {
                clean_warning "Failed to remove release $release_name from $release_ns"
            }
        fi
    done < <(helm list -A 2>/dev/null || echo "")

    if [[ "$releases_found" == "false" ]]; then
        clean_info "No Falcon-related releases found"
    fi

    # Remove namespaces with timeout
    clean_info "Removing Falcon namespaces..."
    kubectl delete namespace falcon-platform falcon-system falcon-kac falcon-image-analyzer --ignore-not-found --timeout=60s 2>/dev/null || {
        clean_warning "Some namespaces may take longer to delete (stuck finalizers)"
    }

    # Remove ValidatingWebhookConfigurations (multiple methods for thoroughness)
    clean_info "Removing webhook configurations..."

    # Method 1: Remove by label
    kubectl delete validatingwebhookconfigurations -l app.kubernetes.io/instance=falcon-platform --ignore-not-found 2>/dev/null || true

    # Method 2: Remove by name patterns (covers individual component installs)
    kubectl delete validatingwebhookconfigurations \
        validating.falcon-kac.crowdstrike.com \
        falcon-kac-validating-webhook \
        --ignore-not-found 2>/dev/null || true

    # Method 3: Find and remove any CrowdStrike-related webhooks
    local crowdstrike_webhooks=$(kubectl get validatingwebhookconfigurations -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n' | grep -i crowdstrike || echo "")
    if [[ -n "$crowdstrike_webhooks" ]]; then
        for webhook in $crowdstrike_webhooks; do
            clean_info "Removing webhook: $webhook"
            kubectl delete validatingwebhookconfigurations "$webhook" --ignore-not-found 2>/dev/null || true
        done
    fi

    # Additional cleanup for stuck resources
    clean_info "Cleaning up any remaining Falcon resources..."
    kubectl delete all,pvc,secrets,configmaps -l app.kubernetes.io/instance=falcon-platform --all-namespaces --ignore-not-found --timeout=30s 2>/dev/null || true

    clean_success "Cleanup completed"
    clean_info "You can now run the deployment again"
}

# Cleanup function
cleanup() {
    if [[ -f "falcon-container-sensor-pull.sh" ]]; then
        rm -f falcon-container-sensor-pull.sh
        clean_info "Cleaned up temporary files"
    fi
}

# TUI Functions for Interactive Mode
# =====================================

# Check if we should show TUI (if required vars are missing and we have TTY)
should_show_tui() {
    # Check if we have a TTY (interactive terminal)
    if [[ ! -t 0 ]]; then
        return 1  # Not interactive
    fi

    # Check if any required variables are missing
    if [[ -z "$FALCON_CLIENT_ID" || -z "$FALCON_CLIENT_SECRET" || -z "$CLUSTERNAME" ]]; then
        return 0  # Show TUI
    fi

    return 1  # All vars present, skip TUI
}

# TUI Welcome Screen
show_tui_welcome() {
    clear
    echo
    echo "🛡️  CrowdStrike Falcon Interactive Deployment"
    print_separator
    echo
    clean_info "Welcome! This interactive setup will guide you through deploying"
    clean_info "CrowdStrike Falcon Platform to your Kubernetes cluster."
    echo
    clean_info "You'll be prompted for:"
    echo "  • CrowdStrike OAuth credentials"
    echo "  • Component selection (Sensor, KAC, Image Analyzer)"
    echo "  • Cluster configuration"
    echo
    read -p "Press Enter to continue..." -r
}

# TUI Credential Input
tui_collect_credentials() {
    print_section "CREDENTIALS"

    # Falcon Client ID
    while [[ -z "$FALCON_CLIENT_ID" ]]; do
        echo
        clean_info "Enter your CrowdStrike Falcon OAuth Client ID:"
        clean_info "(Found in Falcon Console → Support and resources → API Clients & Keys)"
        echo -n "Client ID: "
        read -r FALCON_CLIENT_ID
        if [[ -z "$FALCON_CLIENT_ID" ]]; then
            clean_error "Client ID cannot be empty. Please try again."
        fi
    done

    # Falcon Client Secret
    while [[ -z "$FALCON_CLIENT_SECRET" ]]; do
        echo
        clean_info "Enter your CrowdStrike Falcon OAuth Client Secret:"
        clean_warning "Input will be hidden for security"
        echo -n "Client Secret: "
        read -rs FALCON_CLIENT_SECRET
        echo  # New line after hidden input
        if [[ -z "$FALCON_CLIENT_SECRET" ]]; then
            clean_error "Client Secret cannot be empty. Please try again."
        fi
    done

    # Cluster Name
    while [[ -z "$CLUSTERNAME" ]]; do
        echo
        clean_info "Enter a name for your Kubernetes cluster:"
        clean_info "(This is just a label - use any descriptive name)"
        echo -n "Cluster Name: "
        read -r CLUSTERNAME
        if [[ -z "$CLUSTERNAME" ]]; then
            clean_error "Cluster name cannot be empty. Please try again."
        fi
    done

    export FALCON_CLIENT_ID FALCON_CLIENT_SECRET CLUSTERNAME
    clean_success "Credentials collected successfully"
}

# TUI Component Selection
tui_select_components() {
    print_section "COMPONENT SELECTION"

    clean_info "Select CrowdStrike Falcon components to deploy:"
    echo

    # Falcon Sensor
    local sensor_choice
    while true; do
        echo -n "Deploy Falcon Sensor (node protection)? [Y/n]: "
        read -r sensor_choice
        case ${sensor_choice,,} in
            ""|"y"|"yes") INSTALL_SENSOR="true"; break ;;
            "n"|"no") INSTALL_SENSOR="false"; break ;;
            *) clean_error "Please enter 'y' for yes or 'n' for no" ;;
        esac
    done

    # Falcon KAC
    local kac_choice
    while true; do
        echo -n "Deploy Falcon Kubernetes Admission Controller? [Y/n]: "
        read -r kac_choice
        case ${kac_choice,,} in
            ""|"y"|"yes") INSTALL_KAC="true"; break ;;
            "n"|"no") INSTALL_KAC="false"; break ;;
            *) clean_error "Please enter 'y' for yes or 'n' for no" ;;
        esac
    done

    # Falcon Image Analyzer
    local iar_choice
    while true; do
        echo -n "Deploy Falcon Image Analyzer (container scanning)? [Y/n]: "
        read -r iar_choice
        case ${iar_choice,,} in
            ""|"y"|"yes") INSTALL_IAR="true"; break ;;
            "n"|"no") INSTALL_IAR="false"; break ;;
            *) clean_error "Please enter 'y' for yes or 'n' for no" ;;
        esac
    done

    # GKE Autopilot
    local gke_choice
    while true; do
        echo -n "Is this a GKE Autopilot cluster? [y/N]: "
        read -r gke_choice
        case ${gke_choice,,} in
            ""|"n"|"no") IS_GKE_AUTOPILOT="false"; break ;;
            "y"|"yes") IS_GKE_AUTOPILOT="true"; break ;;
            *) clean_error "Please enter 'y' for yes or 'n' for no" ;;
        esac
    done

    export INSTALL_SENSOR INSTALL_KAC INSTALL_IAR IS_GKE_AUTOPILOT

    # Validate at least one component selected
    if [[ "$INSTALL_SENSOR" == "false" && "$INSTALL_KAC" == "false" && "$INSTALL_IAR" == "false" ]]; then
        clean_error "At least one component must be selected"
        echo "Starting component selection again..."
        tui_select_components
        return
    fi

    clean_success "Component selection complete"
}

# TUI Configuration Summary
tui_show_summary() {
    print_section "DEPLOYMENT SUMMARY"

    clean_info "Ready to deploy with the following configuration:"
    echo
    echo "Credentials:"
    echo "  Client ID: ${FALCON_CLIENT_ID:0:8}..."
    echo "  Cluster Name: $CLUSTERNAME"
    echo
    echo "Components:"
    [[ "$INSTALL_SENSOR" == "true" ]] && clean_success "  ✅ Falcon Sensor" || clean_warning "  ❌ Falcon Sensor"
    [[ "$INSTALL_KAC" == "true" ]] && clean_success "  ✅ Falcon KAC" || clean_warning "  ❌ Falcon KAC"
    [[ "$INSTALL_IAR" == "true" ]] && clean_success "  ✅ Falcon Image Analyzer" || clean_warning "  ❌ Falcon Image Analyzer"
    echo
    echo "Cluster Type:"
    [[ "$IS_GKE_AUTOPILOT" == "true" ]] && clean_success "  ⚙️  GKE Autopilot" || clean_info "  🖥️  Standard Kubernetes"
    echo

    local confirm
    while true; do
        echo -n "Proceed with deployment? [Y/n]: "
        read -r confirm
        case ${confirm,,} in
            ""|"y"|"yes") break ;;
            "n"|"no")
                clean_info "Deployment cancelled by user"
                exit 0
                ;;
            *) clean_error "Please enter 'y' for yes or 'n' for no" ;;
        esac
    done

    clean_success "Starting deployment..."
}

# Run TUI if needed
run_tui_if_needed() {
    if should_show_tui; then
        show_tui_welcome
        tui_collect_credentials
        tui_select_components
        tui_show_summary
    fi
}

# Main execution
main() {
    # Set trap for cleanup
    trap cleanup EXIT

    # Run TUI if needed (before other checks)
    run_tui_if_needed

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
trap 'clean_error "Script failed at line $LINENO"; cleanup' ERR

# Check for cleanup argument
if [[ "$1" == "cleanup" || "$1" == "--cleanup" ]]; then
    cleanup_deployment
    exit 0
fi

# Run main function
main "$@"