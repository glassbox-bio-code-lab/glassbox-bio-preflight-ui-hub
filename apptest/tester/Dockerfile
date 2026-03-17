FROM debian:12-slim

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
