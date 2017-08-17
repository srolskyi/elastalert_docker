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

#Alias
ENV ELASTICSEARCH_HOST elasticsearchhost

# Port on above Elasticsearch host. Set in default Elasticsearch configuration file.
ENV ELASTICSEARCH_PORT 9200

# Use TLS to connect to Elasticsearch (true or false)
ENV ELASTICSEARCH_TLS false

# Verify TLS
ENV ELASTICSEARCH_TLS_VERIFY true

WORKDIR /opt

# Copy the script used to launch the Elastalert when a container is started.
COPY ./start.sh /opt/

# Install software required for Elastalert and NTP for time synchronization.
RUN yum -y update && \
    yum -y install python-devel python-virtualenv openssl-devel libffi-devel gcc wget unzip && \
    virtualenv --python=python2.7 venv && \
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
    pip install -r requirements.txt && \
    python setup.py install && \
    pip install -e . && \
    pip install elastalert && \
# Install Supervisor.
    easy_install supervisor && \

# Make the start-script executable.
    chmod +x /opt/start.sh && \

# Create directories.
    mkdir -p "${CONFIG_DIR}" && \
    mkdir -p "${RULES_DIRECTORY}" && \
    mkdir -p "${LOG_DIR}" && \

# Copy default configuration files to configuration directory.
    cp "${ELASTALERT_HOME}/config.yaml.example" "${ELASTALERT_CONFIG}" && \
    cp "${ELASTALERT_HOME}/supervisord.conf.example" "${ELASTALERT_SUPERVISOR_CONF}" && \

# Elastalert configuration:
# Set the rule directory in the Elastalert config file to external rules directory.
    sed -i -e "s|rules_folder: [[:print:]]*|rules_folder: ${RULES_DIRECTORY}|g" "${ELASTALERT_CONFIG}" && \
# Set the Elasticsearch host that Elastalert is to query.
    sed -i -e "s|es_host: [[:print:]]*|es_host: ${ELASTICSEARCH_HOST}|g" "${ELASTALERT_CONFIG}" && \
# Set the port used by Elasticsearch at the above address.
    sed -i -e "s|es_port: [0-9]*|es_port: ${ELASTICSEARCH_PORT}|g" "${ELASTALERT_CONFIG}" && \

# Elastalert Supervisor configuration:
    # Redirect Supervisor log output to a file in the designated logs directory.
    sed -i -e"s|logfile=.*log|logfile=${LOG_DIR}/supervisord.log|g" "${ELASTALERT_SUPERVISOR_CONF}" && \
    # Redirect Supervisor stderr output to a file in the designated logs directory.
    sed -i -e"s|stderr_logfile=.*log|stderr_logfile=${LOG_DIR}/elastalert_stderr.log|g" "${ELASTALERT_SUPERVISOR_CONF}" && \
    # Modify the start-command.
    sed -i -e"s|python elastalert.py|python -m elastalert.elastalert --config ${ELASTALERT_CONFIG}|g" "${ELASTALERT_SUPERVISOR_CONF}" && \

# Copy the Elastalert configuration file to Elastalert home directory to be used when creating index first time an Elastalert container is launched.
    cp "${ELASTALERT_CONFIG}" "${ELASTALERT_HOME}/config.yaml" && \

# Add Elastalert to Supervisord.
    supervisord -c "${ELASTALERT_SUPERVISOR_CONF}"

# Define mount points.
VOLUME [ "${CONFIG_DIR}", "${RULES_DIRECTORY}", "${LOG_DIR}"]

# Launch Elastalert when a container is started.
CMD [ "/opt/start.sh" ]
