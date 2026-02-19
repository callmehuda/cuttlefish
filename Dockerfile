FROM --platform=linux/arm64 ubuntu:22.04

# Hindari interaksi saat instalasi paket
ENV DEBIAN_FRONTEND=noninteractive

# Install dependensi sistem
RUN apt-get update && apt-get install -y \
# Dependensi Cuttlefish
curl \
wget \
gnupg2 \
software-properties-common \
apt-transport-https \
ca-certificates \
# Tools umum
unzip \
sudo \
udev \
kmod \
# Virtualisasi & kernel modules
qemu-system-aarch64 \
qemu-utils \
# Network tools
iproute2 \
iptables \
dnsmasq \
bridge-utils \
# Build tools (jika perlu compile)
build-essential \
&& rm -rf /var/lib/apt/lists/*

# Download dan install Cuttlefish host packages dari Google
# Cek versi terbaru di: https://github.com/google/android-cuttlefish/releases
ARG CF_VERSION=1.0.0
ARG CF_ARCH=arm64

RUN wget -q https://github.com/google/android-cuttlefish/releases/download/v${CF_VERSION}/cuttlefish-base_${CF_VERSION}_${CF_ARCH}.deb \
https://github.com/google/android-cuttlefish/releases/download/v${CF_VERSION}/cuttlefish-user_${CF_VERSION}_${CF_ARCH}.deb \
&& apt-get install -y \
./cuttlefish-base_${CF_VERSION}_${CF_ARCH}.deb \
./cuttlefish-user_${CF_VERSION}_${CF_ARCH}.deb \
&& rm -f *.deb \
&& rm -rf /var/lib/apt/lists/*

# Buat user 'cuttlefish' dan tambahkan ke grup yang diperlukan
RUN useradd -m -s /bin/bash vsoc_user \
&& usermod -aG kvm,cvdnetwork,render vsoc_user \
&& echo "vsoc_user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Buat direktori kerja
WORKDIR /home/vsoc_user
RUN mkdir -p /home/vsoc_user/cvd-home && \
chown -R vsoc_user:vsoc_user /home/vsoc_user

# Salin Android image (CVD artifacts) ke container
# Kamu perlu menyediakan file-file ini dari AOSP build atau CI artifacts:
# - cvd-host_package.tar.gz
# - aosp_cf_arm64_phone-img-*.zip (atau target image lainnya)
RUN wget -q https://ci.android.com/builds/submitted/14818820/aosp_cf_arm64_only_phone-userdebug/latest/cvd-host_package.tar.gz \
&& wget -q https://ci.android.com/builds/submitted/14818820/aosp_cf_arm64_only_phone-userdebug/latest/aosp_cf_arm64_only_phone-img-14818820.zip \
&& mv cvd-host_package.tar.gz /home/vsoc_user \
&& mv aosp_cf_arm64_only_phone-img-14818820.zip /bome/vsoc_user/aosp_cf_arm64_phone-img.zip
#COPY --chown=vsoc_user:vsoc_user cvd-host_package.tar.gz /home/vsoc_user/
#COPY --chown=vsoc_user:vsoc_user aosp_cf_arm64_phone-img.zip /home/vsoc_user/

# Extract artifacts
USER vsoc_user
RUN tar -xzf cvd-host_package.tar.gz -C /home/vsoc_user/ \
&& unzip aosp_cf_arm64_phone-img.zip -d /home/vsoc_user/ \
&& rm -f cvd-host_package.tar.gz aosp_cf_arm64_phone-img.zip

# Environment variables
ENV HOME=/home/vsoc_user
ENV PATH="${HOME}/bin:${PATH}"

# Expose port untuk ADB dan WebRTC (opsional)
# ADB: 6520+ (instance 1 = 6520, instance 2 = 6521, dst)
# WebRTC/Web UI: 8443
EXPOSE 6520 8443

# Entrypoint script
COPY --chown=vsoc_user:vsoc_user entrypoint.sh /home/vsoc_user/entrypoint.sh
RUN chmod +x /home/vsoc_user/entrypoint.sh

ENTRYPOINT ["/home/vsoc_user/entrypoint.sh"]