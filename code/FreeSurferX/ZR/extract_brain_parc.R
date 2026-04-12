## Select regions of interest and re-encode the region indices
## Get the commandline arguments
cmd_args <- commandArgs(trailingOnly = TRUE)
in_fname <- cmd_args[1]
lut_fname <- cmd_args[2]
out_fname <- cmd_args[3]
## Load the original parcellation data
in_parc <- RNifti::readNifti(in_fname)
## Load FS LUT file
fs_lut <- read.table(lut_fname, header = FALSE) 
## Get label index
old_idx <- fs_lut[,1]
new_idx <- seq_along(old_idx)
## Set uninteresting regions to zero
out_parc <- in_parc
out_parc[!out_parc %in% old_idx] <- 0
## Loop each region and re-encode the label index
for (curr_idx in new_idx){
    out_parc[in_parc == old_idx[curr_idx]] <- new_idx[curr_idx]
}
## Save
RNifti::writeNifti(out_parc, out_fname, datatype = 'int32')

