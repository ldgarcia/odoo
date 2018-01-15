FROM debian:stable-slim

ENV LANG=en_US \
    LANGUAGE=en_US:en \
    LC_COLLATE=C \
    LC_CTYPE=en_US.UTF-8 \
    ODOO_VERSION=11.0 \
    ODOO_RELEASE=20180114 \
    ODOO_RC=/etc/odoo/odoo.conf

RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            gcc \
            curl \
            node-less \
            python3-dev \
            python3-pip \
            python3-setuptools \
            python3-renderpm \
            libsasl2-dev \
            libldap2-dev \
            libssl-dev \
            unzip \
            xz-utils \
            wkhtmltopdf \
        && pip3 install num2words boto3

RUN set -x; \
        curl -o tini -SL https://github.com/krallin/tini/releases/download/v0.16.1/tini-static-amd64 \
        && echo '5e01734c8b2e6429a1ebcc67e2d86d3bb0c4574dd7819a0aff2dca784580e040 tini' | sha256sum -c - \
        && chmod u+x tini \
        && mv tini /usr/bin

RUN set -x; \
        curl -o dockerize.tar.gz -SL https://github.com/jwilder/dockerize/releases/download/v0.6.0/dockerize-linux-amd64-v0.6.0.tar.gz \
        && echo 'ad838ccaa301d0f331d4729abb4b33c363644dc5749a92467a09d305d348b3b6 dockerize.tar.gz' | sha256sum -c - \
        && tar -C /usr/local/bin -xf dockerize.tar.gz \
        && chmod u+x /usr/local/bin/dockerize \
        && rm dockerize.tar.gz

RUN set -x; \
    curl -o odoo.tar.gz -SL https://nightly.odoo.com/11.0/nightly/src/odoo_${ODOO_VERSION}.${ODOO_RELEASE}.tar.gz \
    && echo '20bbc5f77f85d56fb85f9ee5314b7107142ca0ee5684664bc48e5430cf677cf0 odoo.tar.gz' | sha256sum -c - \
    && pip3 install odoo.tar.gz \
    && rm odoo.tar.gz

ADD ./odoo.conf.tmpl /etc/odoo/
ADD ./entrypoint.sh /etc/odoo/

RUN mkdir -p /mnt/extra-addons \
    && mkdir -p /opt/extra-addons \
    && mkdir -p /opt/custom-addons \
    && curl -o odoo-s3.zip -SL https://github.com/marclijour/odoo-s3/archive/master.zip \
    && echo 'bbce4b31cd8d91d9ddef1b070640953d40c3828f6abc3096c9a781a89564018c odoo-s3.zip' | sha256sum -c - \
    && unzip odoo-s3.zip \
    && mv odoo-s3-master /opt/extra-addons/odoo-s3 \
    && rm odoo-s3.zip \
    && useradd -r odoo \
    && chown -R odoo:odoo /etc/odoo \
    && chown -R odoo:odoo /opt \
    && chown -R odoo:odoo /mnt/extra-addons \
    && chmod -R go-rwx /etc/odoo

RUN chmod u+x /etc/odoo/entrypoint.sh

USER odoo

VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

EXPOSE 8069 8071

ENTRYPOINT ["tini", "--", "/etc/odoo/entrypoint.sh"]

CMD ["odoo"]
