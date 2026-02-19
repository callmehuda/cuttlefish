#!/bin/bash
set -e

HOME_DIR="/home/vsoc_user"

# Load kernel modules yang dibutuhkan (perlu akses root/privileged)
sudo modprobe vhost_vsock || true
sudo modprobe vhost_net || true

# Pindah ke direktori home
cd "${HOME_DIR}"

# Jalankan Cuttlefish
# Flag tambahan yang umum digunakan:
#   --num_instances=1        → jumlah device
#   --cpus=4                 → jumlah CPU
#   --memory_mb=4096         → RAM
#   --blank_data_image_mb=8192 → storage
#   --nostart_webrtc         → nonaktifkan WebRTC jika tidak perlu

exec ./bin/launch_cvd \
    --num_instances=1 \
    --cpus=4 \
    --memory_mb=4096 \
    --blank_data_image_mb=65536 \
    --report_anonymous_usage_stats=n \
    "$@"