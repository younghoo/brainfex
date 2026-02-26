#! /bin/bash

## Author: Yang Hu / free_learner@163.com

## This script checks whether FSL is installed and the exact version

## If FSL installed?
if [[ ! -z ${FSLDIR} ]]
then
    Version=$(cat ${FSLDIR}/etc/fslversion)
    echo $Version
else
    echo "Please install FSL !!!"
    exit 1
fi

