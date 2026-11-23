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

Выполните в SSH-консоли роутера от `root`:

```sh
installer=$(mktemp /tmp/ssh-tunnel-install.XXXXXX) &&
  wget -T 15 -O "$installer" https://raw.githubusercontent.com/SSHVPN-Connect/SshVPN-openwrt/main/scripts/install.sh &&
  sh "$installer"
```

Скрипт определяет версию OpenWrt и платформу, скачивает подходящий пакет,
проверяет SHA-256 и устанавливает пакет с зависимостями. Если адрес релиза
недоступен, скрипт пробует скачать пакет через GitHub API.

Если роутер не может скачать сам скрипт по ссылке выше, скопируйте
[install.sh](scripts/install.sh) в `/tmp` и выполните `sh /tmp/install.sh`.

Пакеты для ручной установки доступны в релизах
[24.10.4](https://github.com/SSHVPN-Connect/SshVPN-openwrt/releases/tag/openwrt-24.10.4),
[25.12.5](https://github.com/SSHVPN-Connect/SshVPN-openwrt/releases/tag/v0.1.0) и
[25.12.6](https://github.com/SSHVPN-Connect/SshVPN-openwrt/releases/tag/openwrt-25.12.6).
Для другой версии прошивки используйте соответствующий SDK.

После установки откройте **Сеть → Интерфейсы → Добавить интерфейс → SSH Tunnel**.

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

### Код «Поделиться»

В поле **Connection method** выберите **Use an invitation code** и вставьте
полную строку из меню «Поделиться» в поле **Share invitation code**. На
сервере должна быть включена поддержка приглашений из клиента владельца.
Приглашение одноразовое и действует 30 минут. При первом запуске интерфейса
роутер активирует его на сервере, создаёт постоянный ключ и сохраняет профиль.
После активации поле кода очищается.
SSH-порт по умолчанию — `22`; если сервер использует другой порт, укажите его
в поле **SSH port**.

### Прямое подключение

В поле **Connection method** выберите **Enter SSH credentials manually**.
Для автоматической настройки сервера нужен SSH-доступ под пользователем
`root`. Укажите адрес и порт, а также пароль либо путь к приватному ключу,
который уже находится на роутере и доступен пользователю root.

Имя сетевого устройства назначается автоматически. Пакет использует адреса
`172.31.255.2/30` на роутере и `172.31.255.1` на сервере. Серверная часть
допускает одно активное подключение одновременно.
