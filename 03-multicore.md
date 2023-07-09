---
title: "Multicore"
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- Can parallelization decrease time to solution for my program?
- What is machine learning?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Introduce machine learning, in particular the random forest algorithm
- Demonstrate serial and parallel implementations of the random forest algorithm
- Show that statistical machine learning models can be used to classify data after training on an existing dataset

::::::::::::::::::::::::::::::::::::::::::::::::

## Introduction


### Serial Implementation

```r
suppressMessages(library(randomForest))
data(LetterRecognition, package = "mlbench")
set.seed(seed = 123)

n = nrow(LetterRecognition)
n_test = floor(0.2 * n)
i_test = sample.int(n, n_test)
train = LetterRecognition[-i_test, ]
test = LetterRecognition[i_test, ]

rf.all = randomForest(lettr ~ ., train, ntree = 500, norm.votes = FALSE)
pred = predict(rf.all, test)

correct = sum(pred == test$lettr)
cat("Proportion Correct:", correct/(n_test), "\n")
```


### Parallel Multicore Implementation

```r
library(parallel)                                       #<<
library(randomForest)
data(LetterRecognition, package = "mlbench")
set.seed(seed = 123, "L'Ecuyer-CMRG")                   #<<

n = nrow(LetterRecognition)
n_test = floor(0.2 * n)
i_test = sample.int(n, n_test)
train = LetterRecognition[-i_test, ]
test = LetterRecognition[i_test, ]

nc = as.numeric(commandArgs(TRUE)[2])                    #<<
ntree = lapply(splitIndices(500, nc), length)            #<<
rf = function(x, train) randomForest(lettr ~ ., train, ntree=x, #<<
                                     norm.votes = FALSE)        #<<
rf.out = mclapply(ntree, rf, train = train, mc.cores = nc)      #<<
rf.all = do.call(combine, rf.out)                        #<<

crows = splitIndices(nrow(test), nc)                     #<<
rfp = function(x) as.vector(predict(rf.all, test[x, ]))  #<<
cpred = mclapply(crows, rfp, mc.cores = nc)              #<<
pred = do.call(c, cpred)                                 #<<

correct <- sum(pred == test$lettr)
cat("Proportion Correct:", correct/(n_test), "\n")
```
:::::::::::::::::::::::: solution

### SLURM submission script

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

cd ~/R4HPC/code_2
pwd

## modules are specific to andes.olcf.ornl.gov
module load openblas/0.3.17-omp
module load flexiblas
flexiblas add OpenBLAS $OLCF_OPENBLAS_ROOT/lib/libopenblas.so
export LD_PRELOAD=$OLCF_FLEXIBLAS_ROOT/lib64/libflexiblas.so
module load r
echo -e "loaded R with FlexiBLAS"
module list

time Rscript rf_serial.r
time Rscript rf_mc.r --args 1
time Rscript rf_mc.r --args 2
time Rscript rf_mc.r --args 4
time Rscript rf_mc.r --args 8
time Rscript rf_mc.r --args 16
time Rscript rf_mc.r --args 32
time Rscript rf_mc.r --args 64
```
:::::::::::::::::::::::::::::::::

:::::::::::::::::::::::: solution

### PBS submission script

```bash
#!/bin/bash
#PBS -N rf
#PBS -l select=1:ncpus=128
#PBS -l walltime=00:05:00
#PBS -q qexp
#PBS -e rf.e
#PBS -o rf.o

cd ~/R4HPC/code_2
pwd

module load R
echo "loaded R"

time Rscript rf_serial.r
time Rscript rf_mc.r --args 1
time Rscript rf_mc.r --args 2
time Rscript rf_mc.r --args 4
time Rscript rf_mc.r --args 8
time Rscript rf_mc.r --args 16
time Rscript rf_mc.r --args 32
time Rscript rf_mc.r --args 64
time Rscript rf_mc.r --args 128
```
:::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::: keypoints 

- To evaluate the fitted model, the availabe data is split into training and testing sets
- Parallelization decreases the training time

::::::::::::::::::::::::::::::::::::::::::::::::

