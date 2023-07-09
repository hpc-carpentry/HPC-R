---
title: "Blas"
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- How much can parallel libraries improve time to solution for your program?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Introduce the Basic Linear Algebra Subroutines (BLAS)
- Show that BLAS routines are used from R for statistical calculations
- Demonstrate that parallelization can improve time to solution

::::::::::::::::::::::::::::::::::::::::::::::::

## Introduction


```r
library(flexiblas)
flexiblas_avail()
flexiblas_version()
flexiblas_current_backend()
flexiblas_list()
flexiblas_list_loaded()

getthreads = function() {
  flexiblas_get_num_threads()
}
setthreads = function(thr, label = "") {
  cat(label, "Setting", thr, "threads\n")
  flexiblas_set_num_threads(thr)
}
setback = function(backend, label = "") {
  cat(label, "Setting", backend, "backend\n")
  flexiblas_switch(flexiblas_load_backend(backend))
}

#' PT
#' A function to time one or more R expressions after setting the number of
#' threads available to the BLAS library.
#' 
#' !!
#' DO NOT USE PT RECURSIVELY
#'
#' Use: 
#' variable-for-result = PT(your-num-threads, a-quoted-text-comment, {
#'   expression
#'   expression
#'   ...
#'   expression-to-assign
#' })
PT = function(threads, text = "", expr) {
  setthreads(threads, label = text)
  print(system.time({result = {expr}}))
  result
}
```


```r
source("flexiblas_setup.R")
memuse::howbig(5e4, 2e3)
parallel::detectCores()

x = matrix(rnorm(1e8), nrow = 5e4, ncol = 2e3)
beta = rep(1, ncol(x))
err = rnorm(nrow(x))
y = x %*% beta + err
data = as.data.frame(cbind(y, x))
names(data) = c("y", paste0("x", 1:ncol(x)))

setback("OPENBLAS")
# qr --------------------------------------
for(i in 0:4) {
  setthreads(2^i, "qr")
  print(system.time((qr(x, LAPACK = TRUE))))
}

# prcomp --------------------------------------
for(i in 0:4) {
  setthreads(2^i, "prcomp")
  print(system.time((prcomp(x))))
}

# princomp --------------------------------------
for(i in 0:4) {
  setthreads(2^i, "princomp")
  print(system.time((princomp(x))))
}

# crossprod --------------------------------------
for(i in 0:5) {
  setthreads(2^i, "crossprod")
  print(system.time((crossprod(x))))
}

# %*% --------------------------------------------
for(i in 0:5) {
  setthreads(2^i, "%*%")
  print(system.time((t(x) %*% x)))
}
```



:::::::::::::::::::::::: solution 

## SLURM submision script
 
```bash
#!/bin/bash
#SBATCH -J flexiblas
#SBATCH -A CSC489
#SBATCH -p batch
#SBATCH --nodes=1
#SBATCH --mem=0
#SBATCH -t 00:15:00
#SBATCH -e ./flexiblas.e
#SBATCH -o ./flexiblas.o
#SBATCH --open-mode=truncate

## assumes this repository was cloned in your home area
cd ~/R4HPC/code_3
pwd

## modules are specific to andes.olcf.ornl.gov
module load openblas/0.3.17-omp
module load flexiblas
flexiblas add OpenBLAS $OLCF_OPENBLAS_ROOT/lib/libopenblas.so
export LD_PRELOAD=$OLCF_FLEXIBLAS_ROOT/lib64/libflexiblas.so
module load r
echo -e "loaded R with FlexiBLAS"
module list

Rscript flexiblas_bench.R
```

:::::::::::::::::::::::::::::::::



:::::::::::::::::::::::: solution 

## PBS submission script

```bash
#!/bin/bash
#PBS -N fx
#PBS -l select=1:ncpus=128,walltime=00:50:00
#PBS -q qexp
#PBS -e fx.e
#PBS -o fx.o

cd ~/R4HPC/code_3
pwd

module load R
echo "loaded R"

time Rscript flexiblas_bench2.R
```

:::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: keypoints 

- Many statistical calculations require matrix and vector operations
- When libraries are used, setting their parameters appropriately can improve your time to solution

::::::::::::::::::::::::::::::::::::::::::::::::
