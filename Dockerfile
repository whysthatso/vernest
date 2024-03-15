ARG RUBY_VERSION=3.3.0
FROM registry.docker.com/library/ruby:$RUBY_VERSION-alpine3.18

ENV APP_ENV=production
WORKDIR /app

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
    git

RUN mkdir -p /usr/local/etc \
    && { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
    } >> /usr/local/etc/gemrc

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs=4 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

RUN addgroup -S sinatra && adduser -S sinatra -G sinatra && \
    chown -R sinatra:sinatra db
USER sinatra:sinatra

EXPOSE 4567

CMD ["ruby", "vernest.rb"]
