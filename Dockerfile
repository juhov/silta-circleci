ARG BUILDER_BASE_IMAGE=circleci/php:7.3.23-cli-node

FROM ${BUILDER_BASE_IMAGE}

# Make composer packages executable.
ENV PATH="/home/circleci/.composer/vendor/bin:${PATH}"

# Downgrade composer to 1.x
USER root
RUN composer self-update --1
USER circleci

# Install drush and prestissimo.
RUN composer global require drush/drush-launcher:^0.8.0 hirak/prestissimo \
  && composer clearcache

# Install vim based on popular demand.
RUN sudo apt-get update --allow-releaseinfo-change && sudo apt-get install vim && sudo apt-get clean

# Add gcloud CLI and kubectl
ENV GCLOUD_VERSION 348.0.0-0
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && sudo apt-get install apt-transport-https ca-certificates \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
  && sudo apt-get update --allow-releaseinfo-change && sudo apt-get install google-cloud-sdk=${GCLOUD_VERSION} kubectl \
  && sudo apt-get clean

# Install AWS cli and aws-iam-authenticator
RUN sudo apt-get install -y awscli git python3 \
  && curl -o /tmp/aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/aws-iam-authenticator \
  && chmod +x /tmp/aws-iam-authenticator \ 
  && sudo mv /tmp/aws-iam-authenticator /bin/aws-iam-authenticator

# Install Helm 3
ENV HELM_VERSION v3.6.3
ENV FILENAME helm-${HELM_VERSION}-linux-amd64.tar.gz
ENV HELM_URL https://get.helm.sh/${FILENAME}

RUN curl -o /tmp/$FILENAME ${HELM_URL} \
  && tar -zxvf /tmp/${FILENAME} -C /tmp \
  && rm /tmp/${FILENAME} \
  && sudo mv /tmp/linux-amd64/helm /bin/helm \
  && helm repo add bitnami https://charts.bitnami.com/bitnami \
  && helm repo add minio https://helm.min.io/ \
  && helm repo add wunderio https://storage.googleapis.com/charts.wdr.io \
  && helm plugin install https://github.com/quintush/helm-unittest --version 0.2.4

# NOTE: quintush/helm-unittest v0.2.0 release breaks helm tests.

# TODO: when https://github.com/lrills/helm-unittest/issues/87 is merged,
# switch back to using https://github.com/lrills/helm-unittest as the source

# Add custom php config and lift memory limit.
COPY conf/php/memory.ini /usr/local/etc/php/conf.d/memory.ini

