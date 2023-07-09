---
title: "Parallel Randomized Singular Value Decomposition for Classification"
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- How well can an alternative parallel classification algorithm work?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Introduce the Randomized singular value decomposition (RSVD)
- Use the randomized singular value decomposition to classify digits

::::::::::::::::::::::::::::::::::::::::::::::::

## Introduction


### What is the randomized singular value decomposition?

```r
rsvd <- function(x, k=1, q=3, retu=TRUE, retvt=TRUE) {
  
  n <- ncol(x)
  
  if (class(x) == "matrix")
    Omega <- matrix(runif(n*2L*k), nrow=n, ncol=2L*k)
  else if (class(x) == "ddmatrix")  #<<
    Omega <- ddmatrix("runif", nrow=n, ncol=2L*k, bldim=x@bldim, ICTXT=x@ICTXT) #<<
  
  Y <- x %*% Omega
  Q <- qr.Q(qr(Y))
  
  for (i in 1:q) {
    Y <- crossprod(x, Q)
    Q <- qr.Q(qr(Y))
    Y <- x %*% Q
    Q <- qr.Q(qr(Y))
  }
  
  B <- crossprod(Q, x)
  
  if (!retu) nu <- 0
  else nu <- min(nrow(B), ncol(B))
  
  if (!retvt) nv <- 0
  else nv <- min(nrow(B), ncol(B))
  
  svd.B <- La.svd(x=B, nu=nu, nv=nv)
  
  d <- svd.B$d
  d <- d[1L:k]
  
  # Produce u/vt as desired
  if (retu) {
    u <- svd.B$u
    u <- Q %*% u
    u <- u[, 1L:k, drop=FALSE]
  }
  
  if (retvt) vt <- svd.B$vt[1L:k, , drop=FALSE]
  
  # wrangle return
  if (retu) {
    if (retvt) svd <- list(d=d, u=u, vt=vt)
    else svd <- list(d=d, u=u)
  } else {
    if (retvt) svd <- list(d=d, vt=vt)
    else svd <- list(d=d)
  }
  
  return( svd )
}
```

## HDF5 and reading in data

```r
suppressMessages(library(rhdf5))
suppressMessages(library(pbdMPI))
file = "/gpfs/alpine/world-shared/gen011/mnist/train.hdf5"
dat1  = "image"
dat2  = "label"

## get and broadcast dimensions to all processors
if (comm.rank() == 0) {
   h5f = H5Fopen(file, flags="H5F_ACC_RDONLY")
   h5d = H5Dopen(h5f, dat1)
   h5s = H5Dget_space(h5d)
   dims = H5Sget_simple_extent_dims(h5s)$size
   H5Dclose(h5d)
   H5Fclose(h5f)
} else dims = NA
dims = bcast(dims)

nlast = dims[length(dims)] # last dim moves slowest
my_ind = comm.chunk(nlast, form = "vector")

## parallel read of data columns
my_train = as.double(h5read(file, dat1, index = list(NULL, NULL, my_ind)))
my_train_lab = as.character(h5read(file, dat2, index = list(my_ind)))
H5close()

dim(my_train) = c(prod(dims[-length(dims)]), length(my_ind))
my_train = t(my_train)  # row-major write and column-major read
my_train = rbind(my_train, my_train, my_train, my_train, my_train, my_train)
comm.cat("Local dim at rank", comm.rank(), ":", dim(my_train), "\n")
total_rows = allreduce(nrow(my_train))
comm.cat("Total dim :", total_rows, ncol(my_train), "\n")

## plot for debugging
# if(comm.rank() == 0) {
#   ivals = sample(nrow(my_train), 36)
#   library(ggplot2)
#   image = rep(ivals, 28*28)
#   lab = rep(my_train_lab[ivals], 28*28)
#   image = factor(paste(image, lab, sep = ": "))
#   col = rep(rep(1:28, 28), each = length(ivals))
#   row = rep(rep(1:28, each = 28), each = length(ivals))
#   im = data.frame(image = image, row = row, col = col,
#                   val = as.numeric(unlist(my_train[ivals, ])))
#   print(ggplot(im, aes(row, col, fill = val)) + geom_tile() + facet_wrap(~ image))
# }
#barrier()
## remove finalize if sourced in another script
#finalize()
```


## Using the Randomized Singular Value Decomposition for Classification

```r
source("mnist_read_mpi.R") # reads blocks of rows
suppressMessages(library(pbdDMAT))
suppressMessages(library(pbdML))
init.grid()

## construct block-cyclic ddmatrix
bldim = c(allreduce(nrow(my_train), op = "max"), ncol(my_train))
gdim = c(allreduce(nrow(my_train), op = "sum"), ncol(my_train))
dmat_train = new("ddmatrix", Data = my_train, dim = gdim, 
                 ldim = dim(my_train), bldim = bldim, ICTXT = 2)
cyclic_train = as.blockcyclic(dmat_train)

comm.print(comm.size())
t1 = as.numeric(Sys.time())
rsvd_train = rsvd(cyclic_train, k = 10, q = 3, retu = FALSE, retvt = TRUE)
t2 = as.numeric(Sys.time())
t1 = allreduce(t1, op = "min")
t2 = allreduce(t2, op = "max")
comm.cat("Time:", t2 - t1, "seconds\n")
comm.cat("dim(V):", dim(rsvd_train$vt), "\n")

comm.cat("rsvd top 10 singular values:", rsvd_train$d, "\n")

finalize()
```

:::::::::::::::::::::::: solution 

#### SLURM Submission Script
 
```bash
#!/bin/bash
#SBATCH -J rsve
#SBATCH -A gen011
#SBATCH -p batch
#SBATCH --nodes=4
#SBATCH --mem=0
#SBATCH -t 00:00:10
#SBATCH -e ./rsve.e
#SBATCH -o ./rsve.o
#SBATCH --open-mode=truncate

## assumes this repository was cloned in your home area
cd ~/R4HPC/rsvd
pwd

## modules are specific to andes.olcf.ornl.gov
module load openblas/0.3.17-omp
module load flexiblas
flexiblas add OpenBLAS $OLCF_OPENBLAS_ROOT/lib/libopenblas.so
export LD_PRELOAD=$OLCF_FLEXIBLAS_ROOT/lib64/libflexiblas.so
export UCX_LOG_LEVEL=error  # no UCX warn messages

module load r
echo -e "loaded R with FlexiBLAS"
module list

time mpirun --map-by ppr:1:node Rscript mnist_rsvd.R
time mpirun --map-by ppr:2:node Rscript mnist_rsvd.R
time mpirun --map-by ppr:4:node Rscript mnist_rsvd.R
time mpirun --map-by ppr:8:node Rscript mnist_rsvd.R
```

:::::::::::::::::::::::::::::::::



:::::::::::::::::::::::: solution 

#### PBS Submission Script

```bash
#!/bin/bash
#PBS -N rsvd
#PBS -l select=1:mpiprocs=64,walltime=00:10:00
#PBS -q qexp
#PBS -e rsvd.e
#PBS -o rsvd.o

cd ~/ROBUST2022/mpi
pwd

module load R
echo "loaded R"

## Fix for warnings from libfabric/1.12 bug
module swap libfabric/1.12.1-GCCcore-10.3.0 libfabric/1.13.2-GCCcore-11.2.0 
export UCX_LOG_LEVEL=error

time mpirun --map-by ppr:1:node Rscript mnist_rsvd.R
time mpirun --map-by ppr:2:node Rscript mnist_rsvd.R
time mpirun --map-by ppr:4:node Rscript mnist_rsvd.R
time mpirun --map-by ppr:8:node Rscript mnist_rsvd.R
time mpirun --map-by ppr:16:node Rscript mnist_rsvd.R
time mpirun --map-by ppr:32:node Rscript mnist_rsvd.R
time mpirun --map-by ppr:64:node Rscript mnist_rsvd.R
```
:::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: keypoints 

- There are a variety of machine learning algorithms which can be used for classification
- Some will work better than others for your data
- The memory and compute requirements will differ, choose your algorithms and their implementations wisely!

::::::::::::::::::::::::::::::::::::::::::::::::

