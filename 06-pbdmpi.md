---
title: "pbdMPI - Parallel and Big Data interface to MPI"
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- What types of functions does MPI provide?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Demonstrate some of the functionality of the pbd bindings to the Message Passing Interface (MPI) 

::::::::::::::::::::::::::::::::::::::::::::::::

## Introduction

### Hello World in Serial

```r
library( pbdMPI, quiet = TRUE )

text = paste( "Hello, world from", comm.rank() )
print( text )

finalize()
```

### Rank

```r
library( pbdMPI, quiet = TRUE )

my.rank <- comm.rank()
comm.print( my.rank, all.rank = TRUE )

finalize()
```

### Hello World in Parallel

```r
library( pbdMPI, quiet = TRUE )

print( "Hello, world print" )

comm.print( "Hello, world comm.print" )

comm.print( "Hello from all", all.rank = TRUE, quiet = TRUE )

finalize()
```

### Map Reduce

```r
library( pbdMPI , quiet = TRUE)

## Your "Map" code
n = comm.rank() + 1

## Now "Reduce" but give the result to all
all_sum = allreduce( n ) # Sum is default

text = paste( "Hello: n is", n, "sum is", all_sum )
comm.print( text, all.rank = TRUE )

finalize ()
```

### Calculate Pi

```r
### Compute pi by simulaton
library( pbdMPI, quiet = TRUE )

comm.set.seed( seed = 1234567, diff = TRUE )

my.N = 1e7 %/% comm.size()
my.X = matrix( runif( my.N * 2 ), ncol = 2 )
my.r = sum( rowSums( my.X^2 ) <= 1 )
r = allreduce( my.r )
PI = 4*r / ( my.N * comm.size() )
comm.print( PI )

finalize()
```

### Broadcast

```r
library( pbdMPI, quiet = TRUE )

if ( comm.rank() == 0 ){
  x = matrix( 1:4, nrow = 2 )
} else {
  x = NULL
}

y = bcast( x )

comm.print( y, all.rank = TRUE )
comm.print( x, all.rank = TRUE )

finalize()
```

### Gather

```r
library( pbdMPI, quiet = TRUE )

comm.set.seed( seed = 1234567, diff = TRUE )

my_rank = comm.rank()
n = sample( 1:10, size = my_rank + 1 )
comm.print(n, all.rank = TRUE)

gt = gather(n)

obj_len = gather(length(n))
comm.cat("gathered unequal size objects. lengths =", unlist(obj_len), "\n")

comm.print( unlist( gt ), all.rank = TRUE )

finalize()
```

### Gather Unequal

```r
library( pbdMPI, quiet = TRUE )

comm.set.seed( seed = 1234567, diff = TRUE )

my_rank = comm.rank( )
n = sample( 1:10, size = my_rank + 1 )
comm.print( n, all.rank = TRUE )

gt = gather( n )

obj_len = gather( length( n ) )
comm.cat( "gathered unequal size objects. lengths =", obj_len, "\n" )

comm.print( unlist( gt ), all.rank = TRUE )

finalize( )
```

### Gather Named

```r
library( pbdMPI, quiet = TRUE )

comm.set.seed( seed = 1234567, diff = TRUE )

my_rank = comm.rank()
n = sample( 1:10, size = my_rank + 1 )
names(n) = paste0("a", 1:(my_rank + 1))
comm.print(n, all.rank = TRUE)

gt = gather( n )

comm.print( unlist( gt ), all.rank = TRUE )

finalize()
```

### Chunk

```r
library( pbdMPI, quiet = TRUE )

my.rank = comm.rank( )

k = comm.chunk( 10 )
comm.cat( my.rank, ":", k, "\n", all.rank = TRUE, quiet = TRUE)

k = comm.chunk( 10 , form = "vector")
comm.cat( my.rank, ":", k, "\n", all.rank = TRUE, quiet = TRUE)

k = comm.chunk( 10 , form = "vector", type = "equal")
comm.cat( my.rank, ":", k, "\n", all.rank = TRUE, quiet = TRUE)

finalize( )
```

### Timing

```r
library( pbdMPI, quiet = TRUE )

comm.set.seed( seed = 1234567, diff = T )

test = function( timed )
{
  ltime = system.time( timed )[ 3 ]

  mintime = allreduce( ltime, op='min' )
  maxtime = allreduce( ltime, op='max' )
  meantime = allreduce( ltime, op='sum' ) / comm.size()

  return( data.frame( min = mintime, mean = meantime, max = maxtime ) )
}

# generate 10,000,000 random normal values (total)
times = test( rnorm( 1e7/comm.size() ) ) # ~76 MiB of data
comm.print( times )

finalize()
```
Are there bindings to MPI_wtime()?

### Covariance

```r
library( pbdMPI, quiet = TRUE )

comm.set.seed( seed = 1234567, diff = TRUE )

## Generate 10 rows and 3 columns of data per process
my.X = matrix( rnorm(10*3), ncol = 3 )

## Compute mean
N = allreduce( nrow( my.X ), op = "sum" )
mu = allreduce( colSums( my.X ) / N, op = "sum" )

## Sweep out mean and compute crossproducts sum
my.X = sweep( my.X, STATS = mu, MARGIN = 2 )
Cov.X = allreduce( crossprod( my.X ), op = "sum" ) / ( N - 1 )

comm.print( Cov.X )

finalize()
```

### Matrix reduction
```r
library( pbdMPI, quiet = TRUE )

x <- matrix( 10*comm.rank() + (1:6), nrow = 2 )

comm.print( x, all.rank = TRUE )

z <- reduce( x ) # knows it's a matrix

comm.print( z, all.rank = TRUE )

finalize()
```

### Ordinary Least Squares

```r
### Least Squares Fit wia Normal Equations (see lm.fit for a better way)
library( pbdMPI, quiet = TRUE )

comm.set.seed( seed = 12345, diff = TRUE )

## 10 rows and 3 columns of data per process
my.X = matrix( rnorm(10*3), ncol = 3 )
my.y = matrix( rnorm(10*1), ncol = 1 )

## Form the Normal Equations components
my.Xt = t( my.X )
XtX = allreduce( my.Xt %*% my.X, op = "sum" )
Xty = allreduce( my.Xt %*% my.y, op = "sum" )

## Everyone solve the Normal Equations
ols = solve( XtX, Xty )

comm.print( ols )

finalize()
```

### QR Decomposition

```r
library(cop, quiet = TRUE)

rank = comm.rank()
size = comm.size()

rows = 3
cols = 3
xb = matrix((1:(rows*cols*size))^2, ncol = cols) # a full matrix
xa = xb[(1:rows) + rank*rows, ]  # split by row blocks

comm.print(xa, all.rank = TRUE)
comm.print(xb)

## compute usual QR from full matrix
rb = qr.R(qr(xb))
comm.print(rb)

## compute QR from gathered local QRs
rloc = qr.R(qr(xa))  # compute local QRs
rra = allgather(rloc)  # gather them into a list
rra = do.call(rbind, rra)  # rbind list elements
comm.print(rra)  # print combined local QRs
ra = qr.R(qr(rra)) # QR the combined local QRs
comm.print(ra)

## use cop package to do it again via qr_allreduce
ra = qr_allreduce(xa)
comm.print(ra)

finalize()
```

### Collective communication for a one dimensional domain decomposition

```r
## Splits the world communicator into two sets of smaller communicators and
## demonstrates how a sum collective works
library(pbdMPI)
.pbd_env$SPMD.CT
comm_world = .pbd_env$SPMD.CT$comm  # default communicator
my_rank = comm.rank(comm_world) # my default rank in world communicator
comm_new = 5L       # new communicators can be 5 and up (0-4 are taken)

row_color = my_rank %/% 2L # set new partition colors and split accordingly
comm.split(comm_world, color = row_color, key = my_rank, newcomm = comm_new)
barrier()
my_newrank = comm.rank(comm_new)
comm.cat("comm_world:", comm_world, "comm_new", comm_new, "row_color:",
         row_color, "my_rank:", my_rank, "my_newrank", my_newrank, "\n",
         all.rank = TRUE)
x = my_rank + 1
comm.cat("x", x, "\n", all.rank = TRUE, comm = comm_world)
xa = allreduce(x, comm = comm_world)
xb = allreduce(x, comm = comm_new)

comm.cat("xa", xa, "xb", xb, "\n", all.rank = TRUE, comm = comm_world)
comm.free(comm_new)


finalize()
```

### Collective communication for a two dimensional domain decomposition

```r
## Run with:
## mpiexec -np 32 Rscript comm_split8x4.R
##
## Splits a 32-rank communicator into 4 row-communicators of size 8 and
## othogonal to them 8 column communicators of size 4. Prints rank assignments,
## and demonstrates how sum collectives work in each set of communicators.
##
## Useful row ooperations or column operations on tile-distrobued matrices. But
## note there is package pbdDMAT that already has these operations powered by
## ScaLAPACK.
## It can also serve for any two levels of distributed parallelism that are
## nested.
##
library(pbdMPI)

ncol = 8
nrow = 4
if(comm.size() != ncol*nrow) stop("Error: Must run with -np 32")

## Get world communicator rank
comm_w = .pbd_env$SPMD.CT$comm # world communicator (normallly assigned 0)
rank_w = comm.rank(comm_w)  # world rank

## Split comm_w into ncol communicators of size nrow
comm_c = 5L               # assign them a number
color_c = rank_w %/% nrow # ranks of same color are in same communicator
comm.split(comm_w, color = color_c, key = rank_w, newcomm = comm_c)

## Split comm_w into nrow communicators of size ncol
comm_r = 6L               # assign them a number
color_r = rank_w %% nrow  # make these orthogonal to the row communicators
comm.split(comm_w, color = color_r, key = rank_w, newcomm = comm_r)

## Print the resulting communicator colors and ranks
comm.cat(comm.rank(comm = comm_w),
         paste0("(", color_r, ":", comm.rank(comm = comm_r), ")"),
         paste0("(", color_c, ":", comm.rank(comm = comm_c), ")"),
         "\n", all.rank = TRUE, quiet = TRUE, comm = comm_w)

## Print sums of rank numbers across each communicator to illustrate collectives
x = comm.rank(comm_w)
w = allreduce(x, op = "sum", comm = comm_w)
comm.cat(" ", w, all.rank = TRUE, quiet = TRUE)
comm.cat("\n", quiet = TRUE)

r = allreduce(x, op = "sum", comm = comm_r)
comm.cat(" ", r, all.rank = TRUE, quiet = TRUE)
comm.cat("\n", quiet = TRUE)

c = allreduce(x, op = "sum", comm = comm_c)
comm.cat(" ", c, all.rank = TRUE, quiet = TRUE)
comm.cat("\n", quiet = TRUE)


#comm.free(comm_c)
#comm.free(comm_r)

finalize()
```

::::::::::::::::::::::::::::::::::::: keypoints 

- The message passing interface offers many operations that can be used to
  efficiently and portably add parallelism to your program
- It is possible to use parallel libraries to minimize the amount of parallel
  programming you need to do for your data exploration and data analysis

::::::::::::::::::::::::::::::::::::::::::::::::

