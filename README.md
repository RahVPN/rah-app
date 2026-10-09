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

| Property             | Value                                                             |
| -------------------- | ----------------------------------------------------------------- |
| Alias                | `rahvpn`                                                        |
| Key algorithm        | RSA 4096-bit                                                      |
| Signature algorithm  | SHA384withRSA                                                     |
| APK signature scheme | v2                                                                |
| Certificate SHA-256  | df9b1dc736400e69282c2ad1da7571589b5350b4a7e22c690b58638930406646  |
| Certificate SHA-1    | 394383ea685d914237673d5a06ba4c2446eeb11b                          |

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
| ARM64-v8a    | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.4/app-arm64-v8a-release.apk)   |
| ARMv7        | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.4/app-armeabi-v7a-release.apk) |
| x86_64       | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.4/app-x86_64-release.apk)      |
| Universal    | [**Download APK**](https://github.com/RahVPN/rah-app/releases/download/v0.2.4/app-release.apk)             |

## 📥 Download Linux

| Distribution  | Download                                                                                                   |
| ------------- | ---------------------------------------------------------------------------------------------------------- |
| Debian/Ubuntu | [**Download**](https://github.com/RahVPN/rah-app/releases/download/v0.2.4/rahvpn_0.2.4_amd64.deb)     |
| Fedora/RHEL   | [**Download**](https://github.com/RahVPN/rah-app/releases/download/v0.2.4/rahvpn-0.2.4.x86_64.rpm)    |
| tar.gz        | [**Download**](https://github.com/RahVPN/rah-app/releases/download/v0.2.4/rahvpn-linux-x86_64.tar.gz) |
