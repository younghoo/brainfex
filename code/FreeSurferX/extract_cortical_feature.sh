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
This script extracts cortical features from recon-all output and a parcellation atlas
$segline
Usage example:
bash $0 
        -a /home/alex/reconout
        -b Schaefer
        -c thickness
        -d /home/alex/output
        -e Schaefer_ThickAvg.txt
$segline
Required arguments:
        -a: recon-all output folder
        -b: parcellation atlas name
        -c: cortical feature name
        -d: output folder
        -e: output filename
$segline
Parcellation atlases available: 
        1. DK
        2. Destrieux
$segline
Cortical features available: 
        1. thickness
        2. area
        3. volume
        4. meancurv
        5. gauscurv
        6. foldind
        7. curvind
        8. sulc
        9. pial_lgi
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
            c) ## cortical feature name
                MEASNAME=$OPTARG
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

## Deal with atlas names of default parcellations in FreeSurfer
## Reference: https://surfer.nmr.mgh.harvard.edu/fswiki/CorticalParcellation
## In recon-all, "aparc" stands for the DK Atlas.
if [[ ${PARCNAME} == 'DK' ]]
then
    PARCNAME=aparc
fi
## In recon-all, "aparc.a2009s" stands for the Destrieux Atlas.
if [[ ${PARCNAME} == 'Destrieux' ]]
then
    PARCNAME=aparc.a2009s
fi

## Set FreeSurfer environment variables
export SUBJECTS_DIR=$(dirname ${RECONOUT})
SUBJECT=$(basename ${RECONOUT})

## Extract data for each hemisphere
if [[ ${MEASNAME} != 'sulc' ]] && [[ ${MEASNAME} != 'pial_lgi' ]]
then
    for curr_hemi in lh rh
    do
        aparcstats2table --subjects ${SUBJECT} --hemi ${curr_hemi} --parc ${PARCNAME} --meas ${MEASNAME} \
            --tablefile ${OUTDIR}/${curr_hemi}_${PARCNAME}_${MEASNAME}.txt
    done
else
    for curr_hemi in lh rh
    do
        mris_anatomical_stats -mgz -cortex ${SUBJECTS_DIR}/${SUBJECT}/label/${curr_hemi}.cortex.label \
            -f ${SUBJECTS_DIR}/${SUBJECT}/stats/${curr_hemi}.${PARCNAME}.${MEASNAME}.stats -b \
            -a ${SUBJECTS_DIR}/${SUBJECT}/label/${curr_hemi}.${PARCNAME}.annot -t ${MEASNAME} ${SUBJECT} ${curr_hemi} white
        aparcstats2table --subjects ${SUBJECT} --hemi ${curr_hemi} --parc ${PARCNAME}.${MEASNAME} --meas thickness \
            --tablefile ${OUTDIR}/${curr_hemi}_${PARCNAME}_${MEASNAME}.txt
    done
fi

## Combine lh and rh features, and remove uninteresting data
Rscript ${BrainFex}/code/FreeSurferX/ZR/merge_cortical_feature.R ${OUTDIR}/lh_${PARCNAME}_${MEASNAME}.txt ${OUTDIR}/rh_${PARCNAME}_${MEASNAME}.txt ${OUTDIR}/${OUTFILE}

## Remove intermediate files
rm ${OUTDIR}/?h_${PARCNAME}_${MEASNAME}.txt
if [[ ${MEASNAME} == 'sulc' ]] || [[ ${MEASNAME} == 'pial_lgi' ]]
then
    rm ${SUBJECTS_DIR}/${SUBJECT}/stats/?h.${PARCNAME}.${MEASNAME}.stats
fi

## Check the success of feature extraction
if [[ ! -f ${OUTDIR}/${OUTFILE} ]]
then
    echo "ERROR: the extraction of cortical feature failed. Please check !!!"
    exit 1
fi

