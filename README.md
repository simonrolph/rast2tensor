# rast2tensor

## Overview

This is R code which producing tensors of environmental conditions for species occurrence records for use in CNN-SDMs. Instead of just getting the environmental conditions at a single point, this code gets the environmental conditions around the point as well - imagine a sort of cookie cutter cutting out a section of the raster around a point, rather than a pinprick at one specific location. This data can then be used in convolution neural networks. Example of a similar application:

*Convolutional neural networks improve species distribution modelling by capturing the spatial structure of the environment*
Deneu B, Servajean M, Bonnet P, Botella C, Munoz F, et al. (2021) Convolutional neural networks improve species distribution modelling by capturing the spatial structure of the environment. PLOS Computational Biology 17(4): e1008856. https://doi.org/10.1371/journal.pcbi.1008856

This is R code developed for use in the Turing Institute funded Ecosystem Leadership Award.

The spatial processing is carried  out using R package {terra}. It has been set-up to run on a SLURM cluster to run for many species.

Two transformations are applied, mean value and central value. See figure 3 of (Deneu et al.) for context.

## Data inputs

### Rasters

Rasters are provided as GeoTIFF files (`.tif`) and placed at the following location `data/raster`. Add each layer as a separate `.tif` file. Each file must have the same extent and resolution. They are loaded in as the terra class `SpatRaster`. 

### Species occurence data

Species occurence data is provided as a `.RDS` file which is a tibble with 5 columns (although date is not used currently so not required): 

```
tibble [7,565,215 x 5] (S3: tbl_df/tbl/data.frame)
 $ id  : num [1:7565215] 
 $ x   : num [1:7565215]
 $ y   : num [1:7565215]
 $ sp  : chr [1:7565215]
 $ date: Date[1:7565215]
 ```
 
## Running the script

`rast2tensor` is the main script for doing the processing. It is set up by default to be run from command line using: `Rscript rast2tensor 1` where you replace `1` with the numeric ID of the species you want to process. But if you want to run it from within Rstudio etc. just edit the script to set `sp_id <- 1`.

A conda environment is used on JASMIN so that the latest version of {terra} can be used to ensure most efficient processing. The conda environment is defined in `environment-jasmin.yml`. You can create an environment using `conda env create -f environment-jasmin.yml`, then loading it with `conda activate rast2tensor-jasmin`.

## Submitting job

Jobs can be submitted to a SLURM cluster using the `.sbatch` file `submit_job.sbatch` and tested with the `submit_job_test.sbatch` (which submits it to the high priority test queue). See https://help.jasmin.ac.uk/article/4881-lotus-queues for queue details.

## Outputs

Outputs are saved as numpy arrays as .npz files. One file per species which contains all the tensors for that species, two more files for the two modifications (central value / mean) are produced. This should be easy to read into tensorflow/PyTorch. Folders are created for each species.

 * load into tensorflow like so: https://www.tensorflow.org/tutorials/load_data/numpy
 * load into pytorch: https://pytorch.org/docs/stable/generated/torch.from_numpy.html
