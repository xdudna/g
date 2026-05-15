#!/bin/bash

G_PATH=$(which g 2>/dev/null || true)
NEW_VER=$(sed -n 's/^version="\(.*\)"$/\1/p' "$(dirname "$0")/g")

if [ -z "$NEW_VER" ]; then
  echo "Error: cannot read version from g script."
  exit 1
fi

if [ -n "$G_PATH" ]; then
  OLD_VER=$(sed -n 's/^version="\(.*\)"$/\1/p' "$G_PATH" 2>/dev/null)

  if [ -n "$OLD_VER" ] && [ "$OLD_VER" != "$NEW_VER" ]; then
    echo "Current version: $OLD_VER"
    echo "New version:     $NEW_VER"

    higher=$(echo -e "$OLD_VER\n$NEW_VER" | sort -V | tail -1)
    if [ "$higher" = "$NEW_VER" ]; then
      echo "Newer version available."
    else
      echo "Installed version is newer. Downgrade?"
    fi

    read -p "Install anyway? [y/N] " ans
    case "$ans" in
      y|Y) ;;
      *) echo "Install cancelled."; exit 0 ;;
    esac
  fi

  cp "$(dirname "$0")/g" "$G_PATH"
  echo "g installed to $G_PATH"
else
  echo "g not found via 'which g'."
  echo "Install manually: cp \"$(dirname "$0")/g\" /usr/local/bin/g"
  exit 1
fi
