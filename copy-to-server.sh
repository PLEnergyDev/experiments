#!/bin/bash

dir_to_copy="$1"
tar_copy="$dir_to_copy.tar.gz"
remote_path="/home/dragos/RAPL/experiments"

if [[ ! -d "$dir_to_copy" ]]; then
    echo "Dir '$dir_to_copy' doesn't exist"
    exit 1
fi

tar --exclude="*results*" -czvf "$tar_copy" "$dir_to_copy"
scp "$tar_copy" aau:"$remote_path"
ssh -t aau "sudo bash -c 'cd $remote_path; tar -xzf $tar_copy; rm $tar_copy; chown -R dragos:dragos $remote_path/$dir_to_copy'"
rm "$tar_copy"
