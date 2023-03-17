#!/bin/bash
#$1 : KEY PATH/FILE
#$2 : KEY NAME

#$1 : PROJECT NAME

#set -e


SSH_DIR="$HOME/.ssh/"
PROJECT_NAME=$1
KEY_NAME="$1_ec2"
PROJECT_SSH_DIR="$SSH_DIR/$PROJECT_NAME"
PROJECT_SSH_KEY_NAME="$SSH_DIR/$PROJECT_NAME/$KEY_NAME"

echo "$SSH_DIR"
echo "$PROJECT_NAME"
echo "$KEY_NAME"

mkdir -p "$PROJECT_SSH_DIR"

ssh-keygen -q -t rsa -b 2048 -m pem -C "$KEY_NAME" -f "$PROJECT_SSH_KEY_NAME" -N "" <<< y
mv "$PROJECT_SSH_KEY_NAME" "$PROJECT_SSH_KEY_NAME.pem"

chmod 400 "$PROJECT_SSH_KEY_NAME.pem"
ls -l "$PROJECT_SSH_DIR"

echo "importing key pair ..."

if aws ec2 import-key-pair --key-name "$KEY_NAME" --public-key-material fileb://"$PROJECT_SSH_KEY_NAME".pub;
  then
    echo "imported key pair !"
    aws ec2 describe-key-pairs --key-name "$KEY_NAME" --no-cli-pager
  else
    echo "failed to import key pair.."
    aws ec2 delete-key-pair --key-name "$KEY_NAME" && aws ec2 import-key-pair --key-name "$KEY_NAME" --public-key-material fileb://"$PROJECT_SSH_KEY_NAME".pub
fi