FROM ubuntu:18.04 AS builder

RUN apt update && apt install -y wget

WORKDIR /tmp

RUN wget https://redirects.z6.web.core.windows.net/mule-ee-distribution-standalone-4.2.2.tar.gz
RUN tar xf mule-ee-distribution-standalone-4.2.2.tar.gz
RUN mv mule-enterprise-standalone-4.2.2 mule

RUN wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.12.0/jmx_prometheus_javaagent-0.12.0.jar
RUN cp jmx_prometheus_javaagent-0.12.0.jar mule/lib/opt/

COPY wrapper-prometheus.conf .

RUN cat wrapper-prometheus.conf >> mule/conf/wrapper.conf
RUN echo "{}" >> mule/conf/prometheus.yaml



FROM adoptopenjdk:8u232-b09-jdk-hotspot

ARG APP_ID

RUN mkdir /app && groupadd mule && useradd -g mule mule && chown mule:mule /app
COPY --from=builder --chown=mule /tmp/mule /app/mule
COPY --chown=mule target/$APP_ID-mule-application.jar /app/mule/apps
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER mule
WORKDIR /app/mule
ENV MULE_HOME=/app/mule

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

EXPOSE 8081/tcp
