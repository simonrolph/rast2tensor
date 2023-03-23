#!/bin/bash 
#SBATCH --partition=test
#SBATCH --job-name=rast2tensor
#SBATCH -o hpc_logs/%A_%a.out
#SBATCH -e hpc_logs/%A_%a.err
#SBATCH --time=60:00
#SBATCH --array=1-3
#SBATCH --mem=32000

conda activate rast2tensor-jasmin
Rscript R/rast2tensor.R ${SLURM_ARRAY_TASK_ID}