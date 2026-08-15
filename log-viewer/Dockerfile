FROM public.ecr.aws/docker/library/openjdk:8-jre-slim

WORKDIR /opt/logviewer

ADD log-viewer-1.0.10.tar.gz /opt/logviewer/temp/
RUN mv temp/log-viewer-1.0.10/* . && \
    rm -rf temp

EXPOSE 8111

CMD ["./logviewer.sh"]