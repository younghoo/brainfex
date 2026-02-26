## Merge lh and rh features, and remove uninteresting data
## Get the commandline arguments
cmd_args <- commandArgs(trailingOnly = TRUE)
lh_fname <- cmd_args[1]
rh_fname <- cmd_args[2]
out_fname <- cmd_args[3]
## Loop each hemisphere
all_dat <- NULL
for (curr_hemi in c('lh', 'rh')){
    if (curr_hemi == 'lh'){
        curr_dat <- read.table(lh_fname, header = TRUE, check.names = FALSE)
    }else{
        curr_dat <- read.table(rh_fname, header = TRUE, check.names = FALSE)
    }
    ## Remove the first column, representing the SUBJECT ID
    curr_dat <- curr_dat[,-1]
    ## Remove uninteresting data
    rm_idx <- names(curr_dat) %in% c("lh_MeanThickness_thickness", "rh_MeanThickness_thickness",
                                    "lh_WhiteSurfArea_area", "rh_WhiteSurfArea_area",
                                    "BrainSegVolNotVent", "eTIV")
    curr_dat <- curr_dat[, !rm_idx]
    ## Combine the lh and rh data
    if (is.null(all_dat)){
        all_dat <- curr_dat
    }else{
        all_dat <- cbind(all_dat, curr_dat)
    }
}
## Refine column names
names(all_dat) <- stringr::str_remove(names(all_dat), '_(thickness|area|volume|meancurv|gauscurv|curvind|foldind)')
names(all_dat) <- stringr::str_replace_all(names(all_dat), stringr::fixed('&'), '_and_')
names(all_dat) <- stringr::str_replace_all(names(all_dat), stringr::fixed('-'), '_')
## Save
write.table(all_dat, out_fname, quote=FALSE, row.names=FALSE, col.names=TRUE)

