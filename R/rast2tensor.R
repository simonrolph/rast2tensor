args = commandArgs(trailingOnly=TRUE); sp_id <- as.numeric(args[1]) # get species ID from call
if (is.na(sp_id)){
  sp_id <- 1
}
start_time <- Sys.time()

#spatial processing
library(terra)
terraOptions(memmax = 30) #less than the amount define in the 
library(sf)

# data wranging
library(dplyr)
library(pbapply) #for progressbars on lapply
pbo = pboptions(type="timer") # !!! force printing loading bars, see: https://github.com/psolymos/pbapply/issues/32

#exporting data
#library(torch) #for exporting to pytorch .pt files (not used currently)
library(reticulate) # for exporting as numpy array
use_condaenv("rast2tensor-jasmin")
np <- import("numpy")

#load raster files from `data/raster` - multiple files loaded as bands into one raster therefore requires matching extents/resolution
env_files <- list.files("data/raster",full.names = T,pattern = "*.tif")

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

#only top 500k results
sp_points_sf <- head(sp_points_sf,500000)

#get the spatial buffer around each point
#100k = 1.5hours (non parallel)
print("Buffering points")
buffer_list <- sp_points_sf %>% 
  st_geometry() %>%
  st_buffer(550) #550metre buffer


print("Cropping raster to buffer")
extract1 <- cells(all_layers,vect(buffer_list)) %>% as.data.frame()
extract2 <- extract(all_layers,extract1[,"cell"],xy=T)
extract3 <- cbind(extract1,extract2)

#method that doesn't have to create rasters then transform to arrays so hopefully less memory involved 
# df_to_array <- function(df){
#   df$x <-df$x - min(df$x)
#   df$x <- df$x / (diff(unique(sort(df$x))))[1]
#   df$y <- df$y - min(df$y)
#   df$y <- df$y / (diff(unique(sort(df$y))))[1]
#   df<-df[,-1] #drop ID column
#   cols1 <- bind_rows(replicate(ncol(df)-2, df[,1:2], simplify = FALSE))
#   x <- as.data.frame(t(df[,3:ncol(df)]))
#   cols2 <- data.frame(
#     name = rownames(x),
#     value = unlist(x)
#   )
#   df <- bind_cols(cols1,cols2)
#   xtabs(value ~ x + y+name, df)
# }
# 
# cropped_rast_array <- extract3 %>% select(-cell) %>%
#   base::split(f = extract3$ID) %>%
#   pblapply(FUN = df_to_array) %>% 
#   unname()



#version that turned it into a raster then an array
cropped_rast_array <- extract3 %>% select(-cell) %>%
  base::split(f = extract3$ID) %>%
  pblapply(FUN = function(x){rast(x[,-1],type="xyz")}) %>% #create raster
  lapply(as.array) %>% #turn into an array
  unname()

gc()

# central value
print("Transformation: central value")
cropped_rast_array_centre <- cropped_rast_array %>% 
  lapply(
    FUN = function(x){
      central_vals <- x[6,6,]
      x[,,] <- rep(central_vals,each = 11^2) %>% array(dim = c(11,11,dim(x)[3]))
      }
    )

#mean values
print("Transformation: mean ")
cropped_rast_array_mean <- cropped_rast_array %>% 
  lapply(
    FUN = function(x){
      means <- x %>% apply(FUN=function(x){mean(x,na.rm = T)},MARGIN = 3)
      x[,,] <- rep(means,each = 11^2) %>% array(dim = c(11,11,dim(x)[3]))
    }
  )


#save as numpy arrays
print("Saving outputs...")

#save untransformed as rds
saveRDS(cropped_rast_array,paste0("data/tensor/",species_lower,"/",species_lower,"_unmodified.RDS"))

np_array_list <- np$array(cropped_rast_array)
np$savez(paste0("data/tensor/",species_lower,"/",species_lower,"_unmodified.npz"),np_array_list)

np_array_list_centre <- np$array(cropped_rast_array_centre)
np$savez(paste0("data/tensor/",species_lower,"/",species_lower,"_central_val.npz"),np_array_list_centre)

np_array_list_mean <- np$array(cropped_rast_array_mean)
np$savez(paste0("data/tensor/",species_lower,"/",species_lower,"_mean.npz"),np_array_list_mean)


print("checking outputs")
print("Unmodified:")
file.exists(paste0("data/tensor/",species_lower,"/",species_lower,"_unmodified.npz"))
print("Central value:")
file.exists(paste0("data/tensor/",species_lower,"/",species_lower,"_central_val.npz"))
print("Mean:")
file.exists(paste0("data/tensor/",species_lower,"/",species_lower,"_mean.npz"))

print("Script finished. Runtime:")
print(Sys.time()-start_time)


#npz files can be loaded for tensorflow or pytorch
#load into tensorflow like so: https://www.tensorflow.org/tutorials/load_data/numpy
# load into pytorch: https://pytorch.org/docs/stable/generated/torch.from_numpy.html








