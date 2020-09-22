#!/bin/bash
# usage: gdown fileid /path/to/filename

fileid=$1
filename=$2

curl -sLc /tmp/gdcookie  "https://drive.google.com/uc?export=download&id=${fileid}" > /dev/null
curl -sLb /tmp/gdcookie  "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' /tmp/gdcookie`&id=${fileid}" --create-dirs -o ${filename}
rm -f /tmp/gdcookie