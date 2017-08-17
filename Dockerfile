#ElastAlert and Centos:7

FROM centos:7

MAINTAINER Sergii Rolskyi 

# Download latest Elasticalert
ENV ELASTALERT_URL https://github.com/Yelp/elastalert/archive/master.zip

# Directory holding configuration for Elastalert and Supervisor.
ENV CONFIG_DIR /opt/config

# Elastalert rules directory.
ENV RULES_DIRECTORY /opt/rules

# Elastalert configuration file path in configuration directory.
ENV ELASTALERT_CONFIG ${CONFIG_DIR}/config.yaml

# Directory to which Elastalert and Supervisor logs are written.
ENV LOG_DIR /opt/logs

# Elastalert home directory name.
ENV ELASTALERT_DIRECTORY_NAME elastalert

# Elastalert home directory full path.
ENV ELASTALERT_HOME /opt/${ELASTALERT_DIRECTORY_NAME}

# Supervisor configuration file for Elastalert.
ENV ELASTALERT_SUPERVISOR_CONF ${CONFIG_DIR}/supervisord.conf

#### Alias, DNS or IP of Elasticsearch host to be queried by Elastalert. Set in default Elasticsearch configuration file.
###ENV ELASTICSEARCH_HOST elasticsearchhost

#### Port on above Elasticsearch host. Set in default Elasticsearch configuration file.
###ENV ELASTICSEARCH_PORT 9200

WORKDIR /opt

# Copy the script used to launch the Elastalert when a container is started.
#COPY ./start.sh /opt/

# Install software required for Elastalert and NTP for time synchronization.
RUN yum -y update && \
    yum -y install python-devel openssl-devel libffi-devel gcc wget unzip && \
# Download and unpack Elastalert.
    wget -O elastalert.zip "${ELASTALERT_URL}" && \
    unzip elastalert.zip && \
    rm -f elastalert.zip && \
    mv e* "${ELASTALERT_DIRECTORY_NAME}"

WORKDIR "${ELASTALERT_HOME}"

# Install Elastalert.
RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" && \
    python get-pip.py && \
    pip install "setuptools>=11.3" && \
    python setup.py install && \
    pip install -e . && \

# Install Supervisor.
    easy_install supervisor && \

# Make the start-script executable.
#    chmod +x /opt/start-elastalert.sh && \

# Create directories.
    mkdir -p "${CONFIG_DIR}" && \
    mkdir -p "${RULES_DIRECTORY}" && \
    mkdir -p "${LOG_DIR}" && \

# Copy default configuration files to configuration directory.
    cp "${ELASTALERT_HOME}/config.yaml.example" "${ELASTALERT_CONFIG}" && \
    cp "${ELASTALERT_HOME}/supervisord.conf.example" "${ELASTALERT_SUPERVISOR_CONF}" && \

# Add Elastalert to Supervisord.
    supervisord -c "${ELASTALERT_SUPERVISOR_CONF}"

# Define mount points.
VOLUME [ "${CONFIG_DIR}", "${RULES_DIRECTORY}", "${LOG_DIR}"]

# Launch Elastalert when a container is started.
# CMD ["/opt/start.sh"]
