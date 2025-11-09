## Extract subcortical volume and remove uninteresting data
## Get the commandline arguments
cmd_args <- commandArgs(trailingOnly = TRUE)
atlas_name <- cmd_args[1]
in_fname <- cmd_args[2]
out_fname <- cmd_args[3]
## Deal with AsegN14 Atlas
if (atlas_name == 'AsegN14'){
  ## Load data and select structures of interest
  all_dat <- read.table(in_fname, header = TRUE, check.names = FALSE)
  in_idx <- stringr::str_detect(names(all_dat), 'Thalamus|Caudate|Putamen|Pallidum|Hippocampus|Amygdala|Accumbens')
  all_dat <- all_dat[, in_idx]
  ## Refine column names
  names(all_dat) <- stringr::str_replace_all(names(all_dat), stringr::fixed('-'), '_')
  names(all_dat) <- stringr::str_remove_all(names(all_dat), c('Left'='lh', 'Right'='rh'))
  names(all_dat) <- stringr::str_remove_all(names(all_dat), '_area')
  names(all_dat) <- tolower(names(all_dat))
  ## Save
  write.table(all_dat, out_fname, quote=FALSE, row.names=FALSE, col.names=TRUE)
}

