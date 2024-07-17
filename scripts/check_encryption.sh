#!/bin/bash

VAULT_PASSWORD_FILE=".password"
FILES_AND_DIRS=(
  "playbooks/vars/secret.yaml"
  "playbooks/vars/hosts.ini"
  "playbooks/vpn-playbook/vpn_users.yml"
)

check_encryption() {
  for item in "${FILES_AND_DIRS[@]}"; do
    if [ -f "$item" ]; then
      if ! grep -q "\$ANSIBLE_VAULT;" "$item"; then
        echo "Error: $item is not encrypted!"
        exit 1
      fi
    elif [ -d "$item" ]; then
      while IFS= read -r -d '' file; do
        if ! grep -q "\$ANSIBLE_VAULT;" "$file"; then
          echo "Error: $file in directory $item is not encrypted!"
          exit 1
        fi
      done < <(find "$item" -type f -print0)
    fi
  done
  echo "All specified files are encrypted."
  exit 0
}

check_encryption
