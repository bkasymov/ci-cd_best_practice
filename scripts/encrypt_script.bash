#!/bin/bash

# Путь к ansible-vault паролю
VAULT_PASSWORD_FILE=".password"

# Файлы и директории для зашифрования/расшифрования
FILES_AND_DIRS=(
  "playbooks/vars/secret.yaml"
  "playbooks/vars/hosts.ini"
  "playbooks/vpn-playbook/vpn_users.yml"
#   "some_directory"
)

encrypt_files() {
  for item in "${FILES_AND_DIRS[@]}"; do
    if [ -d "$item" ]; then
      # Зашифровать все файлы в директории
      find "$item" -type f -exec ansible-vault encrypt --vault-password-file "$VAULT_PASSWORD_FILE" {} \;
    else
      # Зашифровать файл
      ansible-vault encrypt "$item" --vault-password-file "$VAULT_PASSWORD_FILE"
    fi
  done
}

decrypt_files() {
  for item in "${FILES_AND_DIRS[@]}"; do
    if [ -d "$item" ]; then
      # Расшифровать все файлы в директории
      find "$item" -type f -exec ansible-vault decrypt --vault-password-file "$VAULT_PASSWORD_FILE" {} \;
    else
      # Расшифровать файл
      ansible-vault decrypt "$item" --vault-password-file "$VAULT_PASSWORD_FILE"
    fi
  done
}

# Проверка аргументов командной строки
if [ "$1" == "encrypt" ]; then
  encrypt_files
elif [ "$1" == "decrypt" ]; then
  decrypt_files
else
  echo "Usage: $0 [encrypt|decrypt]"
  exit 1
fi
