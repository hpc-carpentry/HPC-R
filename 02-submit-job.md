---
title: "Submit a parallel job"
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- How do you get a high performance computing cluster to run a program?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Introduce a parallel R program
- Submit a parallel R program to a job scheduler on a cluster

::::::::::::::::::::::::::::::::::::::::::::::::

## Introduction


```r
## This script describes two levels of parallelism:
## Top level: Distributed MPI runs several copies of this entire script.
##            Instances differ by their comm.rank() designation.
## Inner level: The unix fork (copy-on-write) shared memory parallel execution
##            of the mc.function() managed by parallel::mclapply()
## Further levels are possible: multithreading in compiled code and communicator
## splitting at the distributed MPI level.

suppressMessages(library(pbdMPI))
comm.print(sessionInfo())

## get node name
host = system("hostname", intern = TRUE)

mc.function = function(x) {
    Sys.sleep(1) # replace with your function for mclapply cores here
    Sys.getpid() # returns process id
}

## Compute how many cores per R session are on this node
local_ranks_query = "echo $OMPI_COMM_WORLD_LOCAL_SIZE"
ranks_on_my_node = as.numeric(system(local_ranks_query, intern = TRUE))
cores_on_my_node = parallel::detectCores()
cores_per_R = floor(cores_on_my_node/ranks_on_my_node)
cores_total = allreduce(cores_per_R)  # adds up over ranks

## Run mclapply on allocated cores to demonstrate fork pids
my_pids = parallel::mclapply(1:cores_per_R, mc.function, mc.cores = cores_per_R)
my_pids = do.call(paste, my_pids) # combines results from mclapply
##
## Same cores are shared with OpenBLAS (see flexiblas package)
##            or for other OpenMP enabled codes outside mclapply.
## If BLAS functions are called inside mclapply, they compete for the
##            same cores: avoid or manage appropriately!!!

## Now report what happened and where
msg = paste0("Hello World from rank ", comm.rank(), " on host ", host,
             " with ", cores_per_R, " cores allocated\n",
             "            (", ranks_on_my_node, " R sessions sharing ",
             cores_on_my_node, " cores on this host node).\n",
             "      pid: ", my_pids, "\n")
comm.cat(msg, quiet = TRUE, all.rank = TRUE)


comm.cat("Total R sessions:", comm.size(), "Total cores:", cores_total, "\n",
         quiet = TRUE)
comm.cat("\nNotes: cores on node obtained by: detectCores {parallel}\n",
         "       ranks (R sessions) per node: OMPI_COMM_WORLD_LOCAL_SIZE\n",
         "       pid to core map changes frequently during mclapply\n",
         quiet = TRUE)

finalize()
```

## Submit a job on a cluster


:::::::::::::::::::::::: solution

## Slurm


```bash
#!/bin/bash
#SBATCH -J hello
#SBATCH -A CSC489
#SBATCH -p batch
#SBATCH --nodes=4
#SBATCH --mem=0
#SBATCH -t 00:00:10
#SBATCH -e ./hello.e
#SBATCH -o ./hello.o
#SBATCH --open-mode=truncate

## above we request 4 nodes and all memory on the nodes

## assumes this repository was cloned in your home area
cd ~/R4HPC/code_1
pwd

## modules are specific to andes.olcf.ornl.gov
module load openblas/0.3.17-omp
module load flexiblas
flexiblas add OpenBLAS $OLCF_OPENBLAS_ROOT/lib/libopenblas.so
export LD_PRELOAD=$OLCF_FLEXIBLAS_ROOT/lib64/libflexiblas.so
module load r
echo -e "loaded R with FlexiBLAS"
module list

## above supplies your R code with FlexiBLAS-OpenBLAS on Andes
## but matrix computation is not used in the R illustration below

# An illustration of fine control of R scripts and cores on several nodes
# This runs 4 R sessions on each of 4 nodes (for a total of 16).
#
# Each of the 16 hello_world.R scripts will calculate how many cores are
# available per R session from environment variables and use that many
# in mclapply.
#
# NOTE: center policies may require dfferent parameters
#
# runs 4 R sessions per node
mpirun --map-by ppr:4:node Rscript hello_balance.R
```
:::::::::::::::::::::::::::::::::


:::::::::::::::::::::::: solution

## PBS

```bash
#!/bin/bash
#PBS -N hello
#PBS -A DD-21-42
#PBS -l select=4:mpiprocs=16
#PBS -l walltime=00:00:10
#PBS -q qprod
#PBS -e hello.e
#PBS -o hello.o

cat $BASH_SOURCE 
cd ~/R4HPC/code_1
pwd

## module names can vary on different platforms
module load R
echo "loaded R"

## prevent warning when fork is used with MPI
export OMPI_MCA_mpi_warn_on_fork=0
export RDMAV_FORK_SAFE=1

# Fix for warnings from libfabric/1.12 on Karolina
module swap libfabric/1.12.1-GCCcore-10.3.0 libfabric/1.13.2-GCCcore-11.2.0 

time mpirun --map-by ppr:4:node Rscript hello_balance.R
```


:::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: keypoints 

- Parallel R code distributes work
- There is shared memory and distributed memory parallelizm
- You can test parallel code on your own local machine
- There are several different job schedulers, but they share many similarities so you can learn a new one when needed

::::::::::::::::::::::::::::::::::::::::::::::::

