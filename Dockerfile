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
        htop \
        vim \
        libmysqlclient-dev \
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
    && pip install mysql-python \
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


RUN set -ex \
    && apt-get update -yqq \
    && apt-get install -yqq \
       software-properties-common \
       python-software-properties

# Install Java 8
RUN \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    add-apt-repository -y ppa:webupd8team/java && \
    apt-get update && \
    apt-get install -y oracle-java8-installer && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/oracle-jdk8-installer

# Install Embulk
RUN set -ex \
  && curl --insecure --create-dirs -o /usr/local/bin/embulk -L "https://dl.embulk.org/embulk-latest.jar" \
  && chmod +x /usr/local/bin/embulk

RUN embulk gem install embulk-input-mysql \
    && embulk gem install embulk-output-redshift

# Install psql client
RUN set -ex \
    && apt-get update -yqq \
    && apt-get install -yqq postgresql-client

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
