# use the latest Ubuntu LTS image
FROM ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/dsumjham/patch-hunter"
LABEL org.opencontainers.image.description="Firmware patch analysis utility packaged in Docker."
LABEL org.opencontainers.image.licenses="MIT"

# prevent interactive prompts during package installs
ENV DEBIAN_FRONTEND=noninteractive

# install dependencies
RUN apt update && apt install -y \
    curl git build-essential libfontconfig1-dev liblzma-dev libssl-dev \
    pkg-config p7zip-full p7zip-rar cpio gzip bzip2 xz-utils tar \
    squashfs-tools 7zip zlib1g-dev liblzo2-dev wget liblz4-dev libzstd-dev \
	7zip p7zip-full python3
RUN ln -s /usr/bin/7z /usr/local/bin/7zz

# build and install sasquatch (patched unsquashfs)
RUN git clone https://github.com/onekey-sec/sasquatch.git 
WORKDIR /sasquatch/squashfs-tools
RUN make 
RUN cp sasquatch /usr/local/bin/sasquatch
WORKDIR /    

# install the Rust compiler
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# clone binwalk and compile it from source
RUN git clone https://github.com/ReFirmLabs/binwalk
WORKDIR /binwalk
RUN cargo build --release
RUN cp target/release/binwalk /usr/local/bin/binwalk

# ensure /bins exists as a target to copy firmware into
WORKDIR /bins

# copy the entrypoint script in to analyze the firmware images
WORKDIR /
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]