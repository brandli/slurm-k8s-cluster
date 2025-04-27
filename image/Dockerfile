FROM ubuntu:22.04

ENV SLURM_TAG=slurm-23-02-0-1
ENV GOSU_VERSION=1.11
LABEL org.opencontainers.image.source="https://github.com/brandli/slurm-docker-cluster" \
      org.opencontainers.image.title="slurm-docker-cluster" \
      org.opencontainers.image.description="Slurm Docker cluster on Ubuntu 22.04" \
      org.label-schema.docker.cmd="docker-compose up -d" \
      maintainer="brandli (forked from StackHPC)"

# Update and install dependencies
RUN set -ex \
    && apt-get update \
    && apt-get -y upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install \
       wget \
       bzip2 \
       perl \
       gcc \
       g++ \
       git \
       gnupg \
       make \
       munge \
       libmunge-dev \
       python3-dev \
       python3-pip \
       python3 \
       mariadb-server \
       libmariadb-dev \
       psmisc \
       bash-completion \
       vim \
       libhttp-parser-dev \
       libjson-c-dev \
       openmpi-bin \
       openmpi-common \
       libopenmpi-dev \
       libpmix-dev \
       hwloc \
       libhwloc-dev \
       openssh-server \
       curl \
       squashfs-tools \
       fuse \
       fuse2fs \
       libfuse2 \
       cryptsetup \
       ca-certificates \
       seccomp \
       libseccomp-dev \
       pkg-config \
       ruby \
       ruby-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Go (required for Apptainer)
RUN cd /tmp \
    && export GO_VERSION=1.20.4 \
    && wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_VERSION}.linux-amd64.tar.gz \
    && echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile \
    && echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc \
    && export PATH=$PATH:/usr/local/go/bin

# Install Apptainer from source
RUN cd /tmp \
    && export APPTAINER_VERSION=1.2.4 \
    && export PATH=$PATH:/usr/local/go/bin \
    && wget https://github.com/apptainer/apptainer/releases/download/v${APPTAINER_VERSION}/apptainer-${APPTAINER_VERSION}.tar.gz \
    && tar -xzf apptainer-${APPTAINER_VERSION}.tar.gz \
    && cd apptainer-${APPTAINER_VERSION} \
    && ./mconfig --with-suid \
    && cd builddir \
    && make \
    && make install \
    && cd /tmp \
    && rm -rf apptainer-${APPTAINER_VERSION} apptainer-${APPTAINER_VERSION}.tar.gz

# Install kubectl
RUN KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl

# Install Node.js (using the newer recommended approach)
RUN apt-get update \
    && apt-get install -y ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Note: OnDemand doesn't have an official Ubuntu package, so you may need to build from source
# or use an alternative approach. This is a placeholder:
RUN echo "OnDemand would need to be installed manually or from source for Ubuntu"

# Setup Python alternatives if needed
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

RUN pip3 install Cython nose

RUN set -ex \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "${GNUPGHOME}" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

RUN set -x \
    && git clone -b ${SLURM_TAG} --single-branch --depth=1 https://github.com/SchedMD/slurm.git \
    && cd slurm \
    && ./configure --enable-debug --prefix=/usr --sysconfdir=/etc/slurm \
        --with-mysql_config=/usr/bin  --libdir=/usr/lib/x86_64-linux-gnu \
    && make install \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && cd .. \
    && rm -rf slurm

RUN mkdir -p /etc/sysconfig/slurm \
        /var/spool/slurmd \
        /var/run/slurmd \
        /var/run/slurmdbd \
        /var/lib/slurmd \
        /var/log/slurm \
        /data \
        /etc/slurm \
    && touch /var/lib/slurmd/node_state \
        /var/lib/slurmd/front_end_state \
        /var/lib/slurmd/job_state \
        /var/lib/slurmd/resv_state \
        /var/lib/slurmd/trigger_state \
        /var/lib/slurmd/assoc_mgr_state \
        /var/lib/slurmd/assoc_usage \
        /var/lib/slurmd/qos_usage \
        /var/lib/slurmd/fed_mgr_state \
    && useradd -r --uid=990 slurm \
    && chown -R slurm:slurm /var/*/slurm* \
    && useradd -u 1000 ubuntu \
    && usermod -p '*' ubuntu # unlocks account but sets no password

VOLUME /etc/slurm
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["slurmdbd"]