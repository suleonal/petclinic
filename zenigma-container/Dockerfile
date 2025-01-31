FROM ubuntu:latest

WORKDIR /app

COPY zenigma_logger.sh zenigma_killer.sh entrypoint.sh ./
RUN chmod +x zenigma_logger.sh zenigma_killer.sh entrypoint.sh

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]

