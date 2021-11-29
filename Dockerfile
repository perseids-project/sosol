FROM jruby:9.2.20

RUN apt-get update && apt-get install -y git

RUN mkdir /app
WORKDIR /app

ENV JRUBY_OPTS=-"J-Xmx4g"
RUN gem install bundler:1.15.1

COPY Gemfile /app/Gemfile
COPY .ruby-version /app/.ruby-version
COPY Gemfile.lock /app/Gemfile.lock

RUN bundle install

COPY . /app
