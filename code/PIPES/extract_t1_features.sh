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
This script extracts parcel-based features from one T1-weighted image for a single subject
$segline
Usage example:
bash $0 
        -a /home/alex/input/t1.nii.gz
        -b /home/alex/output
        -c DK,Destrieux
        -d thickness,volume
        -e AsegN14
        -f volume
$segline
Required arguments:
        -a: raw T1 image as input
        -b: output folder to save processed results
Optional arguments:
        -c: cortical parcellations
        -d: cortical features
        -e: subcortical parcellations
        -f: subcortical features
$segline
Cortical parcellations available: 
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
Subcortical parcellations available:
        1. AsegN14
Subcortical features available:
        1. volume, gray matter volume
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
    while getopts "a:b:c:d:e:f:" OPT
    do
        case $OPT in
            a) ## T1 input file
                INPUT=$OPTARG
                ;;
            b) ## output folder
                OUTDIR=$OPTARG
                ;;
            c) ## cortical parcellation names
                CTXPARCNAME=$OPTARG
                ;;
            d) ## cortical feature names
                CTXMEASNAME=$OPTARG
                ;;
            e) ## subcortical parcellation names
                SUBPARCNAME=$OPTARG
                ;;
            f) ## subcortical feature names
                SUBMEASNAME=$OPTARG
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

## If INPUT file/OUTPUT folder exist?
bash ${BrainFex}/code/ZOTHERS/check_inout.sh -a ${INPUT} -b ${OUTDIR}
if [[ $? -eq 1 ]]
then
    exit 1
fi

## Record the running environment
LOGDIR=${OUTDIR}/log
mkdir -p ${LOGDIR}
CURRDATE=$(date +%Y%m%d_%H%M%S)
LOGFILE=${LOGDIR}/run_log_${CURRDATE}.txt
bash ${BrainFex}/code/ZOTHERS/check_all_env.sh > ${LOGFILE} 2>&1

## Run recon-all pipeline
if [[ ! -d ${OUTDIR}/reconout ]]
then
    {
    bash ${BrainFex}/code/FreeSurferX/run_recon.sh -a ${INPUT} -b ${OUTDIR} -c reconout 
    } >> ${LOGFILE} 2>&1
fi

## Extract tissue masks for quality check and future use
if [[ ! -f ${OUTDIR}/qc/vent_mask.png ]]
then
    {
    mkdir -p ${OUTDIR}/masks
    mkdir -p ${OUTDIR}/qc
    bash ${BrainFex}/code/FreeSurferX/get_tissue_mask.sh -a ${OUTDIR}/reconout -b ${OUTDIR}/masks
    ## Make figures for fast quality check
    bash ${BrainFex}/code/FSLX/plot_ortho_slices.sh -a ${OUTDIR}/masks/bfc.nii.gz -b ${OUTDIR}/masks/brain_mask.nii.gz \
        -c ${OUTDIR}/qc -d brain_mask.png -g 2
    bash ${BrainFex}/code/FSLX/plot_ortho_slices.sh -a ${OUTDIR}/masks/brain.nii.gz -b ${OUTDIR}/masks/wm_mask.nii.gz \
        -c ${OUTDIR}/qc -d wm_mask.png -g 2
    bash ${BrainFex}/code/FSLX/plot_ortho_slices.sh -a ${OUTDIR}/masks/brain.nii.gz -b ${OUTDIR}/masks/vent_mask.nii.gz \
        -c ${OUTDIR}/qc -d vent_mask.png -g 4
    } >> ${LOGFILE} 2>&1
fi

## Extract Euler number as image quality feature
if [[ ! -f ${OUTDIR}/features/ZOTHERS/EulerNum.txt ]]
then
    {
    mkdir -p ${OUTDIR}/features/ZOTHERS
    bash ${BrainFex}/code/FreeSurferX/extract_Euler.sh -a ${OUTDIR}/reconout -b ${OUTDIR}/features/ZOTHERS -c EulerNum.txt
    } >> ${LOGFILE} 2>&1
fi

## Extract TIV as confounding feature
if [[ ! -f ${OUTDIR}/featuers/ZOTHERS/TIV.txt ]]
then
    {
    bash ${BrainFex}/code/FreeSurferX/extract_TIV.sh -a ${OUTDIR}/reconout -b ${OUTDIR}/features/ZOTHERS -c TIV.txt
    } >> ${LOGFILE} 2>&1
fi

## Deal with cortical features
if [[ ! -z ${CTXPARCNAME} ]] && [[ ! -z ${CTXMEASNAME} ]]
then
    {
    mkdir -p ${OUTDIR}/features/cortical
    IFS=',' read -r -a CTXPARCLIST <<< "${CTXPARCNAME}"
    IFS=',' read -r -a CTXMEASLIST <<< "${CTXMEASNAME}"
    ## Loop each parcellation
    for curr_parc in "${CTXPARCLIST[@]}"
    do
        if [[ ! -f ${OUTDIR}/qc/${curr_parc}_surface.png ]]
        then
            ## Apply the parcellation atlas to cortex
            bash ${BrainFex}/code/FreeSurferX/apply_builtin_parc.sh -a ${OUTDIR}/reconout -b ${curr_parc} -c 1
            ## Extract volume parcellation masks for quality check and future use
            bash ${BrainFex}/code/FreeSurferX/get_parc_mask.sh -a ${OUTDIR}/reconout -b ${curr_parc} -c 1 \
                -d ${OUTDIR}/masks -e ${curr_parc}.nii.gz
            ## Make figures for fast quality check
            bash ${BrainFex}/code/FreeSurferX/plot_volume_parc.sh -a ${OUTDIR}/reconout -b ${curr_parc} -c 1 \
                -d ${OUTDIR}/qc -e ${curr_parc}_mask.png
            bash ${BrainFex}/code/FreeSurferX/plot_surface_parc.sh -a ${OUTDIR}/reconout -b ${curr_parc} \
                -c ${OUTDIR}/qc -d ${curr_parc}_surface.png
        fi
        ## Loop each feature
        for curr_meas in "${CTXMEASLIST[@]}"
        do
            if [[ ! -f ${OUTDIR}/features/cortical/${curr_parc}_${curr_meas}.txt ]]
            then
                bash ${BrainFex}/code/FreeSurferX/extract_cortical_feature.sh -a ${OUTDIR}/reconout -b ${curr_parc} \
                    -c ${curr_meas} -d ${OUTDIR}/features/cortical -e ${curr_parc}_${curr_meas}.txt
            fi
        done
    done
    } >> ${LOGFILE} 2>&1
fi

## Deal with subcortical features
if [[ ! -z ${SUBPARCNAME} ]] && [[ ! -z ${SUBMEASNAME} ]]
then
    {
    mkdir -p ${OUTDIR}/features/subcort
    IFS=',' read -r -a SUBPARCLIST <<< "${SUBPARCNAME}"
    IFS=',' read -r -a SUBMEASLIST <<< "${SUBMEASNAME}"
    ## Loop each parcellation
    for curr_parc in "${SUBPARCLIST[@]}"
    do
        if [[ ! -f ${OUTDIR}/qc/${curr_parc}_mask.png ]]
        then
            ## Apply the parcellation atlas to subcortex
            bash ${BrainFex}/code/FreeSurferX/apply_builtin_parc.sh -a ${OUTDIR}/reconout -b ${curr_parc} -c 2
            ## Extract volume parcellation masks for quality check and future use
            bash ${BrainFex}/code/FreeSurferX/get_parc_mask.sh -a ${OUTDIR}/reconout -b ${curr_parc} -c 2 \
                -d ${OUTDIR}/masks -e ${curr_parc}.nii.gz
            ## Make figures for fast quality check
            bash ${BrainFex}/code/FreeSurferX/plot_volume_parc.sh -a ${OUTDIR}/reconout -b ${curr_parc} -c 2 \
                -d ${OUTDIR}/qc -e ${curr_parc}_mask.png
        fi
        ## Loop each feature
        for curr_meas in "${SUBMEASLIST[@]}"
        do
            if [[ ! -f ${OUTDIR}/features/subcort/${curr_parc}_${curr_meas}.txt ]]
            then
                bash ${BrainFex}/code/FreeSurferX/extract_subcort_volume.sh -a ${OUTDIR}/reconout -b ${curr_parc} \
                    -c ${OUTDIR}/features/subcort -d ${curr_parc}_${curr_meas}.txt
            fi
        done
    done
    } >> ${LOGFILE} 2>&1
fi

## Check potential errors
if grep -q "BrainFex Error" ${LOGFILE}
then
    echo "BrainFex Error: T1 feature extraction failed. Please check !!!"
    exit 1
fi

