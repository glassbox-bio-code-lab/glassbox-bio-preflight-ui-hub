SHELL := /bin/bash

ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PREFLIGHT_SOURCE_DIR ?= /home/weslinux/Desktop/marketplace_phase5_isolated-0.99.5-gbx-beta/marketplace_phase5_isolated-0.99.5-gbx-beta/preflight_v2
IPFTO_SOURCE_ROOT ?= /home/weslinux/Desktop/cbtri_local_proto_lite

K3D ?= k3d
DOCKER ?= docker
HELM ?= helm
KUBECTL ?= kubectl

K3D_CLUSTER ?= glassbox-preflight-local
NAMESPACE ?= glassbox-preflight
HELM_RELEASE ?= glassbox-preflight

LOCAL_PREFLIGHT_REPOSITORY ?= glassbox-local/preflight
LOCAL_PREFLIGHT_TAG ?= dev
LOCAL_IPFTO_REPOSITORY ?= glassbox-local/ipfto
LOCAL_IPFTO_TAG ?= dev

LOCAL_PREFLIGHT_IMAGE := $(LOCAL_PREFLIGHT_REPOSITORY):$(LOCAL_PREFLIGHT_TAG)
LOCAL_IPFTO_IMAGE := $(LOCAL_IPFTO_REPOSITORY):$(LOCAL_IPFTO_TAG)

LOCAL_VALUES := $(ROOT_DIR)/chart/preflight/values.local.yaml
IPFTO_VALUES := $(ROOT_DIR)/examples/preflight-values.ipfto.yaml
LOCAL_CORE_RUNNER_REF ?=
PORT_FORWARD_PORT ?= 8080
LOCAL_CORE_RUNNER_SET := $(if $(LOCAL_CORE_RUNNER_REF),--set-string app.runnerImage=$(LOCAL_CORE_RUNNER_REF))

.PHONY: help dev-k8s-up dev-k8s-down dev-k8s-reset dev-k8s-build-preflight \
	dev-k8s-build-ipfto dev-k8s-build-images dev-k8s-load-images dev-k8s-install \
	dev-k8s-upgrade dev-k8s-port-forward dev-k8s-logs dev-k8s-status \
	dev-k8s-uninstall

help:
	@echo "Local Kubernetes workflow for Glassbox Preflight UI Hub"
	@echo ""
	@echo "Cluster lifecycle:"
	@echo "  make dev-k8s-up"
	@echo "  make dev-k8s-down"
	@echo "  make dev-k8s-reset"
	@echo ""
	@echo "Image build and load:"
	@echo "  make dev-k8s-build-preflight"
	@echo "  make dev-k8s-build-ipfto"
	@echo "  make dev-k8s-build-images"
	@echo "  make dev-k8s-load-images"
	@echo ""
	@echo "Deployment:"
	@echo "  make dev-k8s-install"
	@echo "  make dev-k8s-upgrade"
	@echo "  make dev-k8s-port-forward"
	@echo "  make dev-k8s-logs"
	@echo "  make dev-k8s-status"
	@echo "  make dev-k8s-uninstall"
	@echo ""
	@echo "Defaults:"
	@echo "  PREFLIGHT_SOURCE_DIR=$(PREFLIGHT_SOURCE_DIR)"
	@echo "  IPFTO_SOURCE_ROOT=$(IPFTO_SOURCE_ROOT)"
	@echo "  K3D_CLUSTER=$(K3D_CLUSTER)"
	@echo "  NAMESPACE=$(NAMESPACE)"
	@echo "  HELM_RELEASE=$(HELM_RELEASE)"
	@echo "  LOCAL_PREFLIGHT_IMAGE=$(LOCAL_PREFLIGHT_IMAGE)"
	@echo "  LOCAL_IPFTO_IMAGE=$(LOCAL_IPFTO_IMAGE)"
	@echo ""
	@echo "Optional override:"
	@echo "  LOCAL_CORE_RUNNER_REF=<image-ref> make dev-k8s-install"
	@echo "  PORT_FORWARD_PORT=8081 make dev-k8s-port-forward"

dev-k8s-up:
	@command -v "$(K3D)" >/dev/null || { echo "ERROR: k3d is required for dev-k8s-up."; exit 2; }
	@command -v "$(KUBECTL)" >/dev/null || { echo "ERROR: kubectl is required for dev-k8s-up."; exit 2; }
	@if ! "$(K3D)" cluster list 2>/dev/null | awk 'NR>1 {print $$1}' | grep -Fxq "$(K3D_CLUSTER)"; then \
		"$(K3D)" cluster create "$(K3D_CLUSTER)" --servers 1 --agents 1 --wait; \
	else \
		echo "k3d cluster $(K3D_CLUSTER) already exists"; \
	fi
	@"$(KUBECTL)" create namespace "$(NAMESPACE)" --dry-run=client -o yaml | "$(KUBECTL)" apply -f -

dev-k8s-down:
	@command -v "$(K3D)" >/dev/null || { echo "ERROR: k3d is required for dev-k8s-down."; exit 2; }
	@if "$(K3D)" cluster list 2>/dev/null | awk 'NR>1 {print $$1}' | grep -Fxq "$(K3D_CLUSTER)"; then \
		"$(K3D)" cluster delete "$(K3D_CLUSTER)"; \
	else \
		echo "k3d cluster $(K3D_CLUSTER) does not exist"; \
	fi

dev-k8s-reset: dev-k8s-down dev-k8s-up

dev-k8s-build-preflight:
	@command -v "$(DOCKER)" >/dev/null || { echo "ERROR: docker is required for dev-k8s-build-preflight."; exit 2; }
	@test -f "$(PREFLIGHT_SOURCE_DIR)/Dockerfile" || { echo "ERROR: missing $(PREFLIGHT_SOURCE_DIR)/Dockerfile"; exit 2; }
	@"$(DOCKER)" build \
		-f "$(PREFLIGHT_SOURCE_DIR)/Dockerfile" \
		-t "$(LOCAL_PREFLIGHT_IMAGE)" \
		"$(PREFLIGHT_SOURCE_DIR)"

dev-k8s-build-ipfto:
	@command -v "$(DOCKER)" >/dev/null || { echo "ERROR: docker is required for dev-k8s-build-ipfto."; exit 2; }
	@test -f "$(IPFTO_SOURCE_ROOT)/ipfto_module/Dockerfile" || { echo "ERROR: missing $(IPFTO_SOURCE_ROOT)/ipfto_module/Dockerfile"; exit 2; }
	@"$(DOCKER)" build \
		-f "$(IPFTO_SOURCE_ROOT)/ipfto_module/Dockerfile" \
		-t "$(LOCAL_IPFTO_IMAGE)" \
		"$(IPFTO_SOURCE_ROOT)"

dev-k8s-build-images: dev-k8s-build-preflight dev-k8s-build-ipfto

dev-k8s-load-images:
	@command -v "$(K3D)" >/dev/null || { echo "ERROR: k3d is required for dev-k8s-load-images."; exit 2; }
	@if ! "$(K3D)" cluster list 2>/dev/null | awk 'NR>1 {print $$1}' | grep -Fxq "$(K3D_CLUSTER)"; then \
		echo "ERROR: k3d cluster $(K3D_CLUSTER) does not exist. Run 'make dev-k8s-up' first."; \
		exit 2; \
	fi
	@"$(K3D)" image import -c "$(K3D_CLUSTER)" "$(LOCAL_PREFLIGHT_IMAGE)" "$(LOCAL_IPFTO_IMAGE)"

dev-k8s-install: dev-k8s-up dev-k8s-build-images dev-k8s-load-images
	@command -v "$(HELM)" >/dev/null || { echo "ERROR: helm is required for dev-k8s-install."; exit 2; }
	@"$(HELM)" upgrade --install "$(HELM_RELEASE)" "$(ROOT_DIR)/chart/preflight" \
		--namespace "$(NAMESPACE)" \
		--create-namespace \
		--wait \
		--timeout 10m \
		-f "$(LOCAL_VALUES)" \
		-f "$(IPFTO_VALUES)" \
		--set-string image.repository="$(LOCAL_PREFLIGHT_REPOSITORY)" \
		--set-string image.tag="$(LOCAL_PREFLIGHT_TAG)" \
		--set-string app.ipftoRunnerImage="$(LOCAL_IPFTO_IMAGE)" \
		--set-string addons.ipfto.image.repository="$(LOCAL_IPFTO_REPOSITORY)" \
		--set-string addons.ipfto.image.tag="$(LOCAL_IPFTO_TAG)" $(LOCAL_CORE_RUNNER_SET)

dev-k8s-upgrade: dev-k8s-install

dev-k8s-port-forward:
	@command -v "$(KUBECTL)" >/dev/null || { echo "ERROR: kubectl is required for dev-k8s-port-forward."; exit 2; }
	@"$(KUBECTL)" -n "$(NAMESPACE)" port-forward deploy/"$(HELM_RELEASE)" "$(PORT_FORWARD_PORT)":8080

dev-k8s-logs:
	@command -v "$(KUBECTL)" >/dev/null || { echo "ERROR: kubectl is required for dev-k8s-logs."; exit 2; }
	@"$(KUBECTL)" -n "$(NAMESPACE)" logs deploy/"$(HELM_RELEASE)" --tail=200

dev-k8s-status:
	@command -v "$(KUBECTL)" >/dev/null || { echo "ERROR: kubectl is required for dev-k8s-status."; exit 2; }
	@"$(KUBECTL)" -n "$(NAMESPACE)" get pods,svc,deployments,jobs,configmaps,serviceaccounts

dev-k8s-uninstall:
	@command -v "$(HELM)" >/dev/null || { echo "ERROR: helm is required for dev-k8s-uninstall."; exit 2; }
	@"$(HELM)" uninstall "$(HELM_RELEASE)" --namespace "$(NAMESPACE)" || true
