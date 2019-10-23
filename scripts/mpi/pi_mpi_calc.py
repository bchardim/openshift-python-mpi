#!/usr/bin/env python3

#
# Python MPI multithread multihost parallel calculation
#
# See https://rabernat.github.io/research_computing/parallel-programming-with-mpi-for-python.html
# See http://mpitutorial.com/tutorials/

from mpi4py import MPI
import numpy
import sys

# Montecarlo method
# If a circle of radius R is inscribed inside a square with side length 2R, then the area of the circle will be pi*R^2 and the area of the square will be (2R)^2. 
# So the ratio of the area of the circle to the area of the square will be pi/4
# This means that, if you pick n points at random inside the square, approximately n*pi/4 of those points should fall inside the circle. 
def compute_pi(samples):
    count = 0
    for x, y in samples:
        if x**2 + y**2 <= 1:
            count += 1
    pi = 4*float(count)/len(samples)
    return pi

# Create a MPI communicator and get nprocs, rank and size of communication 
# Used the default communicator named MPI.COMM_WORLD, which consists of all the processors. For many MPI codes, this is the main communicator that you will need
comm = MPI.COMM_WORLD
nprocs = comm.Get_size() # Get the number of processes
myrank = comm.Get_rank() # Get the rank of the process
# Each process inside of a communicator is assigned an incremental rank starting from zero. 
# The ranks of the processes are primarily used for identification purposes when sending and receiving messages.


# Number of iterations must be multiple of nproc
n = int(sys.argv[1])

if (myrank == 0):
    if (n % nprocs != 0):
        print ("ERROR - number of calculations must be a multiple of nproc")
        comm.Abort()

# Create sample array with random x,y points for montecarlo calculation
# This must be done only once in the first process (myrank == 0)
if myrank == 0:
    N = n // nprocs
    samples = numpy.random.random((nprocs, N, 2))
else:
    samples = None

# Scatter takes an array (samples) and distributes contiguous sections of it across the ranks of a communicator from the root process
samples = comm.scatter(samples, root=0)

# Perform montecarlo calculation on each processor
mypi = compute_pi(samples) / nprocs

# The MP reduce operation takes values in from an array on each processor and reduces them to a single result on the root process. 
# This is essentially like having a somewhat complicated send command from each process to the root process, and then having the root process perform the reduction operation. 
# Thankfully, MPI reduce does all this with one concise 
pi = comm.reduce(mypi, root=0)

# Print result
# This must be done only once in the first process (myrank == 0), collecting all other process results with previous comm.reduce
if myrank == 0:
    error = abs(pi - numpy.pi)
    print("Calculated pi is %.10f, error is %.10f" % (pi, error))

