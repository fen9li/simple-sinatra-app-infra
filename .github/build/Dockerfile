FROM python:3.7-alpine

LABEL repository="https://github.com/fen9li/simple-sinatra-app-infra.git"
LABEL homepage="https://github.com/fen9li/simple-sinatra-app-infra.git"
LABEL maintainer="Feng Li <lifcn@yahoo.com>"

RUN pip install --quiet --no-cache-dir awscli
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
