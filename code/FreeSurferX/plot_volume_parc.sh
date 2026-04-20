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
This script makes a figure of volume parcellation for fast quality check
$segline
Usage example:
bash $0 
        -a /home/alex/reconout
        -b DK
        -c 1
        -d /home/alex/output
        -e DK.png
$segline
Required arguments:
        -a: recon-all output folder
        -b: parcellation atlas name
        -c: atlas type (1/2: cortical/subcortical)
        -d: output folder
        -e: output filename
Optional arguments:
        -f: slice ranges in fractions of image dimension (start,step,end)
            (default 0.35,0.1,0.65 for cortical; 0.4,0.05,0.6 for subcortical)
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
            b) ## parcellation atlas name
                PARCNAME=$OPTARG
                ;;
            c) ## atlas type
                ATLASTYPE=$OPTARG
                ;;
            d) ## output folder
                OUTDIR=$OPTARG
                ;;
            e) ## output filename
                OUTFILE=$OPTARG
                ;;
            f) ## slice range
                SRANGE=$OPTARG
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

## If INPUT/OUTPUT folders exist?
bash ${BrainFex}/code/ZOTHERS/check_inout.sh -b ${RECONOUT} -b ${OUTDIR}
if [[ $? -eq 1 ]]
then
    exit 1
fi

## If set slice range
if [[ -z ${SRANGE} ]]
then
    if [[ ${ATLASTYPE} -eq 1 ]]
    then
        SRANGE=0.35,0.1,0.65
    fi
    if [[ ${ATLASTYPE} -eq 2 ]]
    then
        SRANGE=0.4,0.05,0.6
    fi
fi

## Make temporary folder
ORIGDIR=$(pwd)
TMPODIR=${OUTDIR}/tmpo_$$_$(date +%s)_${RANDOM}
mkdir -p ${TMPODIR}
cd ${TMPODIR}

## Prepare data for freeview
## Set the background image
IN_BG=${RECONOUT}/mri/nu.mgz
DIM=($(mri_info ${IN_BG} --dim))
## Deal with cortical parcellation
if [[ ${ATLASTYPE} -eq 1 ]]
then
    IN_PARC=${RECONOUT}/mri/${PARCNAME}+aseg.mgz
    FSLUT=${BrainFex}/data/atlases/${PARCNAME}/${PARCNAME}_FS_LUT.txt
fi
## Deal with subcortical parcellation
if [[ ${ATLASTYPE} -eq 2 ]]
then
    IN_PARC=${RECONOUT}/mri/${PARCNAME}.mgz
    FSLUT=${BrainFex}/data/atlases/${PARCNAME}/${PARCNAME}_FS_LUT.txt
    ## Deal with Aseg Atlas
    if [[ ${PARCNAME} == Aseg* ]]
    then
        FSLUT=${BrainFex}/data/atlases/Aseg/${PARCNAME}_FS_LUT.txt
    fi
fi
## Select regions of interest
mri_convert ${IN_PARC} tmpo_${PARCNAME}.nii.gz
Rscript ${BrainFex}/code/FreeSurferX/ZR/clean_parc_mask.R tmpo_${PARCNAME}.nii.gz ${FSLUT} tmpo_${PARCNAME}_clean.nii.gz 0
IN_PARC=tmpo_${PARCNAME}_clean.nii.gz

## Plot the slices
IFS=',' read -r slice_start slice_step slice_end <<< "${SRANGE}"
slice_seq=($(seq ${slice_start} ${slice_step} ${slice_end}))
slice_index=($(seq 1 ${#slice_seq[@]}))
## Export the freeview options into a text file
echo "freeview -v ${IN_BG} ${IN_PARC}:colormap=lut:lut=${FSLUT} --layout 1" > fv_cmd.txt
for curr_idx in "${slice_index[@]}"
do
    pos_idx=$((${curr_idx} - 1))
    curr_frac=${slice_seq[${pos_idx}]}
    curr_slice=$(echo "${curr_frac}*${DIM[0]}/1" | bc)
    echo "-viewport x -slice ${curr_slice} 1 1 -ss X${curr_idx}.png" >> fv_cmd.txt
    echo "-viewport y -slice 1 1 ${curr_slice} -ss Y${curr_idx}.png" >> fv_cmd.txt
    echo "-viewport z -slice 1 ${curr_slice} 1 -ss Z${curr_idx}.png" >> fv_cmd.txt
done
echo "-quit" >> fv_cmd.txt
## Make the screenshots
fsxvfb freeview -cmd fv_cmd.txt

## Merge all slices
for curr_dim in X Y Z
do
    convert ${curr_dim}*.png +append ${curr_dim}_view.png
done
convert *view.png -append ${OUTDIR}/${OUTFILE}

## Remove temporary folder
cd ${ORIGDIR}
rm -r ${TMPODIR}

## Check the output file
if [[ ! -f ${OUTDIR}/${OUTFILE} ]]
then
    echo "BrainFex Error: Making a figure of volume parcellation failed. Please check !!!"
    exit 1
fi

