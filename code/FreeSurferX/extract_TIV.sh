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
This script extracts total intracranial volume (TIV) from recon-all output
$segline
Usage example:
bash $0 
        -a /home/alex/reconout
        -b /home/alex/output
        -c TIV.txt
$segline
Required arguments:
        -a: recon-all output folder
        -b: output folder to save TIV data
        -c: output filename to save TIV data
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
            b) ## output folder
                OUTDIR=$OPTARG
            ;;
            c) ## output filename
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

## Extract TIV (in mm^3) from aseg.stats
TIV=$(cat ${RECONOUT}/stats/aseg.stats | grep "EstimatedTotalIntraCranialVol" | cut -d ',' -f 4)
if [[ ! -z ${TIV} ]]
then
    echo $TIV > ${OUTDIR}/${OUTFILE}
fi

## Check the success of TIV extraction
if [[ ! -f ${OUTDIR}/${OUTFILE} ]]
then
    echo "ERROR: the extraction of TIV failed. Please check !!!"
    exit 1
fi
