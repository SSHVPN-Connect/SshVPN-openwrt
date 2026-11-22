# OpenWrt SSH Tunnel

Пакет добавляет в LuCI → **Сеть → Интерфейсы → Добавить интерфейс** протокол
**SSH Tunnel**. Создаваемый интерфейс не устанавливает маршрут по умолчанию;
его можно выбрать в Podkop как выходной интерфейс.

Это SSH VPN с TUN, реализованный в существующем проекте. Это не `ss://`
Shadowsocks. Интерфейс OpenWrt соединяет локальный TUN с тем же обработчиком,
который использует Windows-клиент.

## Готовый пакет

В каталоге [`dist/`](dist/) находится
[APK для OpenWrt 25.12.5 / mediatek/filogic](dist/luci-proto-ssh-tunnel-0.1.0-r1.apk)
(например, Xiaomi Mi Router AX3000T). Установка на роутере:

```sh
apk add --allow-untrusted /tmp/luci-proto-ssh-tunnel-0.1.0-r1.apk
```

Сначала скопируйте APK в `/tmp` по SSH или через LuCI. Настроенные репозитории
прошивки должны быть доступны: менеджер пакетов установит зависимости
`luci-base`, `netifd`, `kmod-tun`, `openssh-client`, `sshpass` и `python3-light`.

## Сборка для своей версии и платформы

Пакет состоит из скриптов LuCI/netifd и не содержит машинного кода, поэтому сам
пакет имеет архитектуру `all` (в APK она отображается как `noarch`). Но для
сборки всё равно используйте SDK, соответствующий **версии OpenWrt, target и
subtarget** роутера. У SDK свои feeds, ABI и метаданные зависимостей; модуль
`kmod-tun` и остальные зависимости должны подходить конкретной прошивке.

### 1. Узнайте версию и target роутера

Подключитесь к роутеру по SSH и выполните:

```sh
cat /etc/openwrt_release
```

Найдите `DISTRIB_RELEASE` и `DISTRIB_TARGET`. Например:

```text
DISTRIB_RELEASE='25.12.5'
DISTRIB_TARGET='mediatek/filogic'
```

Здесь `mediatek` — target, `filogic` — subtarget. Используйте их из прошивки,
а не архитектуру процессора из `uname -m`.

### 2. Скачайте подходящий SDK

Откройте каталог загрузок именно для своей версии и target:

```text
https://downloads.openwrt.org/releases/<ВЕРСИЯ>/targets/<TARGET>/<SUBTARGET>/
```

Скачайте оттуда архив `openwrt-sdk-...Linux-x86_64.tar.*` и распакуйте его на
Linux-сборщике. Имя SDK содержит версию, target/subtarget и toolchain, поэтому
не подставляйте имя архива от другой платформы. Для snapshot используйте SDK
из каталога `snapshots/targets/...` и по возможности сборку, совпадающую с
ревизией прошивки.

Пример для AX3000T с OpenWrt 25.12.5:

```text
https://downloads.openwrt.org/releases/25.12.5/targets/mediatek/filogic/
```

В этом каталоге выберите актуальный для нужной сборки SDK. Для релизных версий
выбирайте SDK из той же версии OpenWrt, что установлена на роутере.

### 3. Соберите пакет

На Linux установите инструменты для распаковки и сборки (например, в Debian или
Ubuntu):

```sh
sudo apt update
sudo apt install build-essential gawk gettext git libncurses-dev libssl-dev python3 rsync unzip zstd
```

Распакуйте SDK (`tar --zstd -xf openwrt-sdk-...tar.zst`) и клонируйте этот
репозиторий на сборщик. Из корня репозитория выполните:

```sh
./scripts/build-sdk.sh /путь/к/распакованному/openwrt-sdk
```

Скрипт копирует `luci-proto-ssh-tunnel/` в SDK, собирает только этот пакет и
копирует результат в `dist/`. Можно указать другой каталог вывода вторым
аргументом:

```sh
./scripts/build-sdk.sh /путь/к/openwrt-sdk ./build-output
```

SDK сам выберет формат файла: OpenWrt **24.10 и старше** используют `.ipk` и
`opkg`, а OpenWrt **25.12 и новее** — `.apk` и `apk`. Установка на роутере:

```sh
# OpenWrt 24.10 и старше
opkg install /tmp/luci-proto-ssh-tunnel-*.ipk

# OpenWrt 25.12 и новее
apk add --allow-untrusted /tmp/luci-proto-ssh-tunnel-*.apk
```

Поддерживается любая архитектура, для которой в официальном каталоге OpenWrt
есть SDK. При этом готовый пакет, собранный для одного релиза, не следует
считать заменой пакета для другой версии: пересоберите его с соответствующим
SDK и устанавливайте зависимости из репозиториев своей прошивки. Не
устанавливайте APK на системы с `opkg` и IPK на системы с `apk`.

## Подключение к SSH-серверу

При первом подключении пакет запускает `install-server.sh` через SSH. Нужен
доступ пользователем `root` на Debian/Ubuntu. В форме LuCI можно указать пароль
либо путь к приватному ключу, уже установленному на роутере. Первый ключ
SSH-сервера автоматически принимается в `known_hosts` пользователя root.

Интерфейс использует адреса `172.31.255.2/30` и `172.31.255.1`. На удалённом
сервере одновременно поддерживается одно подключение, как и в Windows-клиенте.
