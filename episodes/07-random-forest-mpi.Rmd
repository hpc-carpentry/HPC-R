---
title: "MPI - Distributed Memory Parallelizm"
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- How do you utilize more than one shared memory node?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Demonstrate that distributed memory parallelizm is useful for working with large data
- Demonstrate that distributed memory parallelizm can lead to improved time to solution

::::::::::::::::::::::::::::::::::::::::::::::::

## Introduction

### Distributed Memory Random Forest

#### Digit Recognition

```r
suppressPackageStartupMessages(library(randomForest))
data(LetterRecognition, package = "mlbench")
library(pbdMPI, quiet = TRUE)                #<<
comm.set.seed(seed = 7654321, diff = FALSE)      #<<

n = nrow(LetterRecognition)
n_test = floor(0.2 * n)
i_test = sample.int(n, n_test)
train = LetterRecognition[-i_test, ]
test = LetterRecognition[i_test, ][comm.chunk(n_test, form = "vector"), ]    #<<

comm.set.seed(seed  = 1234, diff = TRUE)          #<<
my.rf = randomForest(lettr ~ ., train, ntree = comm.chunk(500), norm.votes = FALSE) #<<
rf.all = allgather(my.rf)                  #<<
rf.all = do.call(combine, rf.all)          #<<
pred = as.vector(predict(rf.all, test))

correct = allreduce(sum(pred == test$lettr))  #<<
comm.cat("Proportion Correct:", correct/(n_test), "\n")

finalize()
```

#### Diamond Classification

```r
library(randomForest)
data(diamonds, package = "ggplot2")
library(pbdMPI)                                  #<<
comm.set.seed(seed = 7654321, diff = FALSE)      #<<

n = nrow(diamonds)
n_test = floor(0.5 * n)
i_test = sample.int(n, n_test)
train = diamonds[-i_test, ]
test = diamonds[i_test, ][comm.chunk(n_test, form = "vector"), ]    #<<

comm.set.seed(seed = 1e6 * runif(1), diff = TRUE)          #<<
my.rf = randomForest(price ~ ., train, ntree = comm.chunk(100), norm.votes = FALSE) #<<
rf.all = allgather(my.rf)                  #<<
rf.all = do.call(combine, rf.all)          #<<
pred = as.vector(predict(rf.all, test))

sse = sum((pred - test$price)^2)
comm.cat("MSE =", reduce(sse)/n_test, "\n")

finalize()          #<<
```

:::::::::::::::::::::::: solution 

#### SLURM submission script
 
```bash
#!/bin/bash
#SBATCH -J rf
#SBATCH -A CSC143
#SBATCH -p batch
#SBATCH --nodes=1
#SBATCH -t 00:40:00
#SBATCH --mem=0
#SBATCH -e ./rf.e
#SBATCH -o ./rf.o
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

time Rscript ../code_2/rf_serial.R
time mpirun --map-by ppr:1:node Rscript rf_mpi.R
time mpirun --map-by ppr:2:node Rscript rf_mpi.R
time mpirun --map-by ppr:4:node Rscript rf_mpi.R
time mpirun --map-by ppr:8:node Rscript rf_mpi.R
time mpirun --map-by ppr:16:node Rscript rf_mpi.R
time mpirun --map-by ppr:32:node Rscript rf_mpi.R
```

:::::::::::::::::::::::::::::::::


:::::::::::::::::::::::: solution 

#### PBS Submission Script

```bash
#!/bin/bash
#PBS -N rf
#PBS -l select=1:ncpus=32
#PBS -l walltime=00:05:00
#PBS -q qexp
#PBS -e rf.e
#PBS -o rf.o

cd ~/R4HPC/code_5
pwd

module load R
echo "loaded R"

time Rscript ../code_2/rf_serial.R
time mpirun --map-by ppr:1:node Rscript rf_mpi.R
time mpirun --map-by ppr:2:node Rscript rf_mpi.R
time mpirun --map-by ppr:4:node Rscript rf_mpi.R
time mpirun --map-by ppr:8:node Rscript rf_mpi.R
time mpirun --map-by ppr:16:node Rscript rf_mpi.R
time mpirun --map-by ppr:32:node Rscript rf_mpi.R
```
:::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::: keypoints 

- Classification can be used for data other than digits, such as diamonds
- Distributed memory parallelizm can speed up training

::::::::::::::::::::::::::::::::::::::::::::::::

