FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    ca-certificates \
    curl \
    wget \
    gnupg \
    locales \
    tzdata \
    git \
    zsh \
    dbus-user-session \
    rsync && \
    sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash smoke && \
    usermod -aG sudo smoke && \
    echo "smoke ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/smoke && \
    chmod 0440 /etc/sudoers.d/smoke

USER smoke
WORKDIR /home/smoke/osyx

CMD ["/bin/bash"]
