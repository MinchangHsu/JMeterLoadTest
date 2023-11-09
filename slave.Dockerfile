# Use vinsdocker base image
FROM caster/jmeter-base:latest

MAINTAINER CasterHsu

# Ports to be exposed from the container for JMeter Slaves/Server
EXPOSE 1099 50000

# Application to run on starting the container
ENTRYPOINT $JMETER_HOME/bin/jmeter-server


# keep container alive
CMD ["tail", "-f", "/dev/null"]