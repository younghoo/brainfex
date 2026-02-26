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
This script checks whether input/output files & folders exist
$segline
Usage example:
bash $0 
        -a /home/alex/input/t1.nii.gz
        -b /home/alex/output
$segline
Required arguments (at least one argument must be specified):
        -a: files with absolute path
        -b: folders with absolute path
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
    while getopts "a:b:" OPT
    do
        case $OPT in
            a) ## files
                FARRAY+=("$OPTARG")
                ;;
            b) ## folders
                DARRAY+=("$OPTARG")
                ;;
            *) ## invalid option
                echo "ERROR: Unrecognized option -$OPT $OPTARG. Please check !!!"
                exit 1
                ;;
        esac
    done
fi

## Check files
if [[ ! -z ${FARRAY} ]]
then
    for CURR_FILE in "${FARRAY[@]}"
    do
        if [[ ! -f ${CURR_FILE} ]]
        then 
            echo "ERROR: File ${CURR_FILE} doesn't exist. Please check !!!"
            exit 1
        fi
    done
fi

## Check folders
if [[ ! -z ${DARRAY} ]]
then
    for CURR_DIR in "${DARRAY[@]}"
    do
        if [[ ! -d ${CURR_DIR} ]]
        then
            echo "ERROR: Folder ${CURR_DIR} doesn't exist. Please check !!!"
            exit 1
        fi
    done
fi

