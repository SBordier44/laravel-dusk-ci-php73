FROM ubuntu:18.04
LABEL maintainer="lsfiege@gmail.com"

RUN apt-get update \
    && apt-get install -y locales \
    && locale-gen es_AR.UTF-8

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV LC_ALL es_AR.UTF-8
ENV LANG es_AR.UTF-8
ENV LANGUAGE es_AR:es
ENV DISPLAY :99
ENV SCREEN_RESOLUTION 1920x720x24
ENV CHROMEDRIVER_PORT 9515
ENV PATH="${PATH}:/root/.composer/vendor/bin"
ENV TMPDIR=/tmp

RUN apt-get update -y && apt-get install -y wget curl zip unzip git software-properties-common \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update -y \
    && apt-get install -yq apt-utils zip unzip \
    && apt-get install -yq openssl language-pack-es-base \
    && sed -i'' 's/archive\.ubuntu\.com/us\.archive\.ubuntu\.com/' /etc/apt/sources.list \
    && apt-get update \
    && apt-get upgrade -yq \
    && apt-get install -yq libgd-tools \
    && apt-get install -yq --fix-missing php7.3-fpm php7.3-cli php7.3-xml php7.3-zip php7.3-curl php7.3-bcmath php7.3-json php7.3-imap php-memcached \
    php7.3-mbstring php7.3-pgsql php7.3-mysql php7.3-gd php-imagick imagemagick nginx \
    && apt-get install -yq mc lynx mysql-client bzip2 make g++ \
    && php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer 

ADD commands/xvfb.init.sh /etc/init.d/xvfb 

ADD commands/start-nginx-ci-project.sh /usr/bin/start-nginx-ci-project

ADD configs/.bowerrc /root/.bowerrc

RUN chmod +x /usr/bin/start-nginx-ci-project
ADD commands/configure-laravel.sh /usr/bin/configure-laravel
RUN chmod +x /usr/bin/configure-laravel

RUN \
  apt-get install -yq xvfb gconf2 fonts-ipafont-gothic xfonts-cyrillic xfonts-100dpi xfonts-75dpi xfonts-base \
    xfonts-scalable \
  && chmod +x /etc/init.d/xvfb \
  && CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` \
  && mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION \
  && curl -sS -o /tmp/chromedriver_linux64.zip \
    http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip \
  && unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver-$CHROMEDRIVER_VERSION \
  && rm /tmp/chromedriver_linux64.zip \
  && chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver \
  && ln -fs /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver /usr/local/bin/chromedriver \
  && curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get -yqq update && apt-get -yqq install google-chrome-stable x11vnc

RUN apt-get update \
    && apt-get install -yq apt-transport-https python3-software-properties build-essential \
    && curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && apt-get install -yq nodejs

#RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
#RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
#RUN apt-get update && apt-get install -yq yarn
#RUN yarn global add bower --network-concurrency 1

RUN wget https://phar.phpunit.de/phpunit.phar \
    && chmod +x phpunit.phar \
    && mv phpunit.phar /usr/local/bin/phpunit \
    && apt-get install -y supervisor libpng-dev jpegoptim optipng pngquant gifsicle

#RUN npm install -g node-gyp && npm install -g node-sass && npm install -g gulp

ADD configs/supervisord.conf /etc/supervisor/supervisord.conf

ADD configs/nginx-default-site /etc/nginx/sites-available/default 

VOLUME [ "/var/log/supervisor" ]

RUN composer global require laravel/envoy --no-progress --no-suggest

RUN apt-get -yq clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && apt-get upgrade && apt-get autoremove \
    && php --version \
    && composer --version \
    && nginx -v \
    && phpunit --version \
    && nodejs --version \
    && npm --version \
    && envoy -V
    #&& node-sass --version \
    #&& gulp --version
#RUN yarn --version
#RUN bower --version

EXPOSE 80 9515 3306

WORKDIR /var/www/html/

#CMD ["php7.3-fpm", "-g", "daemon off;"]
CMD ["nginx", "-g", "daemon off;"]
