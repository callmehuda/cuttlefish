find /dev -name kvm
sudo apt install -y git devscripts equivs config-package-dev debhelper-compat golang curl >/dev/null
git clone https://github.com/google/android-cuttlefish
cd android-cuttlefish
tools/buildutils/build_packages.sh
sudo dpkg -i ./cuttlefish-base_*_*64.deb || sudo apt-get install -f
sudo dpkg -i ./cuttlefish-user_*_*64.deb || sudo apt-get install -f
sudo usermod -aG kvm,cvdnetwork,render $USER

wget -q 'https://ci.android.com/builds/submitted/14818820/aosp_cf_arm64_only_phone-userdebug/latest/raw/cvd-host_package.tar.gz'
wget -q 'https://ci.android.com/builds/submitted/14818820/aosp_cf_arm64_only_phone-userdebug/latest/raw/aosp_cf_arm64_only_phone-img-14818820.zip'

mkdir cf
cd cf
tar -xvf /path/to/cvd-host_package.tar.gz
unzip /path/to/aosp_cf_arm64_only_phone-img-14818820.zip

HOME=$PWD ./bin/launch_cvd