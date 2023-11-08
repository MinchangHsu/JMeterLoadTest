# Use Java 11 slim JRE
FROM openjdk:11.0.11-jre-slim
MAINTAINER CasterHsu

# JMeter version
ARG JMETER_VERSION=5.6

# Install few utilities
RUN apt-get clean && \
    apt-get update && \
    apt-get -qy install \
                wget \
                telnet \
                iputils-ping \
                unzip \
                vim

# Install JMeter
RUN   mkdir /jmeter \
      && cd /jmeter/ \
      && wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz \
      && tar -xzf apache-jmeter-$JMETER_VERSION.tgz \
      && rm apache-jmeter-$JMETER_VERSION.tgz

# ADD all the plugins
ADD plugins-lib /jmeter/apache-jmeter-$JMETER_VERSION/lib

## replace customer properties
ADD properties /jmeter/apache-jmeter-$JMETER_VERSION/bin

# ADD the sample test
ADD jmx jmx

# Set JMeter Home
ENV JMETER_HOME /jmeter/apache-jmeter-$JMETER_VERSION/

# Add JMeter to the Path
ENV PATH $JMETER_HOME/bin:$PATH