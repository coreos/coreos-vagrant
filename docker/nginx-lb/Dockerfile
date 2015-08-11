FROM nginx:latest
MAINTAINER Kuo-Cheng Yeu <kmd@mikuru.tw>

ENV DEBIAN_FRONTEND noninteractive

# Silently install basic packages
RUN apt-get -qq update && apt-get -qqy install \ 
    nginx \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* \
&& mkdir -p /usr/local/bin \
&& mkdir -p /etc/confd/{conf.d,templates} \
&& rm /etc/nginx/conf.d/default.conf

# add confd
ADD https://github.com/kelseyhightower/confd/releases/download/v0.10.0/confd-0.10.0-linux-amd64 /usr/local/bin/confd

# add template, config, and script
ADD assets/nginx.toml /etc/confd/conf.d/nginx.toml
ADD assets/nginx.tmpl /etc/confd/templates/nginx.tmpl
ADD assets/confd-watch /usr/local/bin/confd-watch

RUN chmod +x /usr/local/bin/*

CMD ["bash"]


