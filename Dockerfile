FROM jenkins/jenkins:lts-jdk11
LABEL description="Jenkins LTS image with plugins pre-installed" \
     "com.koalaphils.vendor"="Koala Software Technology Innovations" \
     "com.koalaphils.image.author"="mdprotacio@outlook.com"

USER root
ENV TZ=Asia/Manila
RUN apt-get update -y \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get install -yq --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    gnupg2 \
    python3-pip \
    python3-setuptools \
    software-properties-common \
    sudo \
    tzdata

RUN curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - \
  && add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable" \
  && apt-get update -yq \
  && apt-get install docker-ce -y \
  && pip3 install -U --system --no-cache-dir awscli \
  && usermod -aG docker jenkins \
  && echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY ./plugins.txt /plugins.txt
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dfile.encoding=UTF-8"
#ENV JENKINS_UC=https://updates.jenkins.io/
ENV JENKINS_UC=http://ftp.yz.yamagata-u.ac.jp/pub/misc/jenkins/updates/
ENV JENKINS_UC_DOWNLOAD=http://ftp.yz.yamagata-u.ac.jp/pub/misc/jenkins/
#ENV TRY_UPGRADE_IF_NO_MARKER=true
RUN jenkins-plugin-cli --verbose --latest true -f /plugins.txt

COPY ./ssh_config /etc/ssh/ssh_config

VOLUME /src

RUN sed -i "s|exec \"\$@\"||g" /usr/local/bin/jenkins.sh \
  ; echo "cp -r /src/.ssh /src/.aws /var/jenkins_home\nchmod 600 /var/jenkins_home/.ssh/id_rsa*\nssh-keygen -f /var/jenkins_home/.ssh/id_rsa -y > /var/jenkins_home/.ssh/id_rsa.pub\ngit config --global user.name \"Jenkins Master\"\ngit config --global user.email jenkins@zmtsys.com\nexec \"\$@\";" >> /usr/local/bin/jenkins.sh

USER jenkins

