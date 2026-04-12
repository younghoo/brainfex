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
This script extracts a specified brain parcellation mask from recon-all output 
$segline
Usage example:
bash $0 
        -a /home/alex/reconout
        -b DK
        -c 1
        -d /home/alex/output
        -e t1_DK.nii.gz
$segline
Required arguments:
        -a: recon-all output folder
        -b: parcellation atlas name
        -c: atlas type (1/2: cortical/subcortical)
        -d: output folder
        -e: output filename
$segline
Parcellation atlases available: 
        1. DK
        2. Destrieux
        3. AsegN14
$segline
USAGE
    exit 1
}

## Parse arguments
if [[ $# -lt 10 ]]
then
    Usage >&2
    exit 1
else
    while getopts "a:b:c:d:e:" OPT
    do
        case $OPT in
            a) ## recon-all output folder
                RECONOUT=$OPTARG
                ;;
            b) ## parcellation atlas name
                PARCNAME=$OPTARG
                ;;
            c) ## atlas type
                ATLASTYPE=$OPTARG
                ;;
            d) ## output folder
                OUTDIR=$OPTARG
                ;;
            e) ## output filename
                OUTFILE=$OPTARG
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

## Convert parcellation from FreeSurfer's MGZ to NIFTI format
## Deal with cortical parcellation
if [[ ${ATLASTYPE} -eq 1 ]]
then
    IN_PARC=${RECONOUT}/mri/${PARCNAME}+aseg.mgz
    ## Deal with DK Atlas
    if [[ ${PARCNAME} == DK ]]
    then
        IN_PARC=${RECONOUT}/mri/aparc+aseg.mgz
    fi
    ## Deal with Destrieux Atlas
    if [[ ${PARCNAME} == Destrieux ]]
    then
        IN_PARC=${RECONOUT}/mri/aparc.a2009s+aseg.mgz
    fi
    mri_convert ${IN_PARC} ${OUTDIR}/tmpo_${PARCNAME}.nii.gz
fi
## Deal with subcortical parcellation
if [[ ${ATLASTYPE} -eq 2 ]]
then
    IN_PARC=${RECONOUT}/mri/${PARCNAME}.mgz
    ## Deal with Aseg Atlas
    if [[ ${PARCNAME} == Aseg* ]]
    then
        IN_PARC=${RECONOUT}/mri/aseg.mgz
    fi
    mri_convert ${IN_PARC} ${OUTDIR}/tmpo_${PARCNAME}.nii.gz
fi

## Select regions of interest and re-encode the region indices
FSLUT=${BrainFex}/data/atlases/${PARCNAME}/${PARCNAME}_FS_LUT.txt
if [[ ${PARCNAME} == Aseg* ]]
then
    FSLUT=${BrainFex}/data/atlases/Aseg/${PARCNAME}_FS_LUT.txt
fi
Rscript ${BrainFex}/code/FreeSurferX/ZR/extract_brain_parc.R ${OUTDIR}/tmpo_${PARCNAME}.nii.gz ${FSLUT} ${OUTDIR}/${OUTFILE}

## Remove temporary files
rm ${OUTDIR}/tmpo_${PARCNAME}.nii.gz

## Check the success of parcellation mask extraction
if [[ ! -f ${OUTDIR}/${OUTFILE} ]]
then
    echo "ERROR: the extraction of brain parcellation mask failed. Please check !!!"
    exit 1
fi

