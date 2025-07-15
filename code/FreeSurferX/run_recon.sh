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
This script runs the default pipeline of recon-all
$segline
Usage example:
bash $0 
        -a /home/alex/input/t1.nii.gz
        -b /home/alex/output
        -c reconout
$segline
Required arguments:
        -a: raw T1 image as input
        -b: output directory
        -c: folder to save recon-all output
Optional arguments:
        -d: use T2 to refine surface
        -e: use FLAIR to refine surface
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
    while getopts "a:b:c:d:e:" OPT
    do
      case $OPT in
          a) ## T1 input file
             INPUT=$OPTARG
             ;;
          b) ## output directory
             OUTDIR=$OPTARG
             ;;
          c) ## folder to save recon-all results
             RECONOUT=$OPTARG
             ;;
          d) ## T2 file
             T2IN=$OPTARG
             ;;
          e) ## FLAIR file
             FLAIRIN=$OPTARG
             ;;
          *) ## invalid option
             echo "ERROR: Unrecognized option -$OPT $OPTARG. Please check !!!"
             exit 1
             ;;
      esac
    done
fi

## If INPUT file/OUTPUT folder exist?
bash ${BrainFex}/code/ZOTHERS/check_inout.sh -a ${INPUT} -b ${OUTDIR}
if [[ $? -eq 1 ]]
then
    exit 1
fi

## If T2 provided?
if [[ ! -z ${T2IN} ]]
then
    bash ${BrainFex}/code/ZOTHERS/check_inout.sh -a ${T2IN}
    if [[ $? -eq 1 ]]
    then
        exit 1
    fi
    MOREPARAS="-T2 ${T2IN} -T2pial"
fi

## If FLAIR provided?
if [[ ! -z ${FLAIRIN} ]]
then
    bash ${BrainFex}/code/check_inout.sh -a ${FLAIRIN}
    if [[ $? -eq 1 ]]
    then
        exit 1
    fi
    MOREPARAS="-FLAIR ${FLAIRIN} -FLAIRpial"
fi

## Run the default pipeline of recon-all
export SUBJECTS_DIR=${OUTDIR}
SUBJECT=${RECONOUT}
recon-all -i ${INPUT} -s ${SUBJECT} -all ${MOREPARAS}

## Remove redundent link
rm ${SUBJECTS_DIR}/fsaverage

## Check whether recon-all finished successfully
STATUS=$(tail -n 1 ${SUBJECTS_DIR}/${SUBJECT}/scripts/recon-all.log | grep "finished without error" | wc -l)
if [[ ${STATUS} -ne 1 ]]
then
    echo "ERROR: The default pipeline of recon-all failed. Please check !!!"
    exit 1
fi


