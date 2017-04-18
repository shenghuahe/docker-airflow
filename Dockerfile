# VERSION 1.8.0
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM ubuntu:trusty
MAINTAINER Puckel_

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.8.0
ARG AIRFLOW_HOME=/usr/local/airflow

RUN set -ex \
    && buildDeps=' \
        python-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        python-pip \
        python-requests \
        apt-utils \
        curl \
        netcat \
        wget \
        software-properties-common \
        python-software-properties \
    && apt-get remove -yqq --no-install-recommends python-setuptools \
    && wget https://bootstrap.pypa.io/get-pip.py \
    && python get-pip.py \
    && pip install -U pip setuptools \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && python -m pip install -U pip \
    && pip install --upgrade pip \
    && pip install Cython \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install airflow[crypto,celery,postgres,hive,hdfs,jdbc,slack]==$AIRFLOW_VERSION \
    && pip install celery[redis]==3.1.17 \
    && apt-get remove --purge -yqq $buildDeps \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base \
    && apt-get autoremove -yqq

# Install Java 8
RUN \
    echo "===> Installing Java 8..."  \
    && apt-get install -y python-software-properties debconf-i18n \
    && add-apt-repository -y ppa:webupd8team/java \
    && apt-get update \
    && echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections \
    && apt-get install -y oracle-java8-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Install Embulk
RUN set -ex \
  && curl --insecure --create-dirs -o /usr/local/bin/embulk -L "https://dl.embulk.org/embulk-latest.jar" \
  && chmod +x /usr/local/bin/embulk

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
