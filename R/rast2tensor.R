args = commandArgs(trailingOnly=TRUE); sp_id <- as.numeric(args[1]) # get species ID from call


#spatial processing
library(terra)
library(sf)

# data wranging
library(dplyr)
library(pbapply) #for progressbars on lapply

#exporting data
#library(torch) #for exporting to pytorch .pt files (not used currently)
library(reticulate) # for exporting as numpy array
np <- import("numpy")

#load raster files from `data/raster` - multiple files loaded as bands into one raster therefore requires matching extents/resolution
env_files <- list.files("data/raster",full.names = T,pattern = "env_data")

# produce object 'all_layers' which has all the layers in it  
all_layers <- rast(env_files)

#clear folders of old content (be careful with this)
clear_old <- F
if(clear_old){
  unlink("data/tensor/*/*")
}

print(names(all_layers))

# species data
sp_points <- readRDS("data/occurence/all_occ_data.RDS")

#create a species list
species_list <- sp_points %>% 
  pull(sp) %>% 
  unique()

species_list_lower <- sp_points %>% 
  pull(sp) %>% 
  unique() %>% 
  tolower() %>% 
  gsub(" ","_",.)


# target species
species <- species_list[sp_id]
species_lower <- species_list_lower[sp_id]
i <- sp_id

#create folders for this species
lapply(species_lower,FUN = function(x){dir.create(paste0("data/tensor/",x))})

#some info
print(paste0(i,"/",length(species_list)))
print(species)

#load points for the selected species
sp_points_sf <- sp_points %>% 
  filter(sp == species) %>%
  st_as_sf(coords =c("x","y"),crs = 27700)

print(nrow(sp_points_sf))



#testing the cropping process in 
#sp_points_sf %>% first() %>% st_geometry() %>% st_buffer(1000)

#only top 100k results
sp_points_sf <- head(sp_points_sf,100000)

#get the spatial buffer around each point
#100k = 1.5hours (non parallel)
print("Buffering points")
buffer_list <- sp_points_sf %>% 
  st_geometry() %>%
  pblapply(FUN = function(x){st_buffer(x,1050)}) 

#not parallel
print("Cropping raster to buffer")
cropped_rast_list <- buffer_list %>%
  pblapply(FUN = function(x){crop(all_layers,x)})


#turn into an array
#unmodified
cropped_rast_array <- cropped_rast_list %>% 
  pblapply(as.array)

# central value
print("Transformation: central value")
cropped_rast_array_centre <- cropped_rast_array %>% 
  pblapply(
    FUN = function(x){
      central_vals <- x[11,11,]
      x[,,] <- rep(central_vals,each = 21^2) %>% array(dim = c(21,21,dim(x)[3]))
      }
    )

#mean values
print("Transformation: mean ")
cropped_rast_array_mean <- cropped_rast_array %>% 
  pblapply(
    FUN = function(x){
      means <- x %>% apply(FUN=function(x){mean(x,na.rm = T)},MARGIN = 3)
      x[,,] <- rep(means,each = 21^2) %>% array(dim = c(21,21,dim(x)[3]))
    }
  )


#save as numpy arrays
print("Saving outputs...")
np_array_list <- np$array(cropped_rast_array)
np$savez(paste0("data/tensor/",species_lower,"/",species_lower,"_unmodified.npz"),np_array_list)

np_array_list_centre <- np$array(cropped_rast_array_centre)
np$savez(paste0("data/tensor/",species_lower,"/",species_lower,"_central_val.npz"),np_array_list_centre)

np_array_list_mean <- np$array(cropped_rast_array_mean)
np$savez(paste0("data/tensor/",species_lower,"/",species_lower,"_mean.npz"),np_array_list_mean)

print("Success")

#npz files can be loaded for tensorflow or pytorch
#load into tensorflow like so: https://www.tensorflow.org/tutorials/load_data/numpy
# load into pytorch: https://pytorch.org/docs/stable/generated/torch.from_numpy.html








