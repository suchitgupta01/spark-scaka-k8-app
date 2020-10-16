ARG SPARK_IMAGE=gcr.io/spark-operator/spark:v3.0.0
FROM ${SPARK_IMAGE}

ENV SBT_VERSION 1.3.13


# Switch to user root so we can add additional jars, packages and configuration files.
USER root

RUN apt-get -y update && apt-get install -y curl

USER ${spark_uid}

WORKDIR /app

#Install SBT
RUN curl -fsL https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.tgz | tar xfz - -C /usr/local
ENV PATH /usr/local/sbt/bin:${PATH}

RUN sbt update

ENTRYPOINT ["/opt/entrypoint.sh"]