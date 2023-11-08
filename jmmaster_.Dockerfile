# Use caster base image
FROM caster/jmeter
MAINTAINER CasterHsu

# Ports to be exposed from the container for JMeter Master
EXPOSE 60000

# keep container alive
CMD ["tail", "-f", "/dev/null"]