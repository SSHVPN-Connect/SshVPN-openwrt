# SSH Tunnel for OpenWrt

[Русский](README.md) | [English](README.en.md)

Добавляет протокол **SSH Tunnel** в LuCI: **Сеть → Интерфейсы → Добавить
интерфейс**. Подключение создаёт TUN-интерфейс, который можно выбрать в Podkop.
Маршрут по умолчанию интерфейс не меняет.

Это клиент SSH VPN из проекта
[SshVPN-openwrt](https://github.com/SSHVPN-Connect/SshVPN-openwrt),
использующий серверную часть
[sshvpn-client](https://github.com/SSHVPN-Connect/sshvpn-client).

## Установка

1. Откройте [релизы](https://github.com/SSHVPN-Connect/SshVPN-openwrt/releases)
   и скачайте APK, соответствующий версии OpenWrt, архитектуре, target и
   subtarget вашего устройства. Имена файлов содержат эти значения. Например,
   для Xiaomi Mi Router AX3000T ищите файл с `mediatek_filogic` в имени.
2. Скопируйте файл на роутер, например в `/tmp`, и установите:

   ```sh
   apk add --allow-untrusted /tmp/<имя-файла>.apk
   ```

3. В LuCI создайте интерфейс: **Сеть → Интерфейсы → Добавить интерфейс → SSH Tunnel**.

Версию, архитектуру и target/subtarget можно посмотреть командой
`cat /etc/openwrt_release`. Для прошивок с `opkg` соберите пакет из
соответствующего SDK и установите полученный `.ipk` командой `opkg install`.

## Сборка

Используйте OpenWrt SDK той же версии, target и subtarget, что и прошивка
устройства. SDK доступны в
[каталоге загрузок OpenWrt](https://downloads.openwrt.org/).

На Linux установите зависимости сборки (Debian/Ubuntu):

```sh
sudo apt update
sudo apt install build-essential gawk gettext git libncurses-dev libssl-dev python3 rsync unzip zstd
```

Распакуйте SDK, клонируйте этот репозиторий и выполните из его корня:

```sh
./scripts/build-sdk.sh /path/to/openwrt-sdk
```

APK или IPK появится в `dist/`. Чтобы указать другой каталог вывода:

```sh
./scripts/build-sdk.sh /path/to/openwrt-sdk ./build-output
```

## Настройка

При первом подключении пакет настраивает SSH VPN сервер. Нужен SSH-доступ к
серверу под пользователем `root`. В форме интерфейса укажите адрес, порт и
пароль либо путь к приватному ключу, который уже находится на роутере и
доступен пользователю root.

Имя сетевого устройства назначается автоматически. Пакет использует адреса
`172.31.255.2/30` на роутере и `172.31.255.1` на сервере. Серверная часть
допускает одно активное подключение одновременно.
