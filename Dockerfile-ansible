FROM python:3.9.20-slim-bullseye

# Install system packages including SSH client
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    libffi-dev \
    libssl-dev \
    python3-pip \
    openssh-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Ansible
RUN python3 -m pip install --no-cache-dir ansible==8.7.0

WORKDIR /ansible

#ENTRYPOINT ["ansible", "ansible-playbook"]
