# Articles API — CI/CD com Jenkins 🚀

API REST em **Ruby on Rails** (modo API-only), **dockerizada** e com um **pipeline de CI/CD completo no Jenkins**. O objetivo do projeto é demonstrar, de ponta a ponta, as boas práticas de mercado para integração e entrega contínuas: build de imagem, análise estática, testes automatizados, scan de segurança e publicação de imagem em registry.

> A aplicação em si é propositalmente simples (um CRUD de `Article`). O foco do portfólio é o **fluxo de CI/CD** e a **qualidade de engenharia** ao redor dela.

---

## 🧱 Stack

| Camada        | Tecnologia                                             |
|---------------|--------------------------------------------------------|
| Linguagem     | Ruby 3.3                                               |
| Framework     | Rails 8.1 (API-only)                                   |
| Banco         | PostgreSQL 16                                          |
| Testes        | RSpec, FactoryBot, shoulda-matchers, SimpleCov         |
| Qualidade     | RuboCop (lint), Brakeman (SAST), bundler-audit         |
| Container     | Docker (multi-stage), Docker Compose                   |
| CI/CD         | Jenkins (Pipeline as Code — `Jenkinsfile` declarativo) |
| Segurança img | Trivy                                                  |
| Registry      | Docker Hub                                             |

---

## 🔁 O pipeline de CI/CD

O `Jenkinsfile` define o pipeline como código. Fluxo por estágio:

```
┌───────────┐   ┌────────┐   ┌──────────────────────────────┐   ┌──────────────┐   ┌───────────┐   ┌──────────────┐
│ Checkout  │──▶│ Build  │──▶│ Qualidade (paralelo)         │──▶│ Testes       │──▶│ Trivy     │──▶│ Push         │
│           │   │ imagens│   │ • RuboCop  (lint)            │   │ RSpec +      │   │ scan da   │   │ Docker Hub   │
│           │   │ test + │   │ • Brakeman (SAST)            │   │ PostgreSQL   │   │ imagem    │   │ (só na main) │
│           │   │ prod   │   │ • bundler-audit (deps)       │   │ + cobertura  │   │           │   │              │
└───────────┘   └────────┘   └──────────────────────────────┘   └──────────────┘   └───────────┘   └──────────────┘
```

- **Build** — usa o `Dockerfile` multi-stage: um alvo `test` (com gems de dev/test) e um alvo `production` (imagem enxuta, non-root).
- **Qualidade** — três checagens rodam **em paralelo** para acelerar o feedback.
- **Testes** — sobe um PostgreSQL efêmero via `docker-compose.ci.yml`, roda o RSpec e publica **relatório JUnit** + **cobertura** (falha se cobertura < 90%).
- **Trivy** — scan de vulnerabilidades da imagem (informativo por padrão; ajustável para bloquear).
- **Push** — publica a imagem no Docker Hub **apenas na branch `main`**.

---

## ▶️ Rodando localmente (desenvolvimento)

Pré-requisitos: **Docker** e **Docker Compose**. (Não é preciso ter Ruby instalado.)

```bash
# 1. Gere o arquivo .env com a master key do Rails
echo "RAILS_MASTER_KEY=$(cat config/master.key)" > .env

# 2. Suba a API + PostgreSQL
docker compose up --build

# 3. Em outro terminal, teste os endpoints
curl localhost:3000/up                      # health check → 200
curl localhost:3000/articles                # lista de artigos (JSON)
curl -X POST localhost:3000/articles \
     -H "Content-Type: application/json" \
     -d '{"article":{"title":"Olá mundo","body":"Meu primeiro artigo","published":true}}'
```

### Endpoints

| Método | Rota             | Descrição                    |
|--------|------------------|------------------------------|
| GET    | `/up`            | Health check (200/500)       |
| GET    | `/articles`      | Lista artigos                |
| GET    | `/articles/:id`  | Detalha um artigo            |
| POST   | `/articles`      | Cria um artigo               |
| PATCH  | `/articles/:id`  | Atualiza um artigo           |
| DELETE | `/articles/:id`  | Remove um artigo             |

---

## 🧪 Rodando os testes

O mesmo fluxo que o Jenkins usa, reproduzível na sua máquina:

```bash
# Constrói a imagem de teste (com todas as gems)
docker build --target test -t articles-api:ci .

# Roda o RSpec com um PostgreSQL efêmero (gera cobertura em coverage/)
CI_IMAGE=articles-api:ci docker compose -f docker-compose.ci.yml up \
  --abort-on-container-exit --exit-code-from test

# Lint, SAST e auditoria de dependências
docker run --rm articles-api:ci bundle exec rubocop
docker run --rm articles-api:ci bundle exec brakeman -q
docker run --rm articles-api:ci bash -lc "bundle exec bundle-audit update && bundle exec bundle-audit check"
```

Resultado esperado: **23 exemplos, 0 falhas, cobertura 100%**.

---

## 🛠️ Subindo o Jenkins localmente

O diretório `jenkins/` traz um Jenkins já com o Docker CLI embutido, pronto para executar o pipeline.

```bash
cd jenkins
docker compose up --build -d

# Senha inicial de administrador:
docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Acesse **http://localhost:8080** e conclua o setup inicial.

### Configurando o pipeline

1. **Credencial do Docker Hub**
   *Manage Jenkins → Credentials → System → Global* → *Add Credentials*
   - Kind: **Username and password**
   - Username: seu usuário do Docker Hub
   - Password: um **access token** do Docker Hub (não use a senha)
   - ID: **`dockerhub-creds`** (o `Jenkinsfile` referencia exatamente esse ID)

2. **Ajuste o seu usuário no `Jenkinsfile`**
   Altere a variável `IMAGE` para `docker.io/<seu-usuario>/articles-api`.

3. **Crie o job**
   *New Item → Pipeline* → em *Pipeline*, selecione **Pipeline script from SCM**, aponte para o repositório Git e o script `Jenkinsfile`.

4. **Rode o build** — o pipeline executa todos os estágios; o push só ocorre na branch `main`.

> **Nota de segurança (lab):** o Jenkins roda como `root` e monta o socket do Docker do host para simplificar o ambiente local. Em produção, use agentes dedicados com permissões restritas em vez de expor o socket do host.

---

## ✅ Boas práticas demonstradas

- **Pipeline as Code** — todo o CI/CD versionado no `Jenkinsfile`.
- **Dockerfile multi-stage** — imagem de produção enxuta (~450 MB), rodando como usuário **não-root**.
- **Configuração por variáveis de ambiente** — `database.yml` parametrizado (12-factor).
- **Segredos fora do código** — `master.key` e credenciais nunca versionados; Docker Hub via credenciais do Jenkins.
- **Testes automatizados** — model specs e request specs, com **gate de cobertura mínima** (90%).
- **Shift-left security** — Brakeman (SAST), bundler-audit (dependências) e Trivy (imagem).
- **Feedback rápido** — estágios de qualidade em **paralelo**.
- **Relatórios integrados** — JUnit e cobertura publicados no Jenkins.
- **Dependabot** — atualizações automáticas de gems e imagens Docker.
- **Schema versionado** — `db/schema.rb` no controle de versão.

---

## 📁 Estrutura

```
rails-jenkins-cicd/
├── app/                     # código da aplicação (model, controller)
├── spec/                    # testes RSpec (model, request, factories)
├── config/                  # configuração do Rails (database.yml parametrizado)
├── db/                      # migrations, schema.rb, seeds
├── Dockerfile               # multi-stage: alvos "test" e "production"
├── docker-compose.yml       # ambiente de dev/demo (API + PostgreSQL)
├── docker-compose.ci.yml    # ambiente efêmero de testes usado pelo CI
├── Jenkinsfile              # pipeline declarativo de CI/CD
├── jenkins/                 # Jenkins em Docker (rodável localmente)
│   ├── Dockerfile
│   └── docker-compose.yml
├── .rubocop.yml             # regras de lint
├── .github/dependabot.yml   # atualização automática de dependências
└── README.md
```

---

## 📌 Próximos passos (ideias de evolução)

- Adicionar autenticação (JWT) e autorização.
- Publicar métricas de cobertura como badge.
- Deploy automático (staging) após o push da imagem.
- Notificações do pipeline (Slack/Discord).
- Migrar o mesmo fluxo para GitHub Actions e comparar as abordagens.
