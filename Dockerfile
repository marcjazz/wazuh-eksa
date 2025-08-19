# Vault configuration Dockerfile
FROM alpine:latest

# Install required tools
RUN apk add --no-cache \
    openssh \
    bash \
    kubernetes-client \
    curl

# Install Vault CLI
RUN VAULT_VERSION=1.15.0 && \
    wget -q https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && \
    unzip vault_${VAULT_VERSION}_linux_amd64.zip && \
    mv vault /usr/local/bin/ && \
    rm vault_${VAULT_VERSION}_linux_amd64.zip

# Create working directory
WORKDIR /workspace

# Copy Vault configuration files
COPY unified-vault-config.sh /workspace/unified-vault-config.sh

# Make script executable
RUN chmod +x /workspace/unified-vault-config.sh

# Set entrypoint
ENTRYPOINT ["/workspace/unified-vault-config.sh"]