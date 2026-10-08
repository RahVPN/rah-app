# RahVPN

[فارسی](README.fa.md) | [English](README.md)

RahVPN is an unofficial client for the [Aether](https://github.com/CluvexStudio/Aether) core.

```
bash tools/android/setup.sh
```

This script prepares the Android project and configures the required dependencies.

```
flutter pub get
flutter devices
flutter run
```

To build a debug APK instead of launching it:

```sh
flutter build apk --debug
```

## APK signature

RahVPN release APKs are signed with a 4096-bit RSA certificate.

| Property             | Value                                                                                               |
| -------------------- | --------------------------------------------------------------------------------------------------- |
| Alias                | `rahvpn`                                                                                          |
| Key algorithm        | RSA 4096-bit                                                                                        |
| Signature algorithm  | SHA384withRSA                                                                                       |
| APK signature scheme | v2                                                                                                  |
| Certificate SHA-256  | `DF:9B:1D:C7:36:40:0E:69:28:2C:2A:D1:DA:75:71:58:9B:53:50:B4:A7:E2:2C:69:0B:58:63:89:30:40:66:46` |
| Certificate SHA-1    | `39:43:83:EA:68:5D:91:42:37:67:3D:5A:06:BA:4C:24:46:EE:B1:1B`                                     |
| Certificate validity | `2026-10-08 → 2054-02-23`                                                                        |

### Verify an APK

Use Android's `apksigner` tool (included in Android SDK Build Tools) to verify the signature and print the certificate details:

```bash
apksigner verify --verbose --print-certs app-arm64-v8a-release.apk
```

## Run on Linux

The Linux desktop build requires GTK 3, CMake, Ninja, Clang, and Ayatana AppIndicator development libraries. On Ubuntu or Debian, install them with:

```sh
sudo apt update
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libayatana-appindicator3-dev liblzma-dev iptables iproute2 util-linux pkexec polkitd
```

Enable Flutter's Linux desktop target, download the Linux Aether/helper binaries for your machine, and run the app:

```sh
build/runtime deps (Debian/Ubuntu)
./tools/linux/setup_linux.sh      # creates linux/ if missing and downloads Aether + hev-socks5-tunnel
./tools/linux/install_linux_tun.sh # checks TUN runtime prerequisites
flutter run -d linux        # development
./tools/linux/package_linux.sh tar  # portable archive: dist/rahvpn-linux-<arch>.tar.gz
./tools/linux/package_linux.sh deb  # Debian/Ubuntu package in dist/
./tools/linux/package_linux.sh rpm  # Fedora/RHEL package in dist/
```



## 📥 Download APK

| Architecture | Download                                                                                                        |
| ------------ | --------------------------------------------------------------------------------------------------------------- |
|  ARM64-v8a  | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/app-arm64-v8a-release.apk)   |
| ARMv7        | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/app-armeabi-v7a-release.apk) |
| x86_64       | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/app-x86_64-release.apk)      |
| Universal    | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/app-release.apk)             |



## 📥 Download Linux

| Distribution  | Download                                                                                                       |
| ------------- | -------------------------------------------------------------------------------------------------------------- |
| Debian/Ubuntu | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/rahvpn_0.2.3_amd64.deb)     |
| Fedora/RHEL   | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/rahvpn-0.2.3.x86_64.rpm)    |
| tar.gz        | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.3/rahvpn-linux-x86_64.tar.gz) |
