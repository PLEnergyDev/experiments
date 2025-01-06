FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /experiments

COPY fastutil-7.2.0.jar /usr/local/src/java-libs/

RUN apt-get update && apt-get install -y \
	build-essential \
	bash \
	gcc \
	g++ \
	clang \
	cmake \
	cpio \
	git \
	locales \
	libicu-dev \
	libkrb5-dev \
	liblttng-ust-dev \
	libssl-dev \
	lld \
	lldb \
	llvm \
	python-is-python3 \
	python3 python3-pip \
	openjdk-21-jdk \
	dotnet-sdk-8.0 \
	dotnet-runtime-8.0 \
	curl \
	vim \
	kmod \
	msr-tools \
	libapr1-dev \
	libgmp-dev \
	libhts-dev \
	libpcre3-dev \
	libboost1.74-all-dev \
	linux-tools-common linux-tools-$(uname -r) \
	linux-modules-$(uname -r) \
	linux-modules-extra-$(uname -r) \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y \
	&& . $HOME/.cargo/env \
	&& rustc --version

RUN locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

ENV PATH="/root/.cargo/bin:$PATH"
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV DOTNET_ROOT=/usr/share/dotnet

# RUN runtime-8.0.4/build.sh --subset clr --configuration Checked
