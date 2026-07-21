# Jenkins LTS com:
#   - Docker CLI + compose (para o pipeline rodar `docker build`/`docker compose`)
#   - JCasC (Jenkins Configuration as Code): admin, credenciais e job vêm de arquivo
#   - setup wizard desativado (nada de configuração manual na primeira subida)
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

USER jenkins

# Instala os plugins a partir do arquivo (inclui configuration-as-code e job-dsl).
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Desativa o assistente de setup inicial e aponta o JCasC para o nosso arquivo.
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV CASC_JENKINS_CONFIG=/var/jenkins_conf/casc.yaml
COPY casc.yaml /var/jenkins_conf/casc.yaml
