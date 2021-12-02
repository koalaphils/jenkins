FROM jenkins/jenkins:lts-jdk11
LABEL org.opencontainers.image.description="Jenkins LTS image with plugins pre-installed" \
     "com.koalaphils.vendor"="Koala Software Technology Innovations" \
     "com.koalaphils.image.author"="mdprotacio@outlook.com"

USER root
ENV TZ=Asia/Manila
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dfile.encoding=UTF-8"
ENV TRY_UPGRADE_IF_NO_MARKER=false
ENV PLUGINS_FORCE_UPGRADE=false
RUN apt-get update -y \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get install -yq --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    docker.io \
    git \
    gnupg2 \
    python3-pip \
    python3-setuptools \
    software-properties-common \
    sudo \
    tzdata \
  && pip3 install -U --system --no-cache-dir awscli \
  && usermod -aG docker jenkins \
  && echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY ./ssh_config /etc/ssh/ssh_config
COPY ./plugins.txt /src/plugins.txt

RUN jenkins-plugin-cli --verbose -f /src/plugins.txt \
  && sed -i "s|exec \"\$@\"||g" /usr/local/bin/jenkins.sh \
       ; echo "cp -r /src/.ssh /src/.aws /var/jenkins_home\nchmod 600 /var/jenkins_home/.ssh/id_rsa*\nssh-keygen -f /var/jenkins_home/.ssh/id_rsa -y > /var/jenkins_home/.ssh/id_rsa.pub\ngit config --global user.name \"Jenkins Master\"\ngit config --global user.email jenkins@localhost\nexec \"\$@\";" >> /usr/local/bin/jenkins.sh

VOLUME /src
USER jenkins

