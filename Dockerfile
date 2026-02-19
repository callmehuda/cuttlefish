FROM ubuntu:24.04

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

RUN curl -fsSL https://us-apt.pkg.dev/doc/repo-signing-key.gpg \
-o /etc/apt/trusted.gpg.d/artifact-registry.asc
RUN chmod a+r /etc/apt/trusted.gpg.d/artifact-registry.asc
RUN echo "deb https://us-apt.pkg.dev/projects/android-cuttlefish-artifacts android-cuttlefish main" \
| tee -a /etc/apt/sources.list.d/artifact-registry.list
RUN apt update

RUN apt install cuttlefish-base cuttlefish-user cuttlefish-orchestration -y

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
RUN wget -q 'https://storage.googleapis.com/android-build/builds/aosp-android-latest-release-linux-aosp_cf_arm64_only_phone-userdebug/14818820/aaa694142c5ba6ad90306040232e01aee6338e0c222a1099a8ed24043bd77da5/1/cvd-host_package.tar.gz?GoogleAccessId=gcs-sign%40android-builds-project.google.com.iam.gserviceaccount.com&Expires=1771530030&Signature=HirK8879%2B8T%2FyjUn7CCGCW3if%2BFsYgMrgNTmFjNFOJEz4T6XnUXttkHK5KlYPqxKN1ZsD74sN6mDI5Q22iVtJGnAVJ8VgH8l2UElMxNDKA%2FJYioUNNYDqWeaOv0yJ5bJWlGswiC7zd%2BOD3NpanrAAvqnOL0TyKKvYjAhYmEQh%2BjhKdZES0F8uCQnwGE9RM6m3qsmQ3CGbNdzRQCGC6fErw75p7I7jv9Thv7FYH80eTtRUsGJsAjWUWw17IzeeKSgoyhwHKZQdJxyGJWFmNPBaBskqtlUgvGPwev%2FHhWugjf7PruaHT9AfZLY7XpPoPHZ22dTMsmsxDjBzothpOw23A%3D%3D&response-content-disposition=attachment' -O cvd-host_package.tar.gz \
&& wget -q 'https://storage.googleapis.com/android-build/builds/aosp-android-latest-release-linux-aosp_cf_arm64_only_phone-userdebug/14818820/aaa694142c5ba6ad90306040232e01aee6338e0c222a1099a8ed24043bd77da5/1/aosp_cf_arm64_only_phone-img-14818820.zip?GoogleAccessId=gcs-sign%40android-builds-project.google.com.iam.gserviceaccount.com&Expires=1771529911&Signature=e6eblJ825QORgPfCEwjKgeuviEsBuFTL3ieNnTlAFLHIRtCG19H4Sf6XCfoxQBeH%2Bq9YM9gteJ4%2BymNjkDUC03j4IMci9v%2Fecj6R54Y7%2FEBPov%2F8IVkX8syOIZK0c5Jqy7TqTMn%2BPm%2BkjWoeZOMk9JYYHtxIoVLp68IETVCo4eQSQGOJZPQyyOFHIA3RCpu0hS138qqj3iRKELP6mNP11dPzw8mHLBLgSdO9tTvpI0smkU%2F2ef8HP0yRFksuWbQeqOlRF9NqqKBprwEyN3lUTqLqMkoyn39YqmXopjuAzl7R3iunUPmWnrqcitZEYBmBUNI7JP0xdi%2BdJn3JNmSRsQ%3D%3D&response-content-disposition=attachment' -O aosp_cf_arm64_phone-img.zip 
#COPY --chown=vsoc_user:vsoc_user cvd-host_package.tar.gz /home/vsoc_user/
#COPY --chown=vsoc_user:vsoc_user aosp_cf_arm64_phone-img.zip /home/vsoc_user/

# Extract artifacts
USER vsoc_user
RUN tar -xf cvd-host_package.tar.gz -C /home/vsoc_user/ \
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