# syntax=docker/dockerfile:1
# ---------------------------------------------------------------------------
# Dockerfile multi-stage.
#   target "test"       -> imagem com TODAS as gems, usada pelo CI (RSpec/RuboCop/Brakeman)
#   target "production"  -> imagem final enxuta, sem gems de dev/test, non-root
# Build padrão (`docker build .`) gera a imagem de produção.
# ---------------------------------------------------------------------------
ARG RUBY_VERSION=3.3.12

########################## base ##########################
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS base
WORKDIR /rails
# Pacotes de runtime (cliente postgres p/ db:prepare, libvips p/ imagens, jemalloc p/ memória)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
ENV BUNDLE_PATH="/usr/local/bundle"

######################## build-deps ######################
# Estágio com toolchain de compilação (gems nativas como pg precisam dele).
FROM base AS build-deps
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
COPY Gemfile Gemfile.lock ./

########################## test ##########################
# Instala TODAS as gems (dev + test). Usada pelo pipeline para lint/SAST/RSpec.
FROM build-deps AS test
ENV RAILS_ENV=test
RUN bundle install
COPY . .
CMD ["bundle", "exec", "rspec"]

######################## build-prod ######################
# Instala apenas as gems de produção e pré-compila o bootsnap.
FROM build-deps AS build-prod
ENV RAILS_ENV=production
RUN bundle config set --local without "development test" && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile
COPY . .
RUN bundle exec bootsnap precompile app/ lib/

####################### production #######################
# Imagem final: só o necessário para rodar em produção.
FROM base AS production
ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1
COPY --from=build-prod "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build-prod /rails /rails

# Usuário não-root (boa prática de segurança em produção)
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# O entrypoint prepara o banco (db:prepare) antes de subir o servidor.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["./bin/rails", "server"]
