---
title: "MPI - Distributed Memory Parallelism"
teaching: 10
exercises: 0
---

:::::::::::::::::::::::::::::::::::::: questions 

- How do you utilize more than one shared memory node?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Demonstrate how to submit a job on multiple nodes
- Demonstrate that a program with distributed memory parallelism can be run on a shared memory node

::::::::::::::::::::::::::::::::::::::::::::::::

## Introduction

### Hello World!

```r
suppressMessages(library(pbdMPI))

my_rank = comm.rank()
nranks = comm.size()
msg = paste0("Hello World! My name is Rank", my_rank,
             ". We are ", nranks, " identical siblings.")
cat(msg, "\n")

finalize()
```


:::::::::::::::::::::::: solution 

#### SLURM submission script
 
```bash
#!/bin/bash
#SBATCH -J hello
#SBATCH -A CSC143
#SBATCH -p batch
#SBATCH --nodes=1
#SBATCH -t 00:40:00
#SBATCH --mem=0
#SBATCH -e ./hello.e
#SBATCH -o ./hello.o
#SBATCH --open-mode=truncate

cd ~/R4HPC/code_5
pwd

## modules are specific to andes.olcf.ornl.gov
module load openblas/0.3.17-omp
module load flexiblas
flexiblas add OpenBLAS $OLCF_OPENBLAS_ROOT/lib/libopenblas.so
export LD_PRELOAD=$OLCF_FLEXIBLAS_ROOT/lib64/libflexiblas.so
module load r
echo -e "loaded R with FlexiBLAS"
module list

mpirun --map-by ppr:32:node Rscript hello_world.R
```

:::::::::::::::::::::::::::::::::


:::::::::::::::::::::::: solution 

#### PBS Submission Script

```bash
#!/bin/bash
#PBS -N hello
#PBS -l select=1:ncpus=32
#PBS -l walltime=00:05:00
#PBS -q qexp
#PBS -e hello.e
#PBS -o hello.o

cd ~/R4HPC/code_5
pwd

module load R
echo "loaded R"

mpirun --map-by ppr:32:node Rscript hello_world.R
```
:::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::: keypoints 

- One can run a distributed memory program on a shared memory node

::::::::::::::::::::::::::::::::::::::::::::::::

