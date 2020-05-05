FROM gcr.io/spark-operator/spark:v2.4.5

ENV SCALA_VERSION 2.12
ENV SPARK_VERSION 2.4.5
ENV HADOOP_VERSION 3.2.1
ENV SBT_VERSION 1.3.9
ENV ARCHIVE_URL http://archive.apache.org/dist

RUN apt-get -y update && apt-get install -y curl

# Hadoop Config
ENV HADOOP_HOME "/opt/hadoop"
RUN rm -rf ${HADOOP_HOME}/ \
    && cd /opt \
    && curl -sL --retry 3 "${ARCHIVE_URL}/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" | tar xz  \
    && chown -R root:root hadoop-${HADOOP_VERSION} \
    && ln -sfn hadoop-${HADOOP_VERSION} hadoop \
    && rm -rf ${HADOOP_HOME}/share/doc \
    && find /opt/ -name *-sources.jar -delete
ENV PATH="${HADOOP_HOME}/bin:${PATH}"
ENV HADOOP_CONF_DIR "${HADOOP_HOME}/etc/hadoop"

# Spark Config
# Since the conf/ folder gets mounted over by the spark-operator we move the spark-env.sh to another folder to be sourced in the entrypoint.sh. No good solution exists to merge the original conf folder with the volumeMount
RUN rm -rf ${SPARK_HOME}/ \
    && cd /opt \
    && curl -sL --retry 3 "${ARCHIVE_URL}/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-without-hadoop-scala-${SCALA_VERSION}.tgz" | tar xz  \
    && mv spark-${SPARK_VERSION}-bin-without-hadoop-scala-${SCALA_VERSION} spark-${SPARK_VERSION} \
    && chown -R root:root spark-${SPARK_VERSION} \
    && ln -sfn spark-${SPARK_VERSION} spark \
    && mkdir -p ${SPARK_HOME}/conf-org/ \
    && mv ${SPARK_HOME}/conf/spark-env.sh.template ${SPARK_HOME}/conf-org/spark-env.sh \
    && rm -rf ${SPARK_HOME}/examples  ${SPARK_HOME}/data ${SPARK_HOME}/tests ${SPARK_HOME}/conf  \
    && echo 'export SPARK_DIST_CLASSPATH=$(hadoop classpath)' >> ${SPARK_HOME}/conf-org/spark-env.sh \
    && echo 'export SPARK_EXTRA_CLASSPATH=$(hadoop classpath)' >> ${SPARK_HOME}/conf-org/spark-env.sh

ENV PATH="${SPARK_HOME}/bin:${PATH}"

# Get SBT
RUN \
  curl -fsL https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.tgz | tar xfz - -C /usr/local \
  && $(mv /usr/local/sbt-launcher-packaging-$SBT_VERSION /usr/local/sbt || true) \
  && ln -s /usr/local/sbt/bin/* /usr/local/bin/ \
  && sbt sbt-version || sbt sbtVersion || true

# Edit entrypoint to source spark-env.sh before running spark-submit
RUN sed -i '30i #CUSTOM\n' /opt/entrypoint.sh \
   && sed -i '/#CUSTOM/a source ${SPARK_HOME}/conf-org/spark-env.sh\n' /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]