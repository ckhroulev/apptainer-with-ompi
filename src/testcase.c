#include <mpi.h>
#include <stdio.h>

int main(int argc, char **argv) {
  int rank = 0;
  int size = 0;

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  if (rank == 0) {
    printf("Size: %d\n", size);
  }

  MPI_Finalize();
  return 0;
}
