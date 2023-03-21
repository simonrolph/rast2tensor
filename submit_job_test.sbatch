#!/bin/bash 
#SBATCH --partition=test
#SBATCH --job-name=butterflyTensors
#SBATCH -o out/%A_%a.out
#SBATCH -e err/%A_%a.err
#SBATCH --time=60:00
#SBATCH --array=1-2
#SBATCH --mem=16000

conda 
Rscript R/rast2tensor.R ${SLURM_ARRAY_TASK_ID}