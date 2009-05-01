#!/bin/bash

if [ -z "${1}" ]; then
  echo
  echo "Usage:  ${0} [ your module name ]"
  echo
  echo "Gathers Webmin module cgi scripts and other required module files in this directory and"
  echo "packs them into a Webmin module tar package with the name and a date/ time stamp."
  echo "The resulting wbm package is saved into your home directory"
  echo
  exit 1
fi


#name='ddclient'
name=$1

dest_dir=`echo $HOME`

stamp=`date +%Y-%m-%d-%H%M`

#files="*.cgi *.pl *.info help/ images/ lang/ config-* defaultacl"
files="*"

mkdir ../${name}/
cp -r ${files} ../${name}/
#tar -zcf ../tars/${name}-${stamp}.wbm.gz ${name}
tar -zcf ${dest_dir}/${name}-${stamp}.wbm.gz ../${name}
rm -rf ../${name} 
