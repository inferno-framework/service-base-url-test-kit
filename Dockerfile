FROM ruby:3.3.6

ENV INSTALL_PATH=/opt/inferno/
ENV APP_ENV=production
RUN mkdir -p $INSTALL_PATH

WORKDIR $INSTALL_PATH


# Included for convenience for MITRE employees
# Should not affect usage outside the MITRE network but should be removed when published
RUN curl -ksSL https://gitlab.mitre.org/mitre-scripts/mitre-pki/raw/master/os_scripts/install_certs.sh | MODE=ubuntu sh

ADD *.gemspec $INSTALL_PATH
ADD Gemfile* $INSTALL_PATH
ADD lib/service_base_url_test_kit/version.rb $INSTALL_PATH/lib/service_base_url_test_kit/version.rb
RUN gem install bundler
# The below RUN line is commented out for development purposes, because any change to the 
# required gems will break the dockerfile build process.
# If you want to run in Deploy mode, just run `bundle install` locally to update 
# Gemfile.lock, and uncomment the following line.
# RUN bundle config set --local deployment 'true'
RUN bundle install

ADD . $INSTALL_PATH

EXPOSE 4567
CMD ["bundle", "exec", "puma"]
