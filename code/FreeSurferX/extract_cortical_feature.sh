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
        -b DK
        -c thickness
        -d /home/alex/output
        -e DK_thickness.txt
$segline
Required arguments:
        -a: recon-all output folder
        -b: parcellation atlas name
        -c: cortical feature name
        -d: output folder
        -e: output filename
$segline
Cortical arcellations available: 
        1. DK
        2. Destrieux
Cortical features available: 
        1. thickness, mean thickness
        2. area, surface area
        3. volume, gray matter volume
        4. meancurv, integrated rectified mean curvature
        5. gauscurv, integrated rectified gaussian curvature
        6. foldind, folding index
        7. curvind, intrinsic curvature index
        8. sulc, mean sulcal depth
        9. pial_lgi, mean LGI
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

## Calculate LGI feature if required
if [[ ${MEASNAME} == 'pial_lgi' ]]
then
    if [[ ! -f ${RECONOUT}/surf/lh.pial_lgi ]] || [[ ! -f ${RECONOUT}/surf/rh.pial_lgi ]]
    then
        bash ${BrainFex}/code/FreeSurferX/calc_LGI.sh -a ${RECONOUT}
    fi
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
Rscript ${BrainFex}/code/FreeSurferX/ZR/clean_cortical_feature.R ${OUTDIR}/lh_${PARCNAME}_${MEASNAME}.txt ${OUTDIR}/rh_${PARCNAME}_${MEASNAME}.txt ${OUTDIR}/${OUTFILE}

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

