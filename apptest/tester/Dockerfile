ARG MP_SERVICE_NAME=services/glassbox-bio-preflight-ui-hub.endpoints.glassbox-bio-public.cloud.goog

FROM debian:12-slim

ARG MP_SERVICE_NAME
LABEL com.googleapis.cloudmarketplace.product.service.name=${MP_SERVICE_NAME}

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      jq \
    && for package_name in libssl3 openssl; do \
         if dpkg-query -W -f='${Version}' "${package_name}" >/tmp/"${package_name}".version 2>/dev/null; then \
           package_version="$(cat /tmp/"${package_name}".version)"; \
           dpkg --compare-versions "${package_version}" ge "3.0.19-1~deb12u2"; \
           echo "${package_name} validation ok: ${package_version}"; \
         else \
           echo "${package_name} is not installed in the tester image"; \
         fi; \
       done \
    && rm -rf /var/lib/apt/lists/* /tmp/libssl3.version /tmp/openssl.version

COPY tests/basic-suite.yaml /tests/basic-suite.yaml
COPY tester.sh /tester.sh
RUN chmod +x /tester.sh

WORKDIR /
ENTRYPOINT ["/tester.sh"]
