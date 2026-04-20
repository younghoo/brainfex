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
This script extracts subcortical volume from recon-all output and a parcellation atlas
$segline
Usage example:
bash $0 
        -a /home/alex/reconout
        -b AsegN14
        -c /home/alex/output
        -d AsegN14_volume.txt
$segline
Required arguments:
        -a: recon-all output folder
        -b: parcellation atlas name
        -c: output folder
        -d: output filename
$segline
Subcortical parcellations available: 
        1. AsegN14: 14 structures from Aseg Atlas including bilateral caudate, putamen, pallidum, hippocampus, amygdala and accumbens
$segline
USAGE
    exit 1
}

## Parse arguments
if [[ $# -lt 8 ]]
then
    Usage >&2
    exit 1
else
    while getopts "a:b:c:d:" OPT
    do
        case $OPT in
            a) ## recon-all output folder
                RECONOUT=$OPTARG
                ;;
            b) ## parcellation atlas name
                PARCNAME=$OPTARG
                ;;
            c) ## output folder
                OUTDIR=$OPTARG
                ;;
            d) ## output filename
                OUTFILE=$OPTARG
                ;;
            *) ## invalid option
                echo "BrainFex Error: Unrecognized option -$OPT $OPTARG. Please check !!!"
                exit 1
                ;;
      esac
    done
fi

## If BrainFex environment variable set?
if [[ -z ${BrainFex} ]]
then
    echo "BrainFex Error: Please set the BrainFex environment variable !!!"
    exit 1
fi

## If INPUT/OUTPUT folders exist?
bash ${BrainFex}/code/ZOTHERS/check_inout.sh -b ${RECONOUT} -b ${OUTDIR}
if [[ $? -eq 1 ]]
then
    exit 1
fi

## Set FreeSurfer environment variables
export SUBJECTS_DIR=$(dirname ${RECONOUT})
SUBJECT=$(basename ${RECONOUT})

## Extract volume
asegstats2table --subjects ${SUBJECT} --meas volume --stats ${PARCNAME}.stats --tablefile ${OUTDIR}/tmpo_${PARCNAME}_volume.txt
Rscript ${BrainFex}/code/FreeSurferX/ZR/clean_subcort_volume.R ${PARCNAME} ${OUTDIR}/tmpo_${PARCNAME}_volume.txt ${OUTDIR}/${OUTFILE}

## Remove intermediate files
rm ${OUTDIR}/tmpo_${PARCNAME}_volume.txt

## Check the success of volume extraction
if [[ ! -f ${OUTDIR}/${OUTFILE} ]]
then
    echo "BrainFex Error: The extraction of subcortical volume failed. Please check !!!"
    exit 1
fi

