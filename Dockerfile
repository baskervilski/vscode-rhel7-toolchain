FROM centos:7

# Fix CentOS 7 EOL mirror issues
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

RUN yum install -y epel-release
RUN yum install -y autoconf gperf bison file flex texinfo help2man gcc-c++ libtool make patch \
    ncurses-devel python36-devel perl-Thread-Queue bzip2 git wget which xz unzip rsync \
    glibc-static libstdc++-static gawk automake
RUN yum install -y kernel-headers
RUN yum install -y glibc-headers glibc-devel

# Install newer make version (glibc 2.28 requires make >= 4.0)
RUN wget https://ftp.gnu.org/gnu/make/make-4.3.tar.gz && \
    tar -xzf make-4.3.tar.gz && \
    cd make-4.3 && \
    ./configure --prefix=/usr/local && \
    make && make install && \
    cd .. && rm -rf make-4.3 make-4.3.tar.gz
ENV PATH=/usr/local/bin:$PATH

RUN ln -sf python36 /usr/bin/python3
RUN wget -O /sbin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64
RUN chmod a+x /sbin/dumb-init
RUN echo 'export PATH=/opt/ctng/bin:$PATH' >> /etc/profile

# FROM ubuntu:latest

ARG CTNG_UID=1000
ARG CTNG_GID=1000
ARG CTNG_UNAME=ctng
RUN groupadd -g $CTNG_GID ctng
RUN useradd -d /home/$CTNG_UNAME -m -g $CTNG_GID -u $CTNG_UID -s /bin/bash $CTNG_UNAME

# RUN apt-get update
# RUN apt-get install -y gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
# python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
# patch rsync meson ninja-build

# Install crosstool-ng
RUN wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.26.0.tar.bz2
RUN tar -xjf crosstool-ng-1.26.0.tar.bz2
RUN cd crosstool-ng-1.26.0 && ./configure --prefix=/crosstool-ng-1.26.0/out && make && make install
ENV PATH=$PATH:/crosstool-ng-1.26.0/out/bin

# Switch to non-root user
USER $CTNG_UNAME
WORKDIR /home/$CTNG_UNAME

# Copy crosstool-ng configuration files and build scripts
COPY --chown=1000:1000 configs/ /home/ctng/configs/
COPY --chown=1000:1000 build-toolchain.sh /home/ctng/
RUN chmod +x /home/ctng/build-toolchain.sh

ENTRYPOINT [ "/sbin/dumb-init", "--" ]
