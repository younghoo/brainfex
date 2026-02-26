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
This script makes a figure of a few orthogonal slices for fast quality check
$segline
Usage example:
bash $0 
        -a /home/alex/input/t1.nii.gz
        -b /home/alex/input/t1_brainmask.nii.gz
        -c /home/alex/output
        -d t1_brainmask.png
$segline
Required arguments:
        -a: input as the background image
        -b: input as the foreground image (set to none if no input)
        -c: output folder to save the figure
        -d: output filename of the figure
Optional arguments:
        -e: reorient to standard orientation (0/1; default 1)
        -f: spatial layout (1/2: vertical/horizontal; default 1)
        -g: visual mode for the foreground image (1/2/3/4: full/border/edge/mask; default 1)
        -h: slice ranges in fractions of image dimension (start,step,end; default 0.35,0.1,0.65)
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
        while getopts "a:b:c:d:e:f:g:h:" OPT
        do
                case $OPT in
                a) ## input as background
                INPUT_BG=$OPTARG
                ;;
                b) ## input as foreground
                INPUT_FG=$OPTARG
                ;;
                c) ## output directory
                OUTDIR=$OPTARG
                ;;
                d) ## output filename
                OUTFILE=$OPTARG
                ;;
                e) ## reorient to standard orientation
                REORIENT=$OPTARG
                ;;
                f) ## spatial layout
                LAYOUT=$OPTARG
                ;;
                g) ## visual mode
                VISMODE=$OPTARG
                ;;
                h) ## slice range
                SRANGE=$OPTARG
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
if [[ ${INPUT_FG} == "none" ]]
then
        PARAMS="-a ${INPUT_BG} -b ${OUTDIR}"
else
        PARAMS="-a ${INPUT_BG} -a ${INPUT_FG} -b ${OUTDIR}"
fi
bash ${BrainFex}/code/ZOTHERS/check_inout.sh ${PARAMS}
if [[ $? -eq 1 ]]
then
        exit 1
fi

## If reorient to standard space
if [[ -z ${REORIENT} ]]
then
        REORIENT=1
fi

## If set the spatial layout
if [[ -z ${LAYOUT} ]]
then
        LAYOUT=1
fi

## If set the visual mode
if [[ -z ${VISMODE} ]]
then
        VISMODE=1
fi

## If set slice range
if [[ -z ${SRANGE} ]]
then
        SRANGE=0.35,0.1,0.65
fi

## Make temporary folder
ORIGDIR=$(pwd)
TMPODIR=${OUTDIR}/tmpo_$$_$(date +%s)_${RANDOM}
mkdir -p ${TMPODIR}
cd ${TMPODIR}

## Prepare data for plot
if [[ ${INPUT_FG} == "none" ]]
then
        MinMax=($(fslstats ${INPUT_BG} -r))
        fslmaths ${INPUT_BG} -max ${MinMax[0]} -min ${MinMax[1]} data_vis.nii.gz
else
        ## Show the full data
        if [[ ${VISMODE} -eq 1 ]]
        then
                MinMax=($(fslstats ${INPUT_FG} -r))
                overlay 1 0 ${INPUT_BG} -a ${INPUT_FG} ${MinMax[0]} ${MinMax[1]} data_vis.nii.gz
        fi
        ## Show image border only
        if [[ ${VISMODE} -eq 2  ]]
        then
                fslmaths ${INPUT_FG} -ero fg_ero.nii.gz
                fslmaths ${INPUT_FG} -sub fg_ero.nii.gz -abs -bin fg_border.nii.gz
                overlay 0 0 ${INPUT_BG} -a fg_border.nii.gz 1 1 data_vis.nii.gz
        fi
        ## Show image edge only
        if [[ ${VISMODE} -eq 3 ]]
        then
                fslmaths ${INPUT_FG} -dog_edge 1 1.6 fg_edge.nii.gz
                overlay 0 0 ${INPUT_BG} -a fg_edge.nii.gz 1 1 data_vis.nii.gz
        fi
        ## Show image mask
        if [[ ${VISMODE} -eq 4 ]]
        then
                fslmaths ${INPUT_FG} -abs -bin fg_mask.nii.gz
                overlay 1 0 ${INPUT_BG} -a fg_mask.nii.gz 1 1 data_vis.nii.gz
        fi
fi

## Reorient to standard orientation
if [[ ${REORIENT} -eq 1 ]]
then
        fslreorient2std data_vis.nii.gz data_vis.nii.gz
fi

## Plot the slices
IFS=',' read -r slice_start slice_step slice_end <<< "${SRANGE}"
slice_seq=($(seq ${slice_start} ${slice_step} ${slice_end}))
slice_index=($(seq 1 ${#slice_seq[@]}))
PARAMS=""
for curr_idx in "${slice_index[@]}"
do
        pos_idx=$((${curr_idx} - 1))
        curr_slice=${slice_seq[${pos_idx}]}
        PARAMS+="-x ${curr_slice} X${curr_idx}.png "
        PARAMS+="-y ${curr_slice} Y${curr_idx}.png "
        PARAMS+="-z ${curr_slice} Z${curr_idx}.png "
done
slicer data_vis.nii.gz -u ${PARAMS}

## Merge all slices
if [[ ${LAYOUT} -eq 1 ]]
then
        for curr_dim in X Y Z
        do
                PARAMS=""
                for curr_idx in "${slice_index[@]}"
                do
                        if [[ ${curr_idx} == 1 ]]
                        then
                                PARAMS+="${curr_dim}${curr_idx}.png "
                        else
                                PARAMS+="- ${curr_dim}${curr_idx}.png "
                        fi
                done
                pngappend ${PARAMS} ${curr_dim}_view.png
        done
        pngappend X_view.png + Y_view.png + Z_view.png ${OUTDIR}/${OUTFILE}
else
        PARAMS=""
        for curr_dim in X Y Z
        do
                for curr_idx in "${slice_index[@]}"
                do
                        if [[ ${curr_idx} == 1 ]] && [[ ${curr_dim} == X ]]
                        then
                                PARAMS+="${curr_dim}${curr_idx}.png "
                        else
                                PARAMS+="+ ${curr_dim}${curr_idx}.png "
                        fi
                done
        done
        pngappend ${PARAMS} ${OUTDIR}/${OUTFILE}
fi

## Remove temporary folder
cd ${ORIGDIR}
rm -r ${TMPODIR}

## Check the output file
if [[ ! -f ${OUTDIR}/${OUTFILE} ]]
then
    echo "ERROR: making a figure of orthogonal slices failed. Please check !!!"
    exit 1
fi

