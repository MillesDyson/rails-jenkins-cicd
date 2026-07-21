// ---------------------------------------------------------------------------
// Pipeline declarativo (Pipeline as Code) para uma API Rails dockerizada.
//
// Fluxo: Checkout -> Build -> Qualidade (lint/SAST/audit) -> Testes (RSpec)
//        -> Scan da imagem (Trivy) -> Push no Docker Hub (só na branch main).
//
// Pré-requisitos no agente do Jenkins: docker + docker compose disponíveis.
// Credencial necessária no Jenkins: 'dockerhub-creds' (usuário/token do Docker Hub).
// ---------------------------------------------------------------------------
pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 30, unit: 'MINUTES')
  }

  environment {
    // TODO: ajuste para o seu usuário do Docker Hub.
    IMAGE     = 'docker.io/millesdyson/articles-api'
    TAG       = "${env.GIT_COMMIT?.take(7) ?: env.BUILD_NUMBER}"
    CI_IMAGE  = "articles-api:ci-${env.BUILD_NUMBER}"
    // Isola os containers de CI por build (evita conflito entre execuções).
    COMPOSE_PROJECT_NAME = "articlesci${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build') {
      steps {
        // Imagem de teste (com gems de dev/test) e imagem de produção enxuta.
        sh 'docker build --target test       -t $CI_IMAGE .'
        sh 'docker build --target production  -t $IMAGE:$TAG -t $IMAGE:latest .'
      }
    }

    stage('Qualidade') {
      parallel {
        stage('RuboCop (lint)') {
          steps { sh 'docker run --rm $CI_IMAGE bundle exec rubocop --format simple' }
        }
        stage('Brakeman (SAST)') {
          steps { sh 'docker run --rm $CI_IMAGE bundle exec brakeman -q --no-pager' }
        }
        stage('bundler-audit (deps)') {
          steps {
            sh 'docker run --rm $CI_IMAGE bash -lc "bundle exec bundle-audit update && bundle exec bundle-audit check"'
          }
        }
      }
    }

    stage('Testes (RSpec)') {
      steps {
        // Sobe Postgres efêmero + roda a suíte; --exit-code-from propaga a falha do RSpec.
        sh '''
          CI_IMAGE=$CI_IMAGE docker compose -f docker-compose.ci.yml up \
            --abort-on-container-exit --exit-code-from test
        '''
      }
      post {
        always {
          // Publica resultados dos testes e a cobertura, e derruba os containers.
          junit testResults: 'tmp/rspec.xml', allowEmptyResults: false
          archiveArtifacts artifacts: 'coverage/**', allowEmptyArchive: true, fingerprint: true
          sh 'docker compose -f docker-compose.ci.yml down -v || true'
        }
      }
    }

    stage('Scan da imagem (Trivy)') {
      steps {
        // Scan informativo de vulnerabilidades na imagem de produção.
        // Troque para "--exit-code 1" para FALHAR o build em HIGH/CRITICAL.
        sh '''
          docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy:latest image \
            --severity HIGH,CRITICAL --exit-code 0 --no-progress $IMAGE:$TAG
        '''
      }
    }

    stage('Push (Docker Hub)') {
      when { branch 'main' }
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                          usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''
            echo "$REG_PASS" | docker login docker.io -u "$REG_USER" --password-stdin
            docker push $IMAGE:$TAG
            docker push $IMAGE:latest
            docker logout docker.io
          '''
        }
      }
    }
  }

  post {
    always {
      // Limpa imagens de CI para não acumular disco no agente.
      sh 'docker rmi $CI_IMAGE || true'
    }
    success { echo "✅ Pipeline concluído. Imagem: ${IMAGE}:${TAG}" }
    failure { echo "❌ Pipeline falhou — verifique o estágio acima." }
  }
}
