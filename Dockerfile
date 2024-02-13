#
# Dockerfile for alpine-linux-rc-nginx-php81 mikrotik-docker-image
# (C) 2023-2024 DL7DET
#

FROM --platform=$TARGETPLATFORM alpine:3.19.1 AS base

# Preset Metadata parameters
ARG BUILD
ARG APP_VERSION=${CI_IMAGE_VERSION}
ARG DEVEL_VERSION=${CI_DEVEL_VERSION}
ARG ALPINE_VERSION=${CI_LINUX_VERSION}

# Set Metadata for docker-image
LABEL maintainer="DL7DET <detlef@lampart.de>" \
    org.label-schema.url="https://cb3.lampart-web.de/internal/docker-projects/mikrotik-docker-images/mikrotik-alp_rc_nginx_php81" \
    org.label-schema.version=${APP_VERSION} \
    org.label-schema.version-devel=${DEVEL_VERSION} \
    org.label-schema.build-date=${BUILD} \
    org.label-schema.version_alpine=${ALPINE_VERSION} \
    org.label-schema.vcs-url="https://cb3.lampart-web.de/internal/docker-projects/mikrotik-docker-images/mikrotik-alp_rc_nginx_php81.git" \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.description="alpine-linux-rc-nginx-php81 mikrotik-docker-image" \
    org.label-schema.schema-version="1.0"

RUN echo 'https://ftp.halifax.rwth-aachen.de/alpine/v3.19/main/' >> /etc/apk/repositories \
    && echo 'https://ftp.halifax.rwth-aachen.de/alpine/v3.19/community' >> /etc/apk/repositories \
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
    apk add --no-cache openssh mc unzip bzip2 screen wget curl iptraf-ng htop

RUN apk update && \
    apk add --no-cache bash build-base gcc wget git autoconf libmcrypt-dev libzip-dev zip \
    g++ make openssl-dev \
    php81 php81-fpm php81-common \
    php81-openssl \
    php81-pdo_mysql \
    php81-mbstring
    
RUN apk update && \
    apk --no-cache add nginx tzdata

COPY ./config_files/auto_init /etc/init.d/
COPY ./config_files/auto_init.sh /sbin/
COPY ./config_files/first_start.sh /sbin/

COPY ./config_files/php_configure.sh /sbin/
COPY ./config_files/nginx.new.conf /etc/nginx/
COPY ./config_files/php-fpm.new.conf /etc/php81/
COPY ./config_files/www.new.conf /etc/php81/php-fpm.d/
COPY ./config_files/php-fpm81.sh /etc/profile.d/
COPY ./config_files/index.html /root/
COPY ./config_files/index.php /root/
COPY ./config_files/phpinfo.php /root/

RUN chown root:root /etc/init.d/auto_init && chmod 0755 /etc/init.d/auto_init
RUN chown root:root /sbin/first_start.sh && chmod 0700 /sbin/first_start.sh
RUN chown root:root /sbin/auto_init.sh && chmod 0700 /sbin/auto_init.sh

RUN ln -s /etc/init.d/auto_init /etc/runlevels/default/auto_init

EXPOSE 22/tcp
EXPOSE 80/tcp
# EXPOSE 443/tcp

CMD ["/sbin/init"]
