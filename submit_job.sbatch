#!/bin/bash 
#SBATCH --partition=short-serial 
#SBATCH --job-name=butterflyTensors
#SBATCH -o hpc_logs/%A_%a.out
#SBATCH -e hpc_logs/%A_%a.err
#SBATCH --time=20:00:00
#SBATCH --array=1-3
#SBATCH --mem=16000

conda activate rast2tensor-jasmin
Rscript R/rast2tensor.R ${SLURM_ARRAY_TASK_ID}