#!/usr/bin/env bash

## install docker

curl -sSL https://get.daocloud.io/docker | sh

## install docker-compose

curl -L https://get.daocloud.io/docker/compose/releases/download/1.23.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

## use daocloud docker registy 

curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://f1361db2.m.daocloud.io
/usr/bin/systemctl restart docker

## local ENV setting

SPHINX_DIR=$(dirname "$PWD")
HTML_DIR=$(find ~/Documents/kubernetes-docs -name index.html -exec dirname {} \;)

## write docker compose
cat << EOF > docker-compose.yaml
version: '3'
services: 

  html:
    container_name: sphinx-kubernetes
    build:
      context: .
      dockerfile: Dockerfile.sphinx
    volumes:
      - "${SPHINX_DIR}:/usr/src/sphinx"
    
  web:
    container_name: nginx-kubernetes
    image: nginx:1.14-alpine
    restart: always
    ports:
      - "80:80"
    volumes:
      - "${HTML_DIR}:/usr/share/nginx/html"
EOF

## run container

cd ${SPHINX_DIR}/docker/
docker-compose -f docker-compose.yaml up -d
