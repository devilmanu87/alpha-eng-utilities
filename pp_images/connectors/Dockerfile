# Custom Connector Image Build
# Dockerfile

ARG tag
FROM confluentinc/cp-server-connect-operator:$tag
USER root
ADD driver_jars/*.jar /opt/confluent/etc/connect/jars/
RUN ls -ltr /opt/confluent/etc/connect/jars/
RUN confluent-hub install --no-prompt jcustenborder/kafka-connect-spooldir:latest
RUN confluent-hub install --no-prompt dariobalinzo/kafka-connect-elasticsearch-source:latest
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:latest
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-azure-blob-storage:latest
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-azure-blob-storage-source:latest
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:latest
RUN confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:latest
USER 1001
