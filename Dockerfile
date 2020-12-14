FROM quay.io/centos/centos:centos7

ARG AWS_CLI_VERSION=1.18.89

RUN yum install -y python3 python3-pip mysql && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    alternatives --install /usr/bin/pip pip /usr/bin/pip3 1 && \
    pip install --no-cache-dir awscli==$AWS_CLI_VERSION

ADD diag.sh /usr/local/bin

CMD diag.sh
