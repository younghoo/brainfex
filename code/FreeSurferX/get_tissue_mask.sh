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
$segline
Required arguments:
        -a: recon-all output folder
        -b: output folder to save masks
$segline
USAGE
    exit 1
}

## Parse arguments
if [[ $# -lt 4 ]]
then
    Usage >&2
    exit 1
else
    while getopts "a:b:" OPT
    do
        case $OPT in
            a) ## recon-all output folder
                RECONOUT=$OPTARG
                ;;
            b) ## output folder
                OUTDIR=$OPTARG
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
mri_convert ${RECONOUT}/mri/nu.mgz ${OUTDIR}/bfc.nii.gz
mri_binarize --i ${RECONOUT}/mri/aseg.mgz --min 1 --o ${OUTDIR}/brain_mask.nii.gz
mri_mask ${RECONOUT}/mri/nu.mgz ${OUTDIR}/brain_mask.nii.gz ${OUTDIR}/brain.nii.gz

## Extract GM/WM/ventricle masks
## Note the ventricle mask including Choroid Plexus but not Fourth Ventricle
mri_binarize --i ${RECONOUT}/mri/aseg.mgz --o ${OUTDIR}/wm_mask.nii.gz --all-wm
mri_binarize --i ${RECONOUT}/mri/aseg.mgz --o ${OUTDIR}/gm_mask.nii.gz --gm
mri_binarize --i ${RECONOUT}/mri/aseg.mgz --o ${OUTDIR}/vent_mask.nii.gz --ventricles

## Check whether the output files exist
bash ${BrainFex}/code/ZOTHERS/check_inout.sh -a ${OUTDIR}/bfc.nii.gz -a ${OUTDIR}/brain_mask.nii.gz \
    -a ${OUTDIR}/gm_mask.nii.gz -a ${OUTDIR}/wm_mask.nii.gz -a ${OUTDIR}/vent_mask.nii.gz
if [[ $? -eq 1 ]]
then
    echo "ERROR: The extraction of tissue masks failed. Please check !!!"
    exit 1
fi

