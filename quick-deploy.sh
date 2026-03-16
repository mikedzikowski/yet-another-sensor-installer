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
    FALCON_SENSOR_MODE="${FALCON_SENSOR_MODE:-bpf}"

    # Log selections with better formatting
    clean_info "Selected components:"
    [[ "$INSTALL_SENSOR" == "true" ]] && clean_success "✅ Falcon Sensor" || clean_warning "❌ Falcon Sensor"
    [[ "$INSTALL_KAC" == "true" ]] && clean_success "✅ Falcon KAC" || clean_warning "❌ Falcon KAC"
    [[ "$INSTALL_IAR" == "true" ]] && clean_success "✅ Falcon Image Analyzer" || clean_warning "❌ Falcon Image Analyzer"

    echo
    clean_info "Cluster type:"
    [[ "$IS_GKE_AUTOPILOT" == "true" ]] && clean_success "⚙️  GKE Autopilot" || clean_info "🖥️  Standard Kubernetes"

    # Show sensor mode configuration if sensor is enabled
    if [[ "$INSTALL_SENSOR" == "true" ]]; then
        echo
        clean_info "Falcon Sensor mode:"
        case "$FALCON_SENSOR_MODE" in
            "kernel")
                clean_success "🔒 Kernel mode"
                ;;
            "bpf")
                clean_info "🛡️  eBPF user mode"
                ;;
            *)
                clean_warning "⚠️  Unknown sensor mode: $FALCON_SENSOR_MODE (using kernel mode)"
                FALCON_SENSOR_MODE="kernel"
                ;;
        esac
    fi

    # Validate at least one component is selected
    if [[ "$INSTALL_SENSOR" == "false" && "$INSTALL_KAC" == "false" && "$INSTALL_IAR" == "false" ]]; then
        echo
        clean_error "At least one component must be selected"
        exit 1
    fi
}

# Image Version Selection Functions
# =================================

# List available image tags for a component
list_component_tags() {
    local component_type="$1"
    local output_format="${2:-json}"

    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "Fetching available tags for $component_type..."
    fi

    local tags_output=$(./falcon-container-sensor-pull.sh --type "$component_type" --list-tags 2>/dev/null)

    if [[ $? -eq 0 && -n "$tags_output" ]]; then
        if [[ "$output_format" == "json" ]]; then
            echo "$tags_output"
        elif [[ "$output_format" == "list" ]]; then
            echo "$tags_output" | grep -o '"[^"]*"' | grep -E "^\"[0-9]" | tr -d '"' | head -20
        fi
    else
        clean_error "Failed to retrieve tags for $component_type"
        return 1
    fi
}

# Show available versions for user selection
show_available_versions() {
    if [[ "$VERBOSE" == "true" ]] || [[ -n "$SHOW_VERSIONS" ]]; then
        print_section "AVAILABLE IMAGE VERSIONS"

        if [[ "$INSTALL_SENSOR" == "true" ]]; then
            clean_info "Falcon Sensor versions:"
            list_component_tags "falcon-sensor" "list" | sed 's/^/  /'
            echo
        fi

        if [[ "$INSTALL_KAC" == "true" ]]; then
            clean_info "Falcon KAC versions:"
            list_component_tags "falcon-kac" "list" | sed 's/^/  /'
            echo
        fi

        if [[ "$INSTALL_IAR" == "true" ]]; then
            clean_info "Falcon Image Analyzer versions:"
            list_component_tags "falcon-imageanalyzer" "list" | sed 's/^/  /'
            echo
        fi

        clean_info "To use specific versions, set environment variables:"
        echo "  export FALCON_SENSOR_VERSION=\"7.34.0-18708-1\""
        echo "  export FALCON_KAC_VERSION=\"7.35.0-3302\""
        echo "  export FALCON_IAR_VERSION=\"1.0.23\""
        echo
    fi
}

# Interactive version selection for deployment
interactive_version_selection() {
    # Skip if environment variables are already set or if non-interactive (unless forced)
    if [[ -n "$FALCON_SENSOR_VERSION" ]] || [[ -n "$FALCON_KAC_VERSION" ]] || [[ -n "$FALCON_IAR_VERSION" ]] || [[ "$SKIP_VERSION_SELECTION" == "true" ]]; then
        return 0
    fi

    # Check if interactive (TTY) or forced interactive mode
    if [[ ! -t 0 ]] && [[ "$FORCE_INTERACTIVE" != "true" ]]; then
        clean_info "Non-interactive environment detected. Skipping version selection (using latest versions)"
        clean_info "To force interactive mode, set: export FORCE_INTERACTIVE=true"
        return 0
    fi

    print_section "INTERACTIVE VERSION SELECTION"

    clean_info "🏷️  Fetching latest available image versions..."
    echo

    # Interactive selection for Falcon Sensor
    if [[ "$INSTALL_SENSOR" == "true" ]]; then
        clean_info "Falcon Sensor versions available:"
        local sensor_versions=$(list_component_tags "falcon-sensor" "list" | head -10)
        if [[ -n "$sensor_versions" ]]; then
            echo "$sensor_versions" | nl -nln
            echo
            local sensor_choice
            while true; do
                echo -n "Select Falcon Sensor version (1-$(echo "$sensor_versions" | wc -l), or 'latest' for newest): "
                read -r sensor_choice

                if [[ "$sensor_choice" == "latest" ]]; then
                    export FALCON_SENSOR_VERSION=$(echo "$sensor_versions" | tail -n 1)
                    clean_success "Selected Falcon Sensor version (latest): $FALCON_SENSOR_VERSION"
                    break
                elif [[ "$sensor_choice" =~ ^[0-9]+$ ]] && [[ "$sensor_choice" -ge 1 ]] && [[ "$sensor_choice" -le $(echo "$sensor_versions" | wc -l) ]]; then
                    export FALCON_SENSOR_VERSION=$(echo "$sensor_versions" | sed -n "${sensor_choice}p")
                    clean_success "Selected Falcon Sensor version: $FALCON_SENSOR_VERSION"
                    break
                else
                    clean_error "Invalid selection. Please enter a number 1-$(echo "$sensor_versions" | wc -l) or 'latest'"
                fi
            done
        else
            clean_warning "Could not fetch Falcon Sensor versions, using latest"
        fi
        echo
    fi

    # Interactive selection for Falcon KAC
    if [[ "$INSTALL_KAC" == "true" ]]; then
        clean_info "Falcon KAC versions available:"
        local kac_versions=$(list_component_tags "falcon-kac" "list" | head -10)
        if [[ -n "$kac_versions" ]]; then
            echo "$kac_versions" | nl -nln
            echo
            local kac_choice
            while true; do
                echo -n "Select Falcon KAC version (1-$(echo "$kac_versions" | wc -l), or 'latest' for newest): "
                read -r kac_choice

                if [[ "$kac_choice" == "latest" ]]; then
                    export FALCON_KAC_VERSION=$(echo "$kac_versions" | tail -n 1)
                    clean_success "Selected Falcon KAC version (latest): $FALCON_KAC_VERSION"
                    break
                elif [[ "$kac_choice" =~ ^[0-9]+$ ]] && [[ "$kac_choice" -ge 1 ]] && [[ "$kac_choice" -le $(echo "$kac_versions" | wc -l) ]]; then
                    export FALCON_KAC_VERSION=$(echo "$kac_versions" | sed -n "${kac_choice}p")
                    clean_success "Selected Falcon KAC version: $FALCON_KAC_VERSION"
                    break
                else
                    clean_error "Invalid selection. Please enter a number 1-$(echo "$kac_versions" | wc -l) or 'latest'"
                fi
            done
        else
            clean_warning "Could not fetch Falcon KAC versions, using latest"
        fi
        echo
    fi

    # Interactive selection for Falcon Image Analyzer
    if [[ "$INSTALL_IAR" == "true" ]]; then
        clean_info "Falcon Image Analyzer versions available:"
        local iar_versions=$(list_component_tags "falcon-imageanalyzer" "list" | head -10)
        if [[ -n "$iar_versions" ]]; then
            echo "$iar_versions" | nl -nln
            echo
            local iar_choice
            while true; do
                echo -n "Select Falcon Image Analyzer version (1-$(echo "$iar_versions" | wc -l), or 'latest' for newest): "
                read -r iar_choice

                if [[ "$iar_choice" == "latest" ]]; then
                    export FALCON_IAR_VERSION=$(echo "$iar_versions" | tail -n 1)
                    clean_success "Selected Falcon Image Analyzer version (latest): $FALCON_IAR_VERSION"
                    break
                elif [[ "$iar_choice" =~ ^[0-9]+$ ]] && [[ "$iar_choice" -ge 1 ]] && [[ "$iar_choice" -le $(echo "$iar_versions" | wc -l) ]]; then
                    export FALCON_IAR_VERSION=$(echo "$iar_versions" | sed -n "${iar_choice}p")
                    clean_success "Selected Falcon Image Analyzer version: $FALCON_IAR_VERSION"
                    break
                else
                    clean_error "Invalid selection. Please enter a number 1-$(echo "$iar_versions" | wc -l) or 'latest'"
                fi
            done
        else
            clean_warning "Could not fetch Falcon Image Analyzer versions, using latest"
        fi
        echo
    fi

    # Summary of selections
    if [[ -n "$FALCON_SENSOR_VERSION" ]] || [[ -n "$FALCON_KAC_VERSION" ]] || [[ -n "$FALCON_IAR_VERSION" ]]; then
        clean_info "Version selections summary:"
        [[ -n "$FALCON_SENSOR_VERSION" ]] && echo "  Sensor: $FALCON_SENSOR_VERSION" || echo "  Sensor: latest"
        [[ -n "$FALCON_KAC_VERSION" ]] && echo "  KAC: $FALCON_KAC_VERSION" || echo "  KAC: latest"
        [[ -n "$FALCON_IAR_VERSION" ]] && echo "  Image Analyzer: $FALCON_IAR_VERSION" || echo "  Image Analyzer: latest"
        echo
    fi

    local proceed_choice
    while true; do
        echo -n "Proceed with these version selections? [Y/n]: "
        read -r proceed_choice
        case ${proceed_choice,,} in
            ""|"y"|"yes")
                clean_success "Proceeding with selected versions"
                break
                ;;
            "n"|"no")
                clean_info "Deployment cancelled by user"
                exit 0
                ;;
            *)
                clean_error "Please enter 'y' for yes or 'n' for no"
                ;;
        esac
    done
}

# Configure image versions (either custom or latest)
configure_image_versions() {
    print_section "IMAGE VERSION CONFIGURATION"

    # Check for custom versions first
    local using_custom_versions=false

    if [[ -n "$FALCON_SENSOR_VERSION" ]]; then
        using_custom_versions=true
        export SENSOR_IMAGE_TAG="$FALCON_SENSOR_VERSION"
        clean_info "Using custom Falcon Sensor version: $FALCON_SENSOR_VERSION"
    fi

    if [[ -n "$FALCON_KAC_VERSION" ]]; then
        using_custom_versions=true
        export KAC_IMAGE_TAG="$FALCON_KAC_VERSION"
        clean_info "Using custom Falcon KAC version: $FALCON_KAC_VERSION"
    fi

    if [[ -n "$FALCON_IAR_VERSION" ]]; then
        using_custom_versions=true
        export IAR_IMAGE_TAG="$FALCON_IAR_VERSION"
        clean_info "Using custom Falcon Image Analyzer version: $FALCON_IAR_VERSION"
    fi

    # If custom versions are specified, skip the API calls for those components
    if [[ "$using_custom_versions" == "true" ]]; then
        clean_success "Custom image versions configured"
        return 0
    else
        clean_info "No custom versions specified - will use latest from API"
        return 1
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

# Get minimal Falcon configuration when custom versions are specified
get_falcon_configuration_minimal() {
    print_section "FALCON CONFIGURATION (Custom Versions)"

    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "Using custom image versions - retrieving CID and registry credentials..."
        clean_info "Using Client ID: ${FALCON_CLIENT_ID:0:8}..."
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

    # Set registry paths for custom versions (will be overridden with custom tags)
    if [[ -n "$FALCON_SENSOR_VERSION" && "$INSTALL_SENSOR" == "true" ]]; then
        export SENSOR_REGISTRY="registry.crowdstrike.com/falcon-sensor/release/falcon-sensor"
        [[ "$VERBOSE" == "true" ]] && clean_success "Sensor: $SENSOR_REGISTRY:$SENSOR_IMAGE_TAG"
    fi

    if [[ -n "$FALCON_KAC_VERSION" && "$INSTALL_KAC" == "true" ]]; then
        export KAC_REGISTRY="registry.crowdstrike.com/falcon-kac/release/falcon-kac"
        [[ "$VERBOSE" == "true" ]] && clean_success "KAC: $KAC_REGISTRY:$KAC_IMAGE_TAG"
    fi

    if [[ -n "$FALCON_IAR_VERSION" && "$INSTALL_IAR" == "true" ]]; then
        # IAR needs special handling for region detection
        if ! FALCON_IAR_IMAGE_FULL_PATH=$(./falcon-container-sensor-pull.sh -t falcon-imageanalyzer --get-image-path 2>/dev/null); then
            # Fallback to us-1 if detection fails
            export IAR_REGISTRY="registry.crowdstrike.com/falcon-imageanalyzer/us-1/release/falcon-imageanalyzer"
        else
            export IAR_REGISTRY=$(echo $FALCON_IAR_IMAGE_FULL_PATH | cut -d':' -f 1)
        fi
        [[ "$VERBOSE" == "true" ]] && clean_success "IAR: $IAR_REGISTRY:$IAR_IMAGE_TAG"
    fi

    clean_success "Falcon configuration retrieved with custom versions"
    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "✓ Customer ID acquired"
        clean_info "✓ Registry access configured"
        clean_info "✓ Custom image versions applied"
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

    # Search for ANY Falcon-related releases across ALL namespaces (including failed ones)
    local falcon_releases=$(helm list -A -a -o json 2>/dev/null | jq -r '.[] | select(.name | test("falcon")) | "\(.name) \(.namespace) \(.status)"' 2>/dev/null || echo "")

    # Fallback if jq not available - search with grep (including failed releases)
    if [[ -z "$falcon_releases" ]]; then
        falcon_releases=$(helm list -A -a 2>/dev/null | grep -E "(falcon-platform|falcon-kac|falcon-sensor|falcon-helm|falcon-image-analyzer)" || echo "")
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

    # Helm chart will handle namespace creation via createComponentNamespaces=true

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

        # Add sensor backend mode configuration
        if [[ -n "$FALCON_SENSOR_MODE" ]]; then
            helm_cmd="$helm_cmd \
            --set falcon-sensor.node.backend=\"$FALCON_SENSOR_MODE\""
        fi

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

    # Verify Falcon sensor registration if sensor is installed
    if [[ "$INSTALL_SENSOR" == "true" ]]; then
        verify_falcon_sensor_registration
    fi

    clean_success "Initial verification complete!"
    echo
    clean_info "Note: Pods may take several minutes to fully start and become ready"
}

# Verify Falcon sensor registration with CrowdStrike
verify_falcon_sensor_registration() {
    echo
    clean_info "Falcon Sensor Registration Status:"
    echo "==================================="

    # Find a running Falcon sensor pod
    local sensor_pod=$(kubectl get pods -n falcon-system -l app.kubernetes.io/name=falcon-sensor --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [[ -z "$sensor_pod" ]]; then
        clean_warning "No running Falcon sensor pods found yet - this is normal during initial startup"
        clean_info "Pods may still be starting. Check status later with:"
        echo "  kubectl get pods -n falcon-system"
        return
    fi

    clean_info "Found running sensor pod: $sensor_pod"
    echo

    # Execute falconctl command to get sensor status
    clean_info "Retrieving sensor registration details..."
    local falconctl_output
    if falconctl_output=$(kubectl exec -n falcon-system "$sensor_pod" -- /opt/CrowdStrike/falconctl -g --aid --cid --version --backend --rfm-state --rfm-reason 2>/dev/null); then
        echo
        # Parse and display the key information
        echo "✅ Sensor Status:"

        # Extract AID (Agent ID) - handle both quoted and unquoted formats
        local aid=""
        if echo "$falconctl_output" | grep -q 'aid='; then
            # Try quoted format first: aid="value"
            if echo "$falconctl_output" | grep -q 'aid="[^"]*"'; then
                aid=$(echo "$falconctl_output" | grep -oE 'aid="[^"]*"' | head -1 | sed 's/aid="//; s/"$//')
            else
                # Try unquoted format: aid=value
                aid=$(echo "$falconctl_output" | grep -oE 'aid=[^,[:space:]]*' | head -1 | sed 's/aid=//; s/,$//')
            fi
            if [[ -n "$aid" && "$aid" != "none" && "$aid" != "" ]]; then
                echo "🆔 Agent ID (AID): $aid"
            else
                echo "⚠️  Agent ID (AID): Not yet assigned"
            fi
        fi

        # Extract CID (Customer ID) - handle both quoted and unquoted formats
        local cid=""
        if echo "$falconctl_output" | grep -q 'cid='; then
            # Try quoted format first: cid="value"
            if echo "$falconctl_output" | grep -q 'cid="[^"]*"'; then
                cid=$(echo "$falconctl_output" | grep -oE 'cid="[^"]*"' | head -1 | sed 's/cid="//; s/"$//')
            else
                # Try unquoted format: cid=value
                cid=$(echo "$falconctl_output" | grep -oE 'cid=[^,[:space:]]*' | head -1 | sed 's/cid=//; s/,$//')
            fi
            if [[ -n "$cid" && "$cid" != "none" && "$cid" != "" ]]; then
                echo "🏢 Customer ID (CID): $cid"
            else
                echo "⚠️  Customer ID (CID): Not configured"
            fi
        fi

        # Extract Version - handle both quoted and unquoted formats with flexible spacing
        local version=""
        if echo "$falconctl_output" | grep -q 'version'; then
            # Try quoted format first: version="value" or version = "value"
            if echo "$falconctl_output" | grep -q 'version[[:space:]]*=[[:space:]]*"[^"]*"'; then
                version=$(echo "$falconctl_output" | grep -oE 'version[[:space:]]*=[[:space:]]*"[^"]*"' | head -1 | sed 's/version[[:space:]]*=[[:space:]]*"//; s/"$//')
            else
                # Try unquoted format: version=value or version = value
                version=$(echo "$falconctl_output" | grep -oE 'version[[:space:]]*=[[:space:]]*[^,[:space:]]*' | head -1 | sed 's/version[[:space:]]*=[[:space:]]*//; s/,$//')
            fi
            if [[ -n "$version" && "$version" != "none" && "$version" != "" ]]; then
                echo "📦 Sensor Version: $version"
            fi
        fi

        # Extract Backend connection status - handle both quoted and unquoted formats
        local backend=""
        if echo "$falconctl_output" | grep -q 'backend='; then
            # Try quoted format first: backend="value"
            if echo "$falconctl_output" | grep -q 'backend="[^"]*"'; then
                backend=$(echo "$falconctl_output" | grep -oE 'backend="[^"]*"' | head -1 | sed 's/backend="//; s/"$//')
            else
                # Try unquoted format: backend=value
                backend=$(echo "$falconctl_output" | grep -oE 'backend=[^,[:space:]]*' | head -1 | sed 's/backend=//; s/,$//')
            fi
            if [[ -n "$backend" && "$backend" != "none" && "$backend" != "" ]]; then
                echo "🌐 Backend Status: $backend"
            fi
        fi

        # Extract RFM (Reduced Functionality Mode) status - handle both quoted and unquoted formats
        local rfm_state=""
        if echo "$falconctl_output" | grep -q 'rfm-state='; then
            # Try quoted format first: rfm-state="value"
            if echo "$falconctl_output" | grep -q 'rfm-state="[^"]*"'; then
                rfm_state=$(echo "$falconctl_output" | grep -oE 'rfm-state="[^"]*"' | head -1 | sed 's/rfm-state="//; s/"$//')
            else
                # Try unquoted format: rfm-state=value
                rfm_state=$(echo "$falconctl_output" | grep -oE 'rfm-state=[^,[:space:]]*' | head -1 | sed 's/rfm-state=//; s/,$//')
            fi
            if [[ "$rfm_state" == "false" ]]; then
                echo "✅ RFM State: Normal operation (RFM disabled)"
            elif [[ "$rfm_state" == "true" ]]; then
                echo "⚠️  RFM State: Reduced functionality mode enabled"
                # Show RFM reason if available
                local rfm_reason=""
                if echo "$falconctl_output" | grep -q 'rfm-reason='; then
                    # Try quoted format first: rfm-reason="value"
                    if echo "$falconctl_output" | grep -q 'rfm-reason="[^"]*"'; then
                        rfm_reason=$(echo "$falconctl_output" | grep -oE 'rfm-reason="[^"]*"' | head -1 | sed 's/rfm-reason="//; s/"$//')
                    else
                        # Try unquoted format: rfm-reason=value
                        rfm_reason=$(echo "$falconctl_output" | grep -oE 'rfm-reason=[^,[:space:]]*' | head -1 | sed 's/rfm-reason=//; s/,$//')
                    fi
                    if [[ -n "$rfm_reason" && "$rfm_reason" != "" && "$rfm_reason" != "None" ]]; then
                        echo "📋 RFM Reason: $rfm_reason"
                    fi
                fi
            fi
        fi

        echo
        # Check if we have a valid AID to confirm registration
        if [[ -n "$aid" && "$aid" != "none" && "$aid" != "" ]]; then
            clean_success "🎯 Sensor is successfully registered and communicating with CrowdStrike!"
        else
            clean_warning "⏳ Sensor is running but registration may still be in progress"
            clean_info "This is normal during initial startup - registration typically completes within 2-5 minutes"
        fi

    else
        clean_warning "Unable to retrieve sensor status (pod may still be initializing)"
        clean_info "You can check sensor status later with:"
        echo "  kubectl exec -n falcon-system \$POD_NAME -- /opt/CrowdStrike/falconctl -g --aid --cid --version"
    fi
}

# Print success message and next steps
# Detect CrowdStrike cloud region from registry URLs
detect_falcon_cloud_region() {
    local region="us-1"  # default

    # Try to detect region from sensor registry URL
    if [[ -n "$SENSOR_REGISTRY" ]]; then
        if [[ "$SENSOR_REGISTRY" == *"us-2"* ]]; then
            region="us-2"
        elif [[ "$SENSOR_REGISTRY" == *"eu-1"* ]]; then
            region="eu-1"
        elif [[ "$SENSOR_REGISTRY" == *"gov"* ]]; then
            region="gov"
        fi
    fi

    echo "$region"
}

# Get the appropriate CrowdStrike console URL for detected region
get_console_base_url() {
    local region=$(detect_falcon_cloud_region)

    case "$region" in
        "us-2")
            echo "https://falcon.us-2.crowdstrike.com"
            ;;
        "eu-1")
            echo "https://falcon.eu-1.crowdstrike.com"
            ;;
        "gov")
            echo "https://falcon.laggar.gcw.crowdstrike.com"
            ;;
        *)
            echo "https://falcon.crowdstrike.com"  # us-1 default
            ;;
    esac
}

# Generate CrowdStrike Host Management links for cluster nodes
generate_node_management_links() {
    echo
    clean_info "📋 Cluster Nodes - CrowdStrike Host Management Links:"
    echo

    # Debug output if verbose mode
    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "🔍 Debug: Starting node management links generation"
    fi

    # Get cluster nodes
    local nodes
    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "🔍 Debug: Attempting to get cluster nodes with kubectl"
    fi

    if ! nodes=$(kubectl get nodes --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null); then
        clean_warning "⚠️  Could not retrieve cluster nodes (kubectl permission issue)"
        if [[ "$VERBOSE" == "true" ]]; then
            clean_info "🔍 Debug: kubectl command failed, trying with error output:"
            kubectl get nodes --no-headers -o custom-columns=NAME:.metadata.name
        fi
        return 1
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "🔍 Debug: kubectl succeeded, node data length: ${#nodes}"
        clean_info "🔍 Debug: Raw nodes data: '$nodes'"
    fi

    if [[ -z "$nodes" ]]; then
        clean_warning "⚠️  No nodes found in cluster"
        return 1
    fi

    # Detect the correct console base URL for the region
    local console_base_url=$(get_console_base_url)
    local detected_region=$(detect_falcon_cloud_region)

    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "Detected Falcon region: $detected_region"
        clean_info "Using console URL: $console_base_url"
    fi

    # Count nodes and show numbered list
    local node_count=0
    local node_array=()

    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "🔍 Debug: Starting node processing loop"
    fi

    # Temporarily disable exit on error for this loop
    set +e
    while IFS= read -r node; do
        if [[ -n "$node" ]]; then
            if [[ "$VERBOSE" == "true" ]]; then
                clean_info "🔍 Debug: Processing raw node: '$node'"
            fi

            local clean_node
            if ! clean_node=$(printf '%s' "$node" | tr -d '\n\r'); then
                if [[ "$VERBOSE" == "true" ]]; then
                    clean_warning "🔍 Debug: Failed to clean node: '$node'"
                fi
                continue
            fi

            if [[ "$VERBOSE" == "true" ]]; then
                clean_info "🔍 Debug: Cleaned node: '$clean_node'"
            fi

            if ! node_array+=("$clean_node"); then
                if [[ "$VERBOSE" == "true" ]]; then
                    clean_warning "🔍 Debug: Failed to add node to array: '$clean_node'"
                fi
                continue
            fi

            ((node_count++)) || true  # Prevent exit if this fails

            if [[ "$VERBOSE" == "true" ]]; then
                clean_info "🔍 Debug: Added node #$node_count: '$clean_node'"
            fi
        fi
    done <<< "$nodes"
    # Re-enable exit on error
    set -e

    if [[ "$VERBOSE" == "true" ]]; then
        clean_info "🔍 Debug: Total nodes processed: $node_count"
        clean_info "🔍 Debug: Node array length: ${#node_array[@]}"
    fi

    # Display numbered list with console link text and URLs
    for i in "${!node_array[@]}"; do
        local node_num=$((i + 1))
        local clean_node="${node_array[$i]}"
        printf "  %2d. %-40s 🔗 Console Link\n" "$node_num" "$clean_node"
    done

    echo
    clean_info "💡 Found $node_count nodes in cluster"

    # Show the actual clickable console URLs
    echo
    clean_info "🔗 Clickable Console Links:"
    echo

    for i in "${!node_array[@]}"; do
        local node_num=$((i + 1))
        local clean_node="${node_array[$i]}"
        local encoded_node=$(printf '%s' "$clean_node" | jq -sRr @uri)
        local console_url="${console_base_url}/host-management/hosts?filter=hostname%3A%27${encoded_node}%27"

        printf "  %2d. %s\n" "$node_num" "$clean_node"
        echo "      🌐 $console_url"
        echo
    done

    if [[ "$detected_region" != "us-1" ]]; then
        clean_info "🌍 Detected region: $detected_region (console adjusted automatically)"
    fi
}

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

    # Add node management links if sensor is installed
    if [[ "$INSTALL_SENSOR" == "true" ]]; then
        generate_node_management_links
    fi

    echo
    echo "Next steps:"
    echo "  1. Monitor the deployment: kubectl get pods -A | grep falcon"
    if [[ "$INSTALL_SENSOR" == "true" ]]; then
        echo "  2. Check sensor registration: kubectl exec -n falcon-system \$(kubectl get pods -n falcon-system -l app.kubernetes.io/name=falcon-sensor -o name | head -1 | cut -d/ -f2) -- /opt/CrowdStrike/falconctl -g --aid --cid"
        echo "  3. Check logs if needed: kubectl logs -n <namespace> <pod-name>"
        echo "  4. View in Falcon Console: $(get_console_base_url)"
    else
        echo "  2. Check logs if needed: kubectl logs -n <namespace> <pod-name>"
        echo "  3. View in Falcon Console: $(get_console_base_url)"
    fi
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
    done < <(helm list -A -a 2>/dev/null || echo "")

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

    # ENHANCED: Clean up individual component releases (non-platform chart deployments)
    clean_info "Scanning for individual Falcon component releases..."
    local individual_components_found=false

    # Check for individual component releases that bypass the platform chart
    local individual_releases=$(helm list -A -a 2>/dev/null | grep -E "^(falcon-sensor|falcon-kac|falcon-image-analyzer)\s" || echo "")

    if [[ -n "$individual_releases" ]]; then
        individual_components_found=true
        clean_warning "Found individual Falcon component releases (non-platform chart):"
        echo "$individual_releases"

        # Remove individual component releases
        while IFS= read -r release_line; do
            if [[ -n "$release_line" ]]; then
                local comp_name=$(echo "$release_line" | awk '{print $1}')
                local comp_ns=$(echo "$release_line" | awk '{print $2}')

                clean_info "Removing individual component: '$comp_name' from namespace '$comp_ns'..."
                helm uninstall "$comp_name" -n "$comp_ns" --ignore-not-found || {
                    clean_warning "Failed to remove individual component $comp_name from $comp_ns"
                }
            fi
        done <<< "$individual_releases"
    fi

    # ENHANCED: Clean up Falcon Operator deployments and CRDs
    clean_info "Scanning for Falcon Operator installations..."
    local operator_found=false

    # Check for Falcon Operator Helm releases
    local operator_releases=$(helm list -A -a 2>/dev/null | grep -E "(falcon-operator|crowdstrike-falcon-operator)" || echo "")
    if [[ -n "$operator_releases" ]]; then
        operator_found=true
        clean_warning "Found Falcon Operator releases:"
        echo "$operator_releases"

        while IFS= read -r operator_line; do
            if [[ -n "$operator_line" ]]; then
                local op_name=$(echo "$operator_line" | awk '{print $1}')
                local op_ns=$(echo "$operator_line" | awk '{print $2}')

                clean_info "Removing Falcon Operator: '$op_name' from namespace '$op_ns'..."
                helm uninstall "$op_name" -n "$op_ns" --ignore-not-found || {
                    clean_warning "Failed to remove Falcon Operator $op_name from $op_ns"
                }
            fi
        done <<< "$operator_releases"
    fi

    # Check for Falcon Operator CRDs
    local falcon_crds=$(kubectl get crd 2>/dev/null | grep -E "(falcon|crowdstrike)" | awk '{print $1}' || echo "")
    if [[ -n "$falcon_crds" ]]; then
        operator_found=true
        clean_warning "Found Falcon/CrowdStrike CRDs:"
        echo "$falcon_crds"

        clean_info "Removing Falcon/CrowdStrike CRDs..."
        for crd in $falcon_crds; do
            clean_info "Deleting CRD: $crd"
            kubectl delete crd "$crd" --ignore-not-found --timeout=30s || {
                clean_warning "Failed to delete CRD $crd (may have finalizers)"
            }
        done
    fi

    # Check for Falcon Operator workloads in common namespaces
    local operator_workloads=$(kubectl get deployment,daemonset -A 2>/dev/null | grep -E "(falcon-operator|crowdstrike-falcon)" || echo "")
    if [[ -n "$operator_workloads" ]]; then
        operator_found=true
        clean_warning "Found Falcon Operator workloads:"
        echo "$operator_workloads"

        clean_info "Removing Falcon Operator workloads..."
        kubectl delete deployment,daemonset -A -l app.kubernetes.io/name=falcon-operator --ignore-not-found --timeout=30s 2>/dev/null || true
        kubectl delete deployment,daemonset -A -l app=falcon-operator --ignore-not-found --timeout=30s 2>/dev/null || true
    fi

    # Check for Falcon Operator namespaces
    local operator_namespaces=$(kubectl get namespace 2>/dev/null | grep -E "(falcon-operator|crowdstrike)" | awk '{print $1}' || echo "")
    if [[ -n "$operator_namespaces" ]]; then
        operator_found=true
        clean_info "Removing Falcon Operator namespaces: $operator_namespaces"
        for ns in $operator_namespaces; do
            kubectl delete namespace "$ns" --ignore-not-found --timeout=60s || {
                clean_warning "Namespace $ns may take longer to delete"
            }
        done
    fi

    # Summary of enhanced cleanup
    if [[ "$individual_components_found" == "false" && "$operator_found" == "false" ]]; then
        clean_success "No individual components or Falcon Operator installations found"
    else
        if [[ "$individual_components_found" == "true" ]]; then
            clean_success "Individual Falcon component releases cleaned up"
        fi
        if [[ "$operator_found" == "true" ]]; then
            clean_success "Falcon Operator installation cleaned up"
        fi
    fi

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

# Main execution
main() {
    # Set trap for cleanup
    trap cleanup EXIT

    check_root
    select_components
    validate_environment
    check_prerequisites
    download_falcon_script

    # Interactive version selection (if TTY and no pre-set versions)
    interactive_version_selection

    # Show available versions if requested
    show_available_versions

    # Configure image versions (custom or latest from API)
    if ! configure_image_versions; then
        # No custom versions, get latest from API
        get_falcon_configuration
    else
        # Custom versions specified, still need CID and registry config
        get_falcon_configuration_minimal
    fi

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

# Check for list-versions argument
if [[ "$1" == "list-versions" || "$1" == "--list-versions" ]]; then
    export SHOW_VERSIONS=true
    export VERBOSE=true
    # Need credentials for API calls
    if [[ -z "$FALCON_CLIENT_ID" || -z "$FALCON_CLIENT_SECRET" ]]; then
        echo
        echo "🛡️  CrowdStrike Falcon Available Image Versions"
        print_separator
        echo
        clean_error "Missing required credentials for API access"
        echo
        echo "Set your credentials first:"
        echo "  export FALCON_CLIENT_ID=\"your-client-id\""
        echo "  export FALCON_CLIENT_SECRET=\"your-client-secret\""
        echo
        echo "Then run: $0 list-versions"
        exit 1
    fi

    # Download the falcon script if needed
    if [[ ! -f "falcon-container-sensor-pull.sh" ]]; then
        curl -sSL -o falcon-container-sensor-pull.sh "https://github.com/CrowdStrike/falcon-scripts/releases/latest/download/falcon-container-sensor-pull.sh" >/dev/null 2>&1
        chmod +x falcon-container-sensor-pull.sh
    fi

    # Show available versions
    echo
    echo "🛡️  CrowdStrike Falcon Available Image Versions"
    print_separator
    echo

    # Set defaults for components to show all versions
    INSTALL_SENSOR=true INSTALL_KAC=true INSTALL_IAR=true show_available_versions

    # Clean up
    rm -f falcon-container-sensor-pull.sh
    exit 0
fi

# Run main function
main "$@"