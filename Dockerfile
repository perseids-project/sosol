FROM jruby:9.2.20

RUN apt-get update && apt-get install -y git

RUN mkdir /app
WORKDIR /app

ARG JRUBY_OPTS=-"J-Xmx4g"
RUN gem install bundler:1.15.1

COPY . /app

RUN bundle install --local
RUN bundle exec cap local externals:setup
