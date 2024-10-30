FROM alpine:3.18.0

# Define the environment variable
ARG SSH_PRIVATE_KEY
# Create the .ssh directory if it doesn't exist
RUN mkdir -p /root/.ssh
# Write the private key content to id_rsa file
RUN echo "$SSH_PRIVATE_KEY" | tr -d '\r' > /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa

# Install ansible
RUN apk --no-cache add ansible=7.5.0-r0

# Install the ansible.posix collection
RUN ansible-galaxy collection install ansible.posix:1.5.2
# Install the at package
RUN apk --no-cache add at

# Install geerlingguy.ntp role from Ansible Galaxy
RUN ansible-galaxy install geerlingguy.ntp,2.5.0

# Copy scripts to the expected location
COPY ./scripts /app
# Copy ansible to the expected location
COPY ./ansible /app/ansible
