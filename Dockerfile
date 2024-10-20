#
# Dockerfile for alpine-linux-rc-nginx-php83 mikrotik-docker-image
# (C) 2023-2024 DL7DET
#

ARG ALPINE_VERSION
FROM --platform=$TARGETPLATFORM $ALPINE_VERSION AS base

# Preset Metadata parameters and build-arg parameters
ARG BUILD
ARG PROD_VERSION
ARG DEVEL_VERSION
ARG ALPINE_VERSION
ARG LINUX_VERSION
ARG COMMIT_SHA
ENV HOME=/home/$USER

# Set Metadata for docker-image
LABEL org.opencontainers.image.authors="DL7DET <detlef@lampart.de>" 
LABEL org.opencontainers.image.licenses="MIT License"
LABEL org.label-schema.vendor="DL7DET <detlef@lampart.de>"
LABEL org.label-schema.name="mikrotik-alp_rc_nginx_php83"
LABEL org.label-schema.url="https://cb3.lampart-web.de/internal/docker-projects/mikrotik-docker-images/mikrotik-alp_rc_nginx_php83"  
LABEL org.label-schema.version=$LINUX_VERSION-$PROD_VERSION 
LABEL org.label-schema.version-prod=$PROD_VERSION 
LABEL org.label-schema.version-devel=$DEVEL_VERSION 
LABEL org.label-schema.build-date=$BUILD 
LABEL org.label-schema.version_alpine_version=$ALPINE_VERSION 
LABEL org.label-schema.vcs-url="https://cb3.lampart-web.de/internal/docker-projects/mikrotik-docker-images/mikrotik-alp_rc_nginx_php83.git" 
LABEL org.label-schema.vcs-ref=$COMMIT_SHA 
LABEL org.label-schema.docker.dockerfile="/Dockerfile" 
LABEL org.label-schema.description="alpine-linux-rc-nginx-php83 mikrotik-docker-image" 
LABEL org.label-schema.usage="N.N." 
LABEL org.label-schema.url="N.N." 
LABEL org.label-schema.schema-version="1.0"

RUN echo 'https://ftp.halifax.rwth-aachen.de/alpine/v3.20/main/' >> /etc/apk/repositories \
    && echo 'https://ftp.halifax.rwth-aachen.de/alpine/v3.20/community' >> /etc/apk/repositories \
    && apk add --no-cache --update --upgrade su-exec ca-certificates

FROM base AS openrc

RUN apk add --no-cache openrc \
    # Disable getty's
    && sed -i 's/^\(tty\d\:\:\)/#\1/g' /etc/inittab \
    && sed -i \
        # Change subsystem type to "docker"
        -e 's/#rc_sys=".*"/rc_sys="docker"/g' \
        # Allow all variables through
        -e 's/#rc_env_allow=".*"/rc_env_allow="\*"/g' \
        # Start crashed services
        -e 's/#rc_crashed_stop=.*/rc_crashed_stop=NO/g' \
        -e 's/#rc_crashed_start=.*/rc_crashed_start=YES/g' \
        # Define extra dependencies for services
        -e 's/#rc_provide=".*"/rc_provide="loopback net"/g' \
        /etc/rc.conf \
    # Remove unnecessary services
    && rm -f /etc/init.d/hwdrivers \
            /etc/init.d/hwclock \
            /etc/init.d/hwdrivers \
            /etc/init.d/modules \
            /etc/init.d/modules-load \
            /etc/init.d/modloop \
    # Can't do cgroups
    && sed -i 's/\tcgroup_add_service/\t#cgroup_add_service/g' /lib/rc/sh/openrc-run.sh \
    && sed -i 's/VSERVER/DOCKER/Ig' /lib/rc/sh/init.sh

RUN apk update && \
    apk add --no-cache openssh mc unzip bzip2 screen wget curl iptraf-ng htop eudev

RUN apk update && \
    apk add --no-cache bash build-base gcc wget git autoconf libmcrypt-dev libzip-dev zip \
    g++ make openssl-dev \
    php83 php83-fpm php83-common \
    php83-openssl \
    php83-pdo_mysql \
    php83-mbstring
    
RUN apk update && \
    apk --no-cache add nginx tzdata

COPY ./config_files/auto_init /etc/init.d/
COPY ./config_files/auto_init.sh /sbin/
COPY ./config_files/first_start.sh /sbin/

COPY ./config_files/php_configure.sh /sbin/
COPY ./config_files/nginx.new.conf /etc/nginx/
COPY ./config_files/php-fpm.new.conf /etc/php83/
COPY ./config_files/www.new.conf /etc/php83/php-fpm.d/
COPY ./config_files/php-fpm83.sh /etc/profile.d/
COPY ./config_files/index.html /root/
COPY ./config_files/index.php /root/
COPY ./config_files/phpinfo.php /root/

RUN chown root:root /etc/init.d/auto_init && chmod 0700 /etc/init.d/auto_init
RUN chown root:root /sbin/first_start.sh && chmod 0700 /sbin/first_start.sh
RUN chown root:root /sbin/auto_init.sh && chmod 0700 /sbin/auto_init.sh

RUN ln -s /etc/init.d/auto_init /etc/runlevels/default/auto_init

EXPOSE 22/tcp
EXPOSE 80/tcp
# EXPOSE 443/tcp

CMD ["/sbin/init"]
