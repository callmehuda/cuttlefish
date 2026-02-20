find /dev -name kvm
sudo apt install -y git devscripts equivs config-package-dev debhelper-compat golang curl >/dev/null
sudo curl -fsSL https://us-apt.pkg.dev/doc/repo-signing-key.gpg \
    -o /etc/apt/trusted.gpg.d/artifact-registry.asc
sudo chmod a+r /etc/apt/trusted.gpg.d/artifact-registry.asc
echo "deb https://us-apt.pkg.dev/projects/android-cuttlefish-artifacts android-cuttlefish main" \
    | sudo tee -a /etc/apt/sources.list.d/artifact-registry.list
sudo apt update
sudo apt install cuttlefish-base cuttlefish-user cuttlefish-orchestration -y
sudo usermod -aG kvm,cvdnetwork,render $USER

wget -q 'https://ci.android.com/builds/submitted/14818820/aosp_cf_arm64_only_phone-userdebug/latest/raw/cvd-host_package.tar.gz'
wget -q 'https://ci.android.com/builds/submitted/14818820/aosp_cf_arm64_only_phone-userdebug/latest/raw/aosp_cf_arm64_only_phone-img-14818820.zip'

mkdir cf
cd cf
tar -xvf ../cvd-host_package.tar.gz
unzip ../aosp_cf_arm64_only_phone-img-14818820.zip

echo "no" | HOME=$PWD ./bin/launch_cvd -report_anonymous_usage_stats=n