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
This script calculates local gyrification index (LGI)
$segline
Usage example:
bash $0 
        -a /home/alex/reconout
$segline
Required arguments:
        -a: recon-all output folder
$segline
USAGE
    exit 1
}

## Parse arguments
if [[ $# -lt 2 ]]
then
    Usage >&2
    exit 1
else
    while getopts "a:" OPT
    do
        case $OPT in
            a) ## recon-all output folder
                RECONOUT=$OPTARG
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

## If INPUT folder exist?
bash ${BrainFex}/code/ZOTHERS/check_inout.sh -b ${RECONOUT}
if [[ $? -eq 1 ]]
then
    exit 1
fi

## Run the calculation of LGI
export SUBJECTS_DIR=$(dirname ${RECONOUT})
SUBJECT=$(basename ${RECONOUT})
recon-all -s ${SUBJECT} -localGI

## Check the success of LGI calculation
if [[ ! -f ${RECONOUT}/surf/lh.pial_lgi ]] || [[ ! -f ${RECONOUT}/surf/rh.pial_lgi ]]
then
    echo "ERROR: The calculation of LGI failed. Please check !!!"
    exit 1
fi

