FROM ruby:2.2.2

RUN apt-get update && apt-get upgrade -y && apt-get install -y build-essential
RUN apt-get install -y nodejs sqlite3 less

ENV APP_HOME /wrestlingApp
ENV PORT 3000

RUN mkdir $APP_HOME

WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
RUN bundle install

ADD . $APP_HOME

RUN bundle exec spring binstub --all

RUN rake db:drop
RUN rake db:migrate RAILS_ENV=test
RUN rake db:migrate RAILS_ENV=development
RUN rake db:seed
RUN rake assets:precompile
RUN rake test

# Pull binstub from image when doing prod deployments
# RUN bundle exec spring binstub --remove --all

#CMD rails s puma --binding 0.0.0.0
CMD bundle exec passenger start -p $PORT --max-pool-size 3

EXPOSE 3000
