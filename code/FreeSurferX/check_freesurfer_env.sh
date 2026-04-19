#! /bin/bash

## Author: Yang Hu / free_learner@163.com

## This script checks whether FreeSurfer is installed and the exact version

## If FreeSurfer installed?
if [[ ! -z ${FREESURFER_HOME} ]]
then
    Version=$(cat ${FREESURFER_HOME}/build-stamp.txt | cut -d '-' -f4)
    echo $Version
else
    echo "Please install FreeSurfer !!!"
    exit 1
fi

