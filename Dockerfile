FROM ruby:3.1.2

RUN apt-get update -yq \
  && apt-get upgrade -yq \
  #ESSENTIALS
  && apt-get install -y -qq --no-install-recommends build-essential curl git-core vim passwd unzip cron gcc wget netcat \
  # RAILS PACKAGES NEEDED
  && apt-get update \
  && apt-get install -y --no-install-recommends imagemagick postgresql-client \
  # INSTALL NODE
  && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  # INSTALL YARN
  && npm install -g yarn

# Clean cache and temp files, fix permissions
RUN apt-get clean -qy \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /app
WORKDIR /app

COPY package.json yarn.lock
RUN yarn install

# install specific version of bundler
RUN gem install bundler -v 2.2.32

ENV BUNDLE_GEMFILE=/app/Gemfile \
  BUNDLE_JOBS=20 \
  BUNDLE_PATH=/bundle \
  BUNDLE_BIN=/bundle/bin \
  GEM_HOME=/bundle
ENV PATH="${BUNDLE_BIN}:${PATH}"

COPY Gemfile Gemfile.lock ./
RUN bundle install --binstubs --without development test

COPY . .

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES 1
ENV RAILS_LOG_TO_STDOUT 1

RUN SECRET_KEY_BASE=skb DB_ADAPTER=nulldb bundle exec rails assets:precompile

RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 3000
CMD bundle exec puma -C config/puma.rb
