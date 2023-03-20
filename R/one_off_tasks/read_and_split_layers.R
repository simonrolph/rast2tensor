library(terra)




#/gws/nopw/j04/ceh_generic/DECIDE/DECIDE_SDMs/data/derived_data/environmental/
env_data <- rast("data/pre-processed/envdata_fixedcoasts_nocorrs_100m_GB.grd")
env_data

names(env_data) <- tolower(names(env_data))
writeRaster(env_data,paste0("data/raster/env_data_",names(env_data),".tif"))







# other files
lc_data <- rast("C:\\Users\\simrol\\Documents\\R\\DECIDE_WP1\\data\\derived_data\\environmental\\lcm2015gb100perc.tif")

names(lc_data)
writeRaster(lc_data,paste0("data/raster/land_cover_",names(lc_data),".tif"))


el_data <- rast("C:\\Users\\simrol\\Documents\\R\\DECIDE_WP1\\data\\derived_data\\environmental\\elevation_UK.grd")
el_data

el_data <- el_data %>% extend(lc_data)
writeRaster(env_data,"data/raster/elevation.tif")

