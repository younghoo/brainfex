#! /bin/bash

## Author: Yang Hu / free_learner@163.com

## This script checks the running environment

## If BrainFex environment variable set?
if [[ -z ${BrainFex} ]]
then
    echo "BrainFex Error: Please set the BrainFex environment variable !!!"
    exit 1
else
    segline=$(bash ${BrainFex}/code/ZOTHERS/make_segline.sh)
fi

## Check the OS
echo $segline
uname -a

## Check dependent general software packages (non-exhaustive, skip those typically pre-installed by system)
echo $segline
Rscript -e "cat(R.version.string, '\n')"
echo "stringr: $(Rscript -e "cat(as.character(packageVersion('stringr')))")"
echo "RNifti: $(Rscript -e "cat(as.character(packageVersion('RNifti')))")"

## Check dependent neuroimaging software packages
echo $segline
echo "FreeSurfer: $(bash ${BrainFex}/code/FreeSurferX/check_freesurfer_env.sh)"
echo "FSL: $(bash ${BrainFex}/code/FSLX/check_fsl_env.sh)"

## Check BrainFex
echo $segline
echo "BrainFex: $(cat ${BrainFex}/VERSION)"
echo $segline

