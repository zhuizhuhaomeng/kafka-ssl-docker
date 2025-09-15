FROM ubuntu
WORKDIR /
RUN apt-get update > /dev/null && apt-get install runit -y > /dev/null
RUN apt-get update > /dev/null && apt-get install libssl-dev openssl -y > /dev/null
RUN apt-get update > /dev/null && apt-get install openjdk-8-jdk -y > /dev/null

# kafka_2.13-4.1.0 does not contains zookeeper-server-start.sh
# So please don't update to this version
# If kafka_2.13-3.9.1.tgz does not exist, please update the script below to start kafka server.

ADD https://downloads.apache.org/kafka/3.9.1/kafka_2.13-3.9.1.tgz .
RUN tar xzf kafka_2.13-3.9.1.tgz && rm kafka_2.13-3.9.1.tgz

RUN mkdir -p /etc/service/zookeeper/
RUN mkdir -p /etc/service/kafka/

COPY serverssl.properties .
COPY prepStartup.sh .

RUN /bin/bash -c "echo -e '#!/bin/bash\nexec /kafka_2.13-3.9.1/bin/zookeeper-server-start.sh /kafka_2.13-3.9.1/config/zookeeper.properties \n' > /etc/service/zookeeper/run"
RUN /bin/bash -c "echo -e '#!/bin/bash\n/prepStartup.sh\nexec /kafka_2.13-3.9.1/bin/kafka-server-start.sh /kafka_2.13-3.9.1/config/serverssl.properties \n' > /etc/service/kafka/run"

RUN chmod +x /etc/service/zookeeper/run
RUN chmod +x /etc/service/kafka/run

ENV KAFKA_HOME=/kafka_2.13-3.9.1
ENV PASSWORD=password
ENV DOMAIN=test.kafka.top

EXPOSE 2181/tcp
EXPOSE 9093/tcp
EXPOSE 9094/tcp

HEALTHCHECK --interval=60s --timeout=5s --start-period=30s \
CMD [[ $(sv status kafka) =~ "run" ]] || exit 1

CMD ["runsvdir", "/etc/service"]
