#!/bin/bash

if [[ "${1}" == "-?" ]] || [[ "${1}" == "-h" ]] || [[ "${1}" == "--help" ]]; then
  echo
  echo "Usage:  ${0}"
  echo
  echo "Gathers Webmin module cgi scripts and other required module files in this directory and"
  echo "packs them into a Webmin module tar package with the name and a date/ time stamp."
  echo "The resulting wbm package is saved into the current directory."
  echo
  exit 1
fi

set -e

name="vsftpd"
stamp=`date +%Y-%m-%d`
tarball="$name-$stamp.wbm.gz"

files="*.cgi *.pl *.info docs/ help/ images/ lang/ libvsftpdconfig/ COPYING config defaultacl vsftpd_pam_d_template"

echo "Creating distribution tarball $tarball ..."

mkdir ./${name}
cp -r ${files} ./${name}/
tar -zcf ./${tarball} ./${name}
rm -rf ./${name} 
