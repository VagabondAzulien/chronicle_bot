FROM ruby:2.7-alpine

RUN bundle config --global frozen 1
RUN apk add build-base sqlite sqlite-dev sqlite-libs

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["bundle", "exec", "rake", "chronicle:start"]
