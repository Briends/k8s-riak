# Riak
#
# VERSION       2.0.0

# Stick with version 0.9.15 because riak repo supports only ubuntu LTS 14
FROM phusion/baseimage:0.9.15
MAINTAINER Jan-Philip Loos <jloos@maxdaten.io>

ARG BINARY_PATH

# Environmental variables
ENV DEBIAN_FRONTEND noninteractive
ENV RIAK_VERSION 2.1.4-1

RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef"

RUN \
    # Add stack repo
    curl -s https://s3.amazonaws.com/download.fpcomplete.com/ubuntu/fpco.key | apt-key add - && \
    echo 'deb http://download.fpcomplete.com/ubuntu/trusty stable main' | tee /etc/apt/sources.list.d/fpco.list && \

    # Install Java 7
    # sed -i.bak 's/main$/main universe/' /etc/apt/sources.list && \
    # apt-get update -qq && apt-get install -y software-properties-common && \
    # apt-add-repository ppa:webupd8team/java -y && apt-get update -qq && \
    # echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    # apt-get install -y oracle-java7-installer && \

    # Add Riak repo
    curl https://packagecloud.io/gpg.key | apt-key add - && \
    curl -s https://packagecloud.io/install/repositories/basho/riak/script.deb.sh | bash && \

    # apt-get update && \
    # Install Riak
    # apt-get install -y apt-transport-https && \
    apt-get install -y riak=${RIAK_VERSION} && \
    apt-get install -y stack && \

    # Cleanup
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup the Riak service
ADD bin/riak.sh /etc/service/riak/run

# Add bootstrapper for auto clustering
ADD ${BINARY_PATH} /usr/sbin/

# Tune Riak configuration settings for the container
RUN sed -i.bak 's/listener.http.internal = 127.0.0.1/listener.http.internal = 0.0.0.0/' /etc/riak/riak.conf && \
    sed -i.bak 's/listener.protobuf.internal = 127.0.0.1/listener.protobuf.internal = 0.0.0.0/' /etc/riak/riak.conf && \
    echo "anti_entropy.concurrency_limit = 1" >> /etc/riak/riak.conf && \
    echo "javascript.map_pool_size = 0" >> /etc/riak/riak.conf && \
    echo "javascript.reduce_pool_size = 0" >> /etc/riak/riak.conf && \
    echo "javascript.hook_pool_size = 0" >> /etc/riak/riak.conf

# Make Riak's data and log directories volumes
VOLUME /var/lib/riak

VOLUME /var/log/riak

# Open ports for HTTP and Protocol Buffers
EXPOSE 8098 8087

# Enable insecure SSH key
# See: https://github.com/phusion/baseimage-docker#using_the_insecure_key_for_one_container_only
RUN /usr/sbin/enable_insecure_key

# Leverage the baseimage-docker init system
CMD ["/sbin/my_init", "--quiet"]
