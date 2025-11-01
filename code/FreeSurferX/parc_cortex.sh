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
This script parcellates the cortex based on recon-all output and a parcellation atlas
$segline
Usage example:
bash $0 
        -a /home/alex/reconout
        -b 1
        -c /home/alex/lh.Schaefer.annot
        -d /home/alex/rh.Schaefer.annot
        -e Schaefer
$segline
Required arguments:
        -a: recon-all output folder
        -b: atlas type (1/2: annot file/gcs file)
        -c: left annot or gcs file
        -d: right annot or gcs file
        -e: output prefix
Optional arguments:
        -f: map from surface to volume space (1/0; default 1)
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
    while getopts "a:b:c:d:e:f:" OPT
    do
      case $OPT in
            a) ## recon-all output folder
                RECONOUT=$OPTARG
            ;;
            b) ## atlas file type
                ATLASTYPE=$OPTARG
            ;;
            c) ## left atlas file
                LHFILE=$OPTARG
            ;;
            d) ## right atlas file
                RHFILE=$OPTARG
            ;;
            e) ## output prefix
                OUTFIX=$OPTARG
            ;;
            f) ## map from surface to volume space
                SURF2VOL=$OPTARG
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
bash ${BrainFex}/code/ZOTHERS/check_inout.sh -b ${RECONOUT}
if [[ $? -eq 1 ]]
then
    exit 1
fi

## If map cortical parcellation to volume space
if [[ -z ${SURF2VOL} ]]
then
    SURF2VOL=1
fi

## Set FreeSurfer environment variables
export SUBJECTS_DIR=$(dirname ${RECONOUT})
SUBJECT=$(basename ${RECONOUT})

## Parcellate the cortex using annot files
if [[ ATLASTYPE -eq 1 ]]
then
    ln -s ${FREESURFER_HOME}/subjects/fsaverage ${SUBJECTS_DIR}/fsaverage
    for curr_hemi in lh rh
    do  
        if [[ $curr_hemi == 'lh' ]]
        then
            CURRFILE=${LHFILE}
        else
            CURRFILE=${RHFILE}
        fi
        mri_surf2surf --srcsubject fsaverage --trgsubject $SUBJECT --hemi ${curr_hemi} --sval-annot ${CURRFILE} \
            --tval ${SUBJECTS_DIR}/${SUBJECT}/label/${curr_hemi}.${OUTFIX}.annot
        ## Calculate summary statistics of morphological features based on the parcellation result
        mris_anatomical_stats -mgz -cortex ${SUBJECTS_DIR}/${SUBJECT}/label/${curr_hemi}.cortex.label \
            -f ${SUBJECTS_DIR}/${SUBJECT}/stats/${curr_hemi}.${OUTFIX}.stats -b \
            -a ${SUBJECTS_DIR}/${SUBJECT}/label/${curr_hemi}.${OUTFIX}.annot ${SUBJECT} ${curr_hemi} white
    done
    rm ${SUBJECTS_DIR}/fsaverage
fi

## Parcellate the cortex using gcs files
if [[ ATLASTYPE -eq 2 ]]
then
    for curr_hemi in lh rh
    do
        if [[ $curr_hemi == 'lh' ]]
        then
            CURRFILE=${LHFILE}
        else
            CURRFILE=${RHFILE}
        fi        
        mris_ca_label -l ${SUBJECTS_DIR}/${SUBJECT}/label/${curr_hemi}.cortex.label ${SUBJECT} ${curr_hemi} \
            ${SUBJECTS_DIR}/${SUBJECT}/surf/${curr_hemi}.sphere.reg ${CURRFILE} ${SUBJECTS_DIR}/${SUBJECT}/label/${curr_hemi}.${OUTFIX}.annot
        mris_anatomical_stats -mgz -cortex ${SUBJECTS_DIR}/${SUBJECT}/label/${curr_hemi}.cortex.label \
            -f ${SUBJECTS_DIR}/${SUBJECT}/stats/${curr_hemi}.${OUTFIX}.stats -b \
            -a ${SUBJECTS_DIR}/${SUBJECT}/label/${curr_hemi}.${OUTFIX}.annot ${SUBJECT} ${curr_hemi} white
      done
fi

## Map cortical parcellation to volume space
if [[ $SURF2VOL -eq 1 ]]
then
    mri_aparc2aseg --s ${SUBJECT} --o ${SUBJECTS_DIR}/${SUBJECT}/mri/${OUTFIX}+aseg.mgz --volmask --annot ${OUTFIX}
fi

## Check whether the output files exist
bash ${BrainFex}/code/ZOTHERS/check_inout.sh \
    -a ${SUBJECTS_DIR}/${SUBJECT}/label/lh.${OUTFIX}.annot \
    -a ${SUBJECTS_DIR}/${SUBJECT}/label/rh.${OUTFIX}.annot \
    -a ${SUBJECTS_DIR}/${SUBJECT}/stats/lh.${OUTFIX}.stats \
    -a ${SUBJECTS_DIR}/${SUBJECT}/stats/rh.${OUTFIX}.stats
if [[ $? -eq 1 ]]
then
    exit 1
fi

## If map to volume space, check the additional output file
if [[ $SURF2VOL -eq 1 ]]
then
    bash ${BrainFex}/code/ZOTHERS/check_inout.sh -a ${SUBJECTS_DIR}/${SUBJECT}/mri/${OUTFIX}+aseg.mgz
fi
if [[ $? -eq 1 ]]
then
    exit 1
fi