FROM ubuntu:jammy-20240808

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV NODE_MAJOR=20
ENV TZ=Etc/UTC

# Set startup command
CMD ["/bin/bash"]

# Install dependencies for C unit testing
RUN apt update && apt install -y \
	gcovr \
	ruby \
	&& gem install ceedling \
	&& rm -rf /var/lib/apt/lists/*

# Install build dependencies
RUN apt update && apt upgrade -y \
	binutils \
	binutils-gold \
	bison \
	build-essential \
	bzip2 \
	ca-certificates \
	cmake \
	curl \
	default-jdk \
	device-tree-compiler \
	devscripts \
	ecj \
	fakeroot \
	file \
	flex \
	fuse \
	g++ \
	gawk \
	gcc \
	gengetopt \
	gettext \
	git \
	gnupg \
	gperf \
	groff \
	help2man \
	java-propose-classpath \
	java-wrappers \
	jq \
	libc6-dev \
	libcap2-bin \
	libexpat-dev \
	libffi-dev \
	liblz4-dev \
	libncurses5-dev \
	libpcre3-dev \
	libpython3-dev \
	libsqlite3-dev \
	libssl-dev \
	libxml-parser-perl \
	libzstd-dev \
	lz4 \
	make \
	mkisofs \
	ocaml \
	ocaml-findlib \
	ocaml-nox \
	patch \
	pkg-config \
	psmisc \
	python-is-python3 \
	python3-setuptools \
	python3-yaml \
	python3.11 \
	python3.11-dev \
	rsync \
	sharutils \
	sudo \
	subversion \
	swig \
	u-boot-tools \
	unzip \
	uuid-dev \
	vim-common \
	wget \
	zip \
	zlib1g-dev \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -L -o- https://deb.nodesource.com/setup_"$NODE_MAJOR".x | bash - \
	&& apt update && apt install -y nodejs \
	&& rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3.11-config /usr/bin/python3-config

RUN echo "ALL ALL=(ALL) NOPASSWD: /usr/sbin/setcap" > /etc/sudoers.d/1-setcap

ARG USERNAME
RUN echo "${USERNAME}:*:19639:0:99999:7:::" >> /etc/shadow
