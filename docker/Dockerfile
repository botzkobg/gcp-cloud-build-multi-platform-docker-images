FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:stable

RUN apt-get update && apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg \
openssh-client \
&& install -m 0755 -d /etc/apt/keyrings \
&& curl -fsSL "https://download.docker.com/linux/debian/gpg" -o /etc/apt/keyrings/docker.asc \
&& chmod a+r /etc/apt/keyrings/docker.asc \
&& echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list \
&& apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get -y -qq install docker-ce-cli=5:28.1.1-1~debian.12~bookworm docker-buildx-plugin=0.23.0-1~debian.12~bookworm


COPY ssh.config /root/.ssh/config
COPY docker-wrapper.sh /scripts/docker-wrapper.sh

RUN  chmod 700 ~/.ssh \
     && chmod 600 ~/.ssh/config \
     && chmod a+x /scripts/docker-wrapper.sh \
     && cp ~/.ssh/config /etc/ssh/ssh_config.d/remote-node.conf

WORKDIR /scripts
ENTRYPOINT ["/scripts/docker-wrapper.sh"]
CMD ["info"]