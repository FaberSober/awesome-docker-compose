FROM public.ecr.aws/docker/library/openjdk:8-jre-slim

WORKDIR /opt/logviewer

RUN apt-get update && apt-get install -y wget \
    && wget https://github.com/sevdokimov/log-viewer/releases/download/v1.0.10/log-viewer-1.0.10.tar.gz \
    && tar -xzf log-viewer-1.0.10.tar.gz \
    && mv log-viewer-1.0.10/* . \
    && rm -rf log-viewer-1.0.10 log-viewer-1.0.10.tar.gz

EXPOSE 8111

CMD ["./logviewer.sh"]