#!/bin/bash

# CrowdStrike Falcon Simple Uninstall Script
# This script removes the complete Falcon Platform deployment
#
# Usage:
#   ./uninstall-falcon.sh

set -e

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if kubectl is installed and working
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi

    # Check kubectl connectivity
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log_error "Helm is not installed or not in PATH"
        exit 1
    fi

    log_success "All prerequisites are installed"
}

# Check if Falcon Platform is installed
check_falcon_installation() {
    log_info "Checking for Falcon Platform installation..."

    if ! helm list -n falcon-platform 2>/dev/null | grep -q falcon-platform; then
        log_warning "Falcon Platform Helm release not found in 'falcon-platform' namespace"

        # Check if it might be installed in a different namespace
        local helm_releases=$(helm list -A 2>/dev/null | grep falcon-platform || true)
        if [[ -n "$helm_releases" ]]; then
            log_info "Found Falcon Platform in other namespaces:"
            echo "$helm_releases"
            echo
            log_warning "Please run 'helm uninstall' manually for the appropriate namespace"
        else
            log_info "No Falcon Platform Helm releases found"
        fi

        # Still check for leftover namespaces and resources
        check_leftover_resources
        return 0
    fi

    log_success "Found Falcon Platform installation"
    return 1
}

# Check for leftover resources
check_leftover_resources() {
    log_info "Checking for leftover Falcon resources..."

    local namespaces=("falcon-system" "falcon-kac" "falcon-image-analyzer" "falcon-platform")
    local found_namespaces=()

    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" &>/dev/null; then
            found_namespaces+=("$ns")
        fi
    done

    if [[ ${#found_namespaces[@]} -eq 0 ]]; then
        log_success "No Falcon namespaces found"
        return 0
    fi

    log_info "Found Falcon namespaces: ${found_namespaces[*]}"
    return 1
}

# Show current Falcon deployment status
show_current_status() {
    log_info "Current Falcon Platform status:"
    echo "================================"

    # Show helm releases
    echo "Helm Releases:"
    helm list -n falcon-platform 2>/dev/null || echo "  No releases in falcon-platform namespace"
    echo

    # Show pods in falcon namespaces
    echo "Falcon Pods:"
    kubectl get pods -l app.kubernetes.io/instance=falcon-platform -A 2>/dev/null || echo "  No falcon-platform pods found"
    echo

    # Show namespaces
    echo "Falcon Namespaces:"
    local namespaces=("falcon-system" "falcon-kac" "falcon-image-analyzer" "falcon-platform")
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" &>/dev/null; then
            echo "  ✓ $ns"
        else
            echo "  ✗ $ns (not found)"
        fi
    done
    echo
}

# Confirm uninstallation
confirm_uninstall() {
    echo
    log_warning "⚠️  This will completely remove the CrowdStrike Falcon Platform from your cluster!"
    echo
    echo "This includes:"
    echo "  - Falcon Sensor (Node protection)"
    echo "  - Falcon Kubernetes Admission Controller"
    echo "  - Falcon Image Analyzer"
    echo "  - All associated namespaces and resources"
    echo

    read -p "Are you sure you want to continue? (type 'yes' to confirm): " -r
    if [[ "$REPLY" != "yes" ]]; then
        log_info "Uninstall cancelled by user"
        exit 0
    fi
    echo
}

# Uninstall Falcon Platform Helm release
uninstall_helm_release() {
    log_info "Removing Falcon Platform Helm release..."

    if helm list -n falcon-platform 2>/dev/null | grep -q falcon-platform; then
        if helm uninstall falcon-platform -n falcon-platform; then
            log_success "Falcon Platform Helm release removed"
        else
            log_error "Failed to remove Falcon Platform Helm release"
            return 1
        fi
    else
        log_info "No Falcon Platform Helm release found to remove"
    fi

    # Wait for pods to terminate
    log_info "Waiting for pods to terminate..."
    sleep 10

    # Check if any pods are still running
    local running_pods=$(kubectl get pods -l app.kubernetes.io/instance=falcon-platform -A --no-headers 2>/dev/null | wc -l || echo "0")
    if [[ "$running_pods" -gt 0 ]]; then
        log_warning "Some pods are still terminating, waiting additional 30 seconds..."
        sleep 30
    fi
}

# Remove namespaces
remove_namespaces() {
    log_info "Removing Falcon namespaces..."

    local namespaces=("falcon-system" "falcon-kac" "falcon-image-analyzer" "falcon-platform")

    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" &>/dev/null; then
            log_info "Removing namespace: $ns"
            kubectl delete namespace "$ns" --timeout=60s || {
                log_warning "Failed to delete namespace $ns within timeout"
                log_info "You may need to manually clean up resources in namespace $ns"
            }
        else
            log_info "Namespace $ns not found (already removed)"
        fi
    done
}

# Clean up any remaining resources
cleanup_remaining_resources() {
    log_info "Checking for remaining Falcon resources..."

    # Remove any remaining falcon-platform labeled resources
    local remaining_resources=$(kubectl get all -A -l app.kubernetes.io/instance=falcon-platform --no-headers 2>/dev/null | wc -l || echo "0")

    if [[ "$remaining_resources" -gt 0 ]]; then
        log_warning "Found remaining Falcon resources, attempting cleanup..."
        kubectl delete all -A -l app.kubernetes.io/instance=falcon-platform --timeout=60s || {
            log_warning "Some resources could not be automatically removed"
        }
    else
        log_success "No remaining Falcon resources found"
    fi

    # Check for any remaining CrowdStrike-related CRDs
    local falcon_crds=$(kubectl get crd 2>/dev/null | grep -i crowdstrike || true)
    if [[ -n "$falcon_crds" ]]; then
        log_info "Found CrowdStrike CRDs (these are typically shared and left intact):"
        echo "$falcon_crds"
    fi
}

# Verify uninstallation
verify_uninstall() {
    log_info "Verifying uninstallation..."

    local verification_failed=false

    # Check helm releases
    if helm list -A 2>/dev/null | grep -q falcon-platform; then
        log_warning "Falcon Platform Helm releases still found"
        helm list -A | grep falcon-platform
        verification_failed=true
    fi

    # Check namespaces
    local namespaces=("falcon-system" "falcon-kac" "falcon-image-analyzer" "falcon-platform")
    local remaining_namespaces=()

    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" &>/dev/null; then
            remaining_namespaces+=("$ns")
        fi
    done

    if [[ ${#remaining_namespaces[@]} -gt 0 ]]; then
        log_warning "Some Falcon namespaces still exist: ${remaining_namespaces[*]}"
        verification_failed=true
    fi

    # Check for remaining pods
    local remaining_pods=$(kubectl get pods -l app.kubernetes.io/instance=falcon-platform -A --no-headers 2>/dev/null | wc -l || echo "0")
    if [[ "$remaining_pods" -gt 0 ]]; then
        log_warning "Some Falcon pods are still running:"
        kubectl get pods -l app.kubernetes.io/instance=falcon-platform -A
        verification_failed=true
    fi

    if [[ "$verification_failed" == "true" ]]; then
        log_warning "Uninstallation verification found remaining resources"
        echo "You may need to manually clean up remaining resources"
        return 1
    else
        log_success "Uninstallation verification passed"
        return 0
    fi
}

# Print completion message
print_completion() {
    echo
    if verify_uninstall; then
        log_success "🎉 CrowdStrike Falcon Platform has been successfully removed!"
        echo
        echo "All components have been uninstalled:"
        echo "  ✅ Falcon Sensor"
        echo "  ✅ Falcon Kubernetes Admission Controller"
        echo "  ✅ Falcon Image Analyzer"
        echo "  ✅ All associated namespaces and resources"
    else
        log_warning "⚠️  Falcon Platform uninstall completed with warnings"
        echo
        echo "Please review the warnings above and manually clean up any remaining resources if needed"
    fi
    echo
}

# Main execution
main() {
    echo "🛡️  CrowdStrike Falcon Simple Uninstall Script"
    echo "============================================="
    echo

    check_prerequisites
    show_current_status

    # Check if anything is actually installed
    if check_falcon_installation; then
        # Nothing found to uninstall
        check_leftover_resources
        if [[ $? -eq 0 ]]; then
            log_success "No Falcon Platform installation or resources found"
            exit 0
        fi
    fi

    confirm_uninstall
    uninstall_helm_release
    remove_namespaces
    cleanup_remaining_resources
    print_completion
}

# Trap errors
trap 'log_error "Uninstall script failed at line $LINENO"' ERR

# Run main function
main "$@"