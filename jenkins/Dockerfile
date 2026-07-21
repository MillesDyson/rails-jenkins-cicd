# Jenkins LTS com o CLI do Docker + compose embutidos, para que o pipeline
# consiga executar `docker build` / `docker compose` usando o socket do host
# (padrão "Docker-outside-of-Docker").
FROM jenkins/jenkins:lts-jdk21

USER root

# Instala o CLI do Docker e o plugin do compose a partir do repositório oficial.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# Plugins essenciais já embutidos (evita configuração manual na primeira subida).
RUN jenkins-plugin-cli --plugins \
    "workflow-aggregator docker-workflow git junit credentials-binding timestamper"

USER jenkins
