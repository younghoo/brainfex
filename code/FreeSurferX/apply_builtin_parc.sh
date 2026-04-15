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
This script applies a built-in surface parcellation atlas to the subject's cortex.
$segline
Usage example:
bash $0 
        -a /home/alex/reconout
        -b DK
        -c 1
$segline
Required arguments:
        -a: recon-all output folder
        -b: parcellation atlas name
        -c: atlas type (1/2: cortical/subcortical)
$segline
Cortical parcellations available: 
        1. DK
        2. Destrieux
Subcortical parcellations available:
        1. AsegN14
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
            b) ## parcellation atlas name
                PARCNAME=$OPTARG
                ;;
            c) ## atlas type
                ATLASTYPE=$OPTARG
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

## Deal with cortical parcellation
if [[ ${ATLASTYPE} -eq 1 ]]
then
    ## Deal with DK Atlas
    if [[ ${PARCNAME} == DK ]]
    then
        cd ${RECONOUT}/label
        ln -s lh.aparc.annot lh.${PARCNAME}.annot
        ln -s rh.aparc.annot rh.${PARCNAME}.annot
        cd ${RECONOUT}/mri
        ln -s aparc+aseg.mgz ${PARCNAME}+aseg.mgz
        cd ${RECONOUT}/stats
        ln -s lh.aparc.stats lh.${PARCNAME}.stats
        ln -s rh.aparc.stats rh.${PARCNAME}.stats
    fi
    ## Deal with Destrieux Atlas
    if [[ ${PARCNAME} == Destrieux ]]
    then
        cd ${RECONOUT}/label
        ln -s lh.aparc.a2009s.annot lh.${PARCNAME}.annot
        ln -s rh.aparc.a2009s.annot rh.${PARCNAME}.annot
        cd ${RECONOUT}/mri
        ln -s aparc.a2009s+aseg.mgz ${PARCNAME}+aseg.mgz
        cd ${RECONOUT}/stats
        ln -s lh.aparc.a2009s.stats lh.${PARCNAME}.stats
        ln -s rh.aparc.a2009s.stats rh.${PARCNAME}.stats
    fi
fi

## Deal with subcortical parcellation
if [[ ${ATLASTYPE} -eq 2 ]]
then
    ## Deal with Aseg Atlas
    if [[ ${PARCNAME} == Aseg* ]]
    then
        cd ${RECONOUT}/mri
        ln -s aseg.mgz ${PARCNAME}.mgz
        cd ${RECONOUT}/stats
        ln -s aseg.stats ${PARCNAME}.stats
    fi
fi

## Check whether the output files exist
if [[ ${ATLASTYPE} -eq 1 ]]
then
    bash ${BrainFex}/code/ZOTHERS/check_inout.sh -a ${RECONOUT}/label/lh.${PARCNAME}.annot -a ${RECONOUT}/label/rh.${PARCNAME}.annot \
        -a ${RECONOUT}/mri/${PARCNAME}+aseg.mgz -a ${RECONOUT}/stats/lh.${PARCNAME}.stats -a ${RECONOUT}/stats/rh.${PARCNAME}.stats
else
    bash ${BrainFex}/code/ZOTHERS/check_inout.sh -a ${RECONOUT}/mri/${PARCNAME}.mgz -a ${RECONOUT}/stats/${PARCNAME}.stats 
fi
if [[ $? -eq 1 ]]
then
    echo "ERROR: The parcellation of built-in atlases failed. Please check !!!"
    exit 1
fi

