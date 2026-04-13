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
This script makes a figure of surface parcellation for fast quality check
$segline
Usage example:
bash $0 
        -a /home/alex/reconout
        -b DK
        -c /home/alex/output
        -d t1_DK.png
$segline
Required arguments:
        -a: recon-all output folder
        -b: parcellation atlas name
        -c: output folder
        -d: output filename
Optional arguments:
        -e: surface type (pial/white/inflated; default pial)
        -f: visual mode (simple/full; default simple)
$segline
Parcellation atlases available: 
        1. DK
        2. Destrieux
        3. AsegN14
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
    while getopts "a:b:c:d:e:f:" OPT
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
            e) ## surface type
                SURFTYPE=$OPTARG
                ;;
            f) ## visual mode
                VISMODE=$OPTARG
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

## If set surface type
if [[ -z ${SURFTYPE} ]]
then
    SURFTYPE=pial
fi

## If set the visual mode
if [[ -z ${VISMODE} ]]
then
    VISMODE=simple
fi

## Make temporary folder
ORIGDIR=$(pwd)
TMPODIR=${OUTDIR}/tmpo_$$_$(date +%s)_${RANDOM}
mkdir -p ${TMPODIR}
cd ${TMPODIR}

## Prepare data for freeview
## Find the surface file
LH_SURF=${RECONOUT}/surf/lh.${SURFTYPE}
RH_SURF=${RECONOUT}/surf/rh.${SURFTYPE}
## Find the parcellation file
LH_PARC=${RECONOUT}/label/lh.${PARCNAME}.annot
RH_PARC=${RECONOUT}/label/rh.${PARCNAME}.annot
## Deal with DK Atlas
if [[ ${PARCNAME} == DK ]]
then
    LH_PARC=${RECONOUT}/label/lh.aparc.annot
    RH_PARC=${RECONOUT}/label/rh.aparc.annot
fi
## Deal with Destrieux Atlas
if [[ ${PARCNAME} == Destrieux ]]
then
    LH_PARC=${RECONOUT}/label/lh.aparc.a2009s.annot
    RH_PARC=${RECONOUT}/label/rh.aparc.a2009s.annot
fi

## For simple mode, plot lateral and medial views
if [[ ${VISMODE} == simple ]]
then
    ## Plot the left surface in different views
    echo "freeview -f ${LH_SURF}:annot=${LH_PARC} --layout 1 -viewport 3d" > fv_cmd.txt
    echo "-cam Azimuth 0 -ss L1_lateral.png" >> fv_cmd.txt
    echo "-cam Azimuth 180 -ss L2_medial.png" >> fv_cmd.txt
    echo "-quit" >> fv_cmd.txt
    fsxvfb freeview -cmd fv_cmd.txt
    ## Plot the right surface in different views
    echo "freeview -f ${RH_SURF}:annot=${RH_PARC} --layout 1 -viewport 3d" > fv_cmd.txt
    echo "-cam Azimuth 180 -ss R1_lateral.png" >> fv_cmd.txt
    echo "-cam Azimuth 180 -ss R2_medial.png" >> fv_cmd.txt
    echo "-quit" >> fv_cmd.txt
    fsxvfb freeview -cmd fv_cmd.txt
fi

## For full mode, plot lateral/medial/superior/inferior views
if [[ ${VISMODE} == full ]]
then
    ## Plot the left surface in different views
    echo "freeview -f ${LH_SURF}:annot=${LH_PARC} --layout 1 -viewport 3d" > fv_cmd.txt
    echo "-cam Azimuth 0 -ss L1_lateral.png" >> fv_cmd.txt
    echo "-cam Azimuth 180 -ss L2_medial.png" >> fv_cmd.txt
    echo "-cam Elevation 90 Roll 90 -ss L3_superior.png" >> fv_cmd.txt
    echo "-cam Elevation 90 Elevation 90 -ss L4_inferior.png" >> fv_cmd.txt
    echo "-quit" >> fv_cmd.txt
    fsxvfb freeview -cmd fv_cmd.txt
    ## Plot the right surface in different views
    echo "freeview -f ${RH_SURF}:annot=${RH_PARC} --layout 1 -viewport 3d" > fv_cmd.txt
    echo "-cam Azimuth 180 -ss R1_lateral.png" >> fv_cmd.txt
    echo "-cam Azimuth 180 -ss R2_medial.png" >> fv_cmd.txt
    echo "-cam Elevation 90 Roll -90 -ss R3_superior.png" >> fv_cmd.txt
    echo "-cam Elevation 90 Elevation 90 -ss R4_inferior.png" >> fv_cmd.txt
    echo "-quit" >> fv_cmd.txt
    fsxvfb freeview -cmd fv_cmd.txt
fi

## Merge all views
for curr_hemi in L R
do
    convert ${curr_hemi}*.png +append ${curr_hemi}_view.png
done
convert *view.png -append ${OUTDIR}/${OUTFILE}

## Remove temporary folder
cd ${ORIGDIR}
rm -r ${TMPODIR}

## Check the output file
if [[ ! -f ${OUTDIR}/${OUTFILE} ]]
then
    echo "ERROR: making a figure of surface parcellation failed. Please check !!!"
    exit 1
fi

