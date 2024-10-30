# Pin Ansible roles and collections

## Motivation

If you are using `Ansible` you will eventually end up using roles and/or collections from [Ansible Galaxy](https://galaxy.ansible.com/ui/). Just like any dependency in any other programming language, you always want to pin your dependencies, since you probably do not want your code to stop working just because breaking changes of a major version affect you.

## Prerequisites

A Linux or MacOS machine for local development. If you are running Windows, you first need to set up the *Windows Subsystem for Linux (WSL)* environment.

You need `docker cli` and `docker-compose` on your machine for testing purposes, and/or on the machines that run your pipeline.
You can check both of these by running the following commands:
```sh
docker --version
docker-compose --version
```

Make sure that you already have a docker container with SSH access.

## Implementation

When adding `Ansible` roles and/or collections, you usually want to use the latest version, and change it if needed.

Let's start with the following role in a `dockerfile`:
```sh
RUN ansible-galaxy install geerlingguy.ntp
```
You can use it in an `Ansible` playlist like shown below:
```sh
- name: master playlist
  hosts: local
  gather_facts: true
  become: yes
  vars:
    ntp_servers:
      - time.google.com
  roles:
    - geerlingguy.ntp
```
Most `Ansible` roles read configuration settings from `vars`. 

Currently, the role `geerlingguy.ntp` is not pinned, so when running the `Ansible` playlist via `Docker`, you will get the laterst version of the `geerlingguy.ntp` role. But what version is it?

To figure out the used version, you have to call
```sh
ansible-galaxy role list
```
inside the container and retrieve the version of the role you are using.
If you use a `docker-compose` file, you just have to list the ansible roles in the place you call your `Ansible` playbook. For example:
```sh
    command: ["ansible-galaxy role list && sh runAnsible.sh"]
```

Now it's time to update the dockerfile with the pinned version:
```sh
RUN ansible-galaxy install geerlingguy.ntp,2.5.0
```
Note that the sintax is to add a comma `,` at the end, followed by the version.

Let's try using a collection also:
```sh
RUN ansible-galaxy collection install ansible.posix:1.5.2
RUN apk --no-cache add at
```
Many `Ansible` collections are build on top of other tools that are expected to be available; that's the reason of installing the `at` package.
A simple usage of it could look like:
```sh
    - name: Schedule a command to execute in 20 minutes as root
      ansible.posix.at:
        command: echo "Hello, World!"
        count: 20
        units: minutes
```

To figure out the used version, you have to call
```sh
ansible-galaxy role list
```
just as before.

Now it's time to update the dockerfile with the pinned version:
```sh
RUN ansible-galaxy collection install ansible.posix:1.5.2
```
Note that the sintax is to add a colon `:` at the end, followed by the version.
Do also note that `Ansible` roles and collections have has a slightly different versioning syntax. 

Note: `Ansible` needs SSH access to the target machine. You can find out how to configure SSH access in the docker container at [https://github.com/Frunza/configure-docker-container-with-ssh-access](https://github.com/Frunza/configure-docker-container-with-ssh-access)

## Usage

Navigate to the root of the repository and run the following command:
```sh
sh run.sh 
```

The following happens:
1) the first command builds the docker image, passing the private key value as an argument and tagging it as *ansiblepinversions*
2) the docker image sets up the SSH access by copying the value of the `SSH_PRIVATE_KEY` argument to the standard location for SSH keys
3) the second command uses docker-compose to create the container and run it. The container runs the `master.yml` `Ansible` playbook, which asks a question, responds to it and prints the output.

Note: if you want to test this, consider changing the `hosts` in the `Ansible` playbook to `local`.
