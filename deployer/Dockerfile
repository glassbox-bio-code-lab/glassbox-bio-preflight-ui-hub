ARG DEPLOYER_BASE_IMAGE=gcr.io/cloud-marketplace-tools/k8s/deployer_helm:0.12.12
# Go 1.25.10 includes current Go stdlib CVE fixes required by Artifact Analysis.
ARG GOLANG_BUILD_IMAGE=golang:1.25.10
ARG HELM_VERSION=v3.20.1
ARG KUBECTL_130_VERSION=v1.30.14
ARG KUBECTL_131_VERSION=v1.31.14
ARG MP_SERVICE_NAME=services/glassbox-bio-preflight-ui-hub.endpoints.glassbox-bio-public.cloud.goog

FROM ${GOLANG_BUILD_IMAGE} AS kubectl-130-builder
ARG KUBECTL_130_VERSION
WORKDIR /src
RUN curl -fsSLo kubernetes-src.tar.gz "https://github.com/kubernetes/kubernetes/archive/refs/tags/${KUBECTL_130_VERSION}.tar.gz" \
    && tar -xzf kubernetes-src.tar.gz --strip-components=1 \
    && /usr/local/go/bin/go mod edit -require=golang.org/x/net@v0.38.0 -require=golang.org/x/oauth2@v0.27.0 -require=github.com/moby/spdystream@v0.5.1 \
    && /usr/local/go/bin/go work vendor \
    && /usr/local/go/bin/go list -mod=vendor -m github.com/moby/spdystream | grep 'v0\.5\.1$' \
    && PATH=/usr/local/go/bin:$PATH make kubectl KUBE_VERBOSE=0 \
    && install -D _output/local/go/bin/kubectl /out/kubectl

FROM ${GOLANG_BUILD_IMAGE} AS kubectl-131-builder
ARG KUBECTL_131_VERSION
WORKDIR /src
RUN curl -fsSLo kubernetes-src.tar.gz "https://github.com/kubernetes/kubernetes/archive/refs/tags/${KUBECTL_131_VERSION}.tar.gz" \
    && tar -xzf kubernetes-src.tar.gz --strip-components=1 \
    && /usr/local/go/bin/go mod edit -require=golang.org/x/net@v0.38.0 -require=golang.org/x/oauth2@v0.27.0 -require=github.com/moby/spdystream@v0.5.1 \
    && /usr/local/go/bin/go work vendor \
    && /usr/local/go/bin/go list -mod=vendor -m github.com/moby/spdystream | grep 'v0\.5\.1$' \
    && PATH=/usr/local/go/bin:$PATH make kubectl KUBE_VERBOSE=0 \
    && install -D _output/local/go/bin/kubectl /out/kubectl

FROM ${GOLANG_BUILD_IMAGE} AS helm-builder
ARG HELM_VERSION
WORKDIR /src
RUN curl -fsSLo helm-src.tar.gz "https://github.com/helm/helm/archive/refs/tags/${HELM_VERSION}.tar.gz" \
    && tar -xzf helm-src.tar.gz --strip-components=1 \
    && /usr/local/go/bin/go mod edit -require=google.golang.org/grpc@v1.79.3 \
    && /usr/local/go/bin/go get google.golang.org/grpc@v1.79.3 google.golang.org/protobuf@v1.36.10 golang.org/x/oauth2@v0.34.0 \
    && CGO_ENABLED=0 /usr/local/go/bin/go build -trimpath -ldflags="-s -w" -o /out/helm ./cmd/helm

FROM ${DEPLOYER_BASE_IMAGE}
ARG HELM_VERSION
ARG KUBECTL_130_VERSION
ARG KUBECTL_131_VERSION
ARG MP_SERVICE_NAME
LABEL com.googleapis.cloudmarketplace.product.service.name=${MP_SERVICE_NAME}

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && . /etc/os-release \
    && for package_name in libssl3 openssl; do \
         if dpkg-query -W -f='${Version}' "${package_name}" >/tmp/"${package_name}".version 2>/dev/null; then \
           package_version="$(cat /tmp/"${package_name}".version)"; \
           if [ "${ID:-}" = "debian" ] && [ "${VERSION_CODENAME:-}" = "bookworm" ]; then \
             dpkg --compare-versions "${package_version}" ge "3.0.19-1~deb12u2"; \
             echo "Debian bookworm ${package_name} validation ok: ${package_version}"; \
           else \
             echo "${package_name} present on ${PRETTY_NAME:-non-Debian-bookworm base}: ${package_version}"; \
           fi; \
         else \
           echo "${package_name} is not installed in the deployer image"; \
         fi; \
       done \
    && apt-get install -y --no-install-recommends python3-pip \
    && python3 -m pip install --no-cache-dir --upgrade "cryptography>=46.0.7,<47" "pyOpenSSL>=26,<27" \
    && python3 -c 'import importlib.metadata as m; v=m.version("cryptography"); assert tuple(map(int, v.split(".")[:3])) >= (46, 0, 7), v; print("cryptography validation ok:", v)' \
    && apt-get purge -y python3-pip wget gnupg2 \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/libssl3.version /tmp/openssl.version

COPY --from=kubectl-130-builder /out/kubectl /opt/kubectl/1.30/kubectl
COPY --from=kubectl-131-builder /out/kubectl /opt/kubectl/1.31/kubectl
COPY --from=helm-builder /out/helm /usr/bin/helm

RUN chmod 0755 /opt/kubectl/1.30/kubectl /opt/kubectl/1.31/kubectl /usr/bin/helm \
    && ln -snf /opt/kubectl/1.31 /opt/kubectl/default

RUN mkdir -p /data/chart /data-test/chart

COPY chart/preflight/ /tmp/marketplace-main/chart/
RUN tar -czf /data/chart/chart-bundle.tar.gz -C /tmp/marketplace-main chart \
    && rm -rf /tmp/marketplace-main
COPY schema.yaml /data/schema.yaml

COPY apptest/deployer/preflight/values.yaml /tmp/marketplace-test/chart/values.yaml
RUN tar -czf /data-test/chart/chart-bundle.tar.gz -C /tmp/marketplace-test chart \
    && rm -rf /tmp/marketplace-test
COPY apptest/deployer/schema.yaml /data-test/schema.yaml
COPY deployer/marketplace-debug-deploy.sh /usr/local/bin/marketplace-debug-deploy.sh
RUN chmod 0755 /usr/local/bin/marketplace-debug-deploy.sh

ENV SCHEMA=/data/schema.yaml
ENV WAIT_FOR_READY_TIMEOUT=1800
ENV TESTER_TIMEOUT=1800

ENTRYPOINT ["/usr/local/bin/marketplace-debug-deploy.sh"]
