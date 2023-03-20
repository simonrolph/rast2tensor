#Generate metadata

library(terra)
env_files <- list.files("data/raster",full.names = T,pattern = "env_data")
all_layers <- rast(env_files)
writeLines(names(all_layers),"data/tensor/_layers.txt") #write a file that indicates what each of the numpy array levels mean