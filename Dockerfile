FROM python:3.8.3-alpine3.12

ARG AWS_CLI_VERSION=1.18.89

RUN pip install --no-cache-dir awscli==$AWS_CLI_VERSION && \
    apk -uv add bash mysql-client

ADD diag.sh /usr/local/bin

CMD diag.sh
