#!/usr/bin/env bash

#set -euo

THIS_DIR=$(cd "$(dirname "$0")"; pwd)
cd "$THIS_DIR"

update() {
  git pull
  git submodule update --init --recursive
  install_rocks
}

# Will install luarocks on THIS_DIR/.luarocks
install_luarocks() {
  git clone https://github.com/keplerproject/luarocks.git
  cd luarocks
  git checkout tags/v2.3.0 # Current stable

  PREFIX="$THIS_DIR/.luarocks"

  ./configure --prefix="$PREFIX" --sysconfdir="$PREFIX"/luarocks --force-config

  RET=$?
  if [ $RET -ne 0 ]; then
    printf '\e[1;31m%s\n\e[0;39;49m' 'Error. Exiting.'
    exit $RET
  fi

  make build && make install
  RET=$?
  if [ $RET -ne 0 ]; then
    printf '\e[1;31m%s\n\e[0;39;49m' 'Error. Exiting.'
    exit $RET
  fi

  cd ..
  rm -rf luarocks
}

install_rocks() {
  ./.luarocks/bin/luarocks install lbase64 20120807-3
  RET=$?
  if [ $RET -ne 0 ]; then
    printf '\e[1;31m%s\n\e[0;39;49m' 'Error. Exiting.'
  exit $RET
  fi
  for i in luasec luasocket oauth redis-lua lua-cjson fakeredis xml feedparser serpent; do
    ./.luarocks/bin/luarocks install "$i"
    RET=$?
    if [ $RET -ne 0 ]; then
      printf '\e[1;31m%s\n\e[0;39;49m' 'Error. Exiting.'
      exit $RET
    fi
  done
}

merbot_upstart() {
  printf '%s\n' "
description 'Merbots upstart script.'

respawn
respawn limit 15 5

start on runlevel [2345]
stop on shutdown

setuid $(whoami)
exec /bin/sh $(pwd)/merbot
" | sudo tee /etc/init/merbot.conf > /dev/null

  [[ -f /etc/init/merbot.conf ]] && printf '%s\n' '

  Upstart script installed to /etc/init/merbot.conf.
  Now you can:
  Start merbot with     : sudo start merbot
  See merbot status with: sudo status merbot
  Stop merbot with      : sudo stop merbot

'
}

tgcli_config() {
  mkdir -p "$THIS_DIR"/.telegram-cli
  printf '%s\n' "
default_profile = \"default\";

default = {
  config_directory = \"$THIS_DIR/.telegram-cli\";
  auth_file = \"$THIS_DIR/.telegram-cli/auth\";
  test = false;
  msg_num = true;
  log_level = 2;
};
" > "$THIS_DIR"/data/tg-cli.config
}

install() {
  git pull
  git submodule update --init --recursive
  patch -i 'patches/merbot.patch' -p 0 --batch --forward
  RET=$?;

  cd tg
  if [ $RET -ne 0 ]; then
    autoconf -i
  fi
  ./configure && make

  RET=$?
  if [ $RET -ne 0 ]; then
    printf '\e[1;31m%s\n\e[0;39;49m' 'Error. Exiting.'
    exit $RET
  fi
  cd ..
  install_luarocks
  install_rocks
  tgcli_config
}

if [[ "$1" = "install" ]]; then
  install
elif [[ "$1" = "update" ]]; then
  update
elif [[ "$1" = "upstart" ]]; then
  merbot_upstart
else
  if [[ ! -f ./tg/telegram.h ]]; then
    printf '\e[1;31m%s\n\e[0;39;49m' '  tg not found' "  Run $0 install"
    exit 1
  fi

  if [[ ! -f ./tg/bin/telegram-cli ]]; then
    printf '\e[1;31m%s\n\e[0;39;49m' '  tg binary not found' "  Run $0 install"
    exit 1
  fi

  ./tg/bin/telegram-cli -k ./tg/tg-server-pub --disable-link-preview -s ./bot/bot.lua -l 1 -E -c ./data/tg-cli.config -p default "$@"
fi
