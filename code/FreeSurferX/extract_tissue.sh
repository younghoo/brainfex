#! /bin/bash

## Author: Yang Hu / free_learner@163.com

## Make the segment line
if [[ ! -z ${BrainFex} ]]
then
    segline=$(bash ${BrainFex}/code/ZOTHERS/make_segline.sh)
fi

## Print script usage
Usage () {
    cat <<USAGE
$segline
This script extracts tissue masks from recon-all output
$segline
Usage example:
bash $0 
        -a /home/alex/reconout
        -b /home/alex/output
        -c t1
$segline
Required arguments:
        -a: recon-all output folder
        -b: output folder to save masks
        -c: output prefix
$segline
USAGE
    exit 1
}

## Parse arguments
if [[ $# -lt 6 ]]
then
    Usage >&2
    exit 1
else
    while getopts "a:b:c:" OPT
    do
        case $OPT in
            a) ## recon-all output folder
                RECONOUT=$OPTARG
                ;;
            b) ## output folder
                OUTDIR=$OPTARG
                ;;
            c) ## output prefix
                OUTFIX=$OPTARG
                ;;
            *) ## invalid option
                echo "ERROR: Unrecognized option -$OPT $OPTARG. Please check !!!"
                exit 1
                ;;
      esac
    done
fi

## If BrainFex environment variable set?
if [[ -z ${BrainFex} ]]
then
    echo "ERROR: Please set the BrainFex environment variable !!!"
    exit 1
fi

## If INPUT/OUTPUT folders exist?
bash ${BrainFex}/code/ZOTHERS/check_inout.sh -b ${RECONOUT} -b ${OUTDIR}
if [[ $? -eq 1 ]]
then
    exit 1
fi

## Extract brain mask
mri_convert ${RECONOUT}/mri/nu.mgz ${OUTDIR}/${OUTFIX}_bfc.nii.gz
mri_binarize --i ${RECONOUT}/mri/aseg.mgz --min 1 --o ${OUTDIR}/${OUTFIX}_brainmask.nii.gz --dilate 1
mri_mask ${RECONOUT}/mri/nu.mgz ${OUTDIR}/${OUTFIX}_brainmask.nii.gz ${OUTDIR}/${OUTFIX}_brain.nii.gz

## Extract GM/WM/ventricle masks
## Note the ventricle mask including Choroid Plexus but not Fourth Ventricle
mri_binarize --i ${RECONOUT}/mri/aseg.mgz --o ${OUTDIR}/${OUTFIX}_wmmask.nii.gz --all-wm
mri_binarize --i ${RECONOUT}/mri/aseg.mgz --o ${OUTDIR}/${OUTFIX}_gmmask.nii.gz --gm
mri_binarize --i ${RECONOUT}/mri/aseg.mgz --o ${OUTDIR}/${OUTFIX}_ventmask.nii.gz --ventricles

## Check whether the output files exist
bash ${BrainFex}/code/ZOTHERS/check_inout.sh -a ${OUTDIR}/${OUTFIX}_bfc.nii.gz -a ${OUTDIR}/${OUTFIX}_brainmask.nii.gz \
    -a ${OUTDIR}/${OUTFIX}_gmmask.nii.gz -a ${OUTDIR}/${OUTFIX}_wmmask.nii.gz -a ${OUTDIR}/${OUTFIX}_ventmask.nii.gz
if [[ $? -eq 1 ]]
then
    exit 1
fi

