# Dockerfile for icinga2 with icingaweb2
# https://github.com/jjethwa/icinga2

FROM debian:bookworm

ENV APACHE2_HTTP=REDIRECT \
    ICINGA2_FEATURE_GRAPHITE=false \
    ICINGA2_FEATURE_GRAPHITE_HOST=graphite \
    ICINGA2_FEATURE_GRAPHITE_PORT=2003 \
    ICINGA2_FEATURE_GRAPHITE_URL=http://graphite \
    ICINGA2_FEATURE_GRAPHITE_SEND_THRESHOLDS="true" \
    ICINGA2_FEATURE_GRAPHITE_SEND_METADATA="false" \
    ICINGA2_USER_FULLNAME="Icinga2" \
    ICINGA2_FEATURE_DIRECTOR="true" \
    ICINGA2_FEATURE_DIRECTOR_KICKSTART="true" \
    ICINGA2_FEATURE_DIRECTOR_USER="icinga2-director" \
    ICINGA2_LOG_LEVEL="information" \
    MYSQL_ROOT_USER=root

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    apache2 \
    apt-transport-https \
    bc \
    ca-certificates \
    curl \
    dnsutils \
    file \
    gnupg \
    jq \
    libdbd-mysql-perl \
    libdigest-hmac-perl \
    libnet-snmp-perl \
    locales \
    logrotate \
    lsb-release \
    bsd-mailx \
    mariadb-client \
    mariadb-server \
    netbase \
    openssh-client \
    openssl \
    php-curl \
    php-ldap \
    php-mysql \
    php-mbstring \
    php-gmp \
    procps \
    pwgen \
    python3 \
    python3-requests \
    snmp \
    msmtp \
    sudo \
    supervisor \
    telnet \
    unzip \
    wget \
    cron \
    && apt-get -y --purge remove exim4 exim4-base exim4-config exim4-daemon-light \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN export DEBIAN_FRONTEND=noninteractive \
    && curl -s https://packages.icinga.com/icinga.key \
    | apt-key add - \
    && echo "deb https://packages.icinga.com/debian icinga-$(lsb_release -cs) main" > /etc/apt/sources.list.d/$(lsb_release -cs)-icinga.list \
    && echo "deb-src https://packages.icinga.com/debian icinga-$(lsb_release -cs) main" >> /etc/apt/sources.list.d/$(lsb_release -cs)-icinga.list \
    && echo "deb http://deb.debian.org/debian $(lsb_release -cs)-backports main" > /etc/apt/sources.list.d/$(lsb_release -cs)-backports.list \
    && apt-get update \
    && apt-get install -y --install-recommends \
    icinga2 \
    icinga2-ido-mysql \
    icingacli \
    icingaweb2 \
    monitoring-plugins \
    nagios-nrpe-plugin \
    nagios-plugins-contrib \
    nagios-snmp-plugins \
    libmonitoring-plugin-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://packages.sury.org/php/README.txt | sudo bash -x
RUN apt-get update && apt-get install -y php8.2 libapache2-mod-php8.2 php8.2-curl \
    php8.2-ldap \
    php8.2-mysql \
    php8.2-mbstring \
    php8.2-gmp
RUN update-alternatives --set php /usr/bin/php8.2

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

ARG GITREF_AWSSDK=3.218.5
ARG GITREF_INCUBATOR=v0.20.0
ARG GITREF_MODAWS=v1.1.0
ARG GITREF_MODDIRECTOR=v1.11.0
ARG GITREF_MODGRAPHITE=v1.2.0
ARG GITREF_MODX509=v1.1.1

RUN mkdir -p /usr/local/share/icingaweb2/modules/ \
    # Icinga Director
    && mkdir -p /usr/local/share/icingaweb2/modules/director/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-director/archive/${GITREF_MODDIRECTOR}.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/director --exclude=.gitignore -f - \
    # # Icingaweb2 Graphite
    && mkdir -p /usr/local/share/icingaweb2/modules/graphite \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-graphite/archive/${GITREF_MODGRAPHITE}.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/graphite -f - \
    # Icingaweb2 AWS
    && mkdir -p /usr/local/share/icingaweb2/modules/aws \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-aws/archive/${GITREF_MODAWS}.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/aws -f - \
    && wget -q --no-cookies "https://github.com/aws/aws-sdk-php/releases/download/${GITREF_AWSSDK}/aws.zip" \
    && unzip -d /usr/local/share/icingaweb2/modules/aws/library/vendor/aws aws.zip \
    && rm aws.zip \
    # Module Incubator
    && mkdir -p /usr/local/share/icingaweb2/modules/incubator/ \
    && wget -q --no-cookies -O - "https://github.com/Icinga/icingaweb2-module-incubator/archive/${GITREF_INCUBATOR}.tar.gz" \
    | tar xz --strip-components=1 --directory=/usr/local/share/icingaweb2/modules/incubator -f - \
    # Module x509
    && mkdir -p /usr/local/share/icingaweb2/modules/x509/ \
    && wget -q --no-cookies "https://github.com/Icinga/icingaweb2-module-x509/archive/${GITREF_MODX509}.zip" \
    && unzip -d /usr/local/share/icingaweb2/modules/x509 ${GITREF_MODX509}.zip \
    && mv /usr/local/share/icingaweb2/modules/x509/icingaweb2-module-x509-${GITREF_MODX509#v}/* /usr/local/share/icingaweb2/modules/x509/ \
    && rm -rf /usr/local/share/icingaweb2/modules/x509/icingaweb2-module-x509-${GITREF_MODX509#v}/ \
    && rm ${GITREF_MODX509}.zip \
    && true

ADD content/ /

# Final fixes
RUN true \
    && sed -i 's/vars\.os.*/vars.os = "Docker"/' /etc/icinga2/conf.d/hosts.conf \
    && mv /etc/icingaweb2/ /etc/icingaweb2.dist \
    && mv /etc/icinga2/ /etc/icinga2.dist \
    && mkdir -p /etc/icinga2 \
    && usermod -aG icingaweb2 www-data \
    && usermod -aG nagios www-data \
    && usermod -aG icingaweb2 nagios \
    && mkdir -p /var/log/icinga2 \
    && chmod 755 /var/log/icinga2 \
    && chown nagios:nagios /var/log/icinga2 \
    && mkdir -p /var/cache/icinga2 \
    && chmod 755 /var/cache/icinga2 \
    && chown nagios:nagios /var/cache/icinga2 \
    && touch /var/log/cron.log \
    && rm -rf \
    /var/lib/mysql/* \
    && chmod u+s,g+s \
    /bin/ping \
    /bin/ping6 \
    /usr/lib/nagios/plugins/check_icmp \
    && /sbin/setcap cap_net_raw+p /bin/ping

EXPOSE 80 443 5665

# Initialize and run Supervisor
ENTRYPOINT ["/opt/run"]

