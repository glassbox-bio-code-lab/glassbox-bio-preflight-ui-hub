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
    && rm -rf /var/lib/apt/lists/*

COPY tests/basic-suite.yaml /tests/basic-suite.yaml
COPY tester.sh /tester.sh
RUN chmod +x /tester.sh

WORKDIR /
ENTRYPOINT ["/tester.sh"]
