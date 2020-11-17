      PROGRAM   MAIN

      IMPLICIT NONE

      DOUBLE PRECISION ALPHA, BETA
      INTEGER          N, I, J
      PARAMETER        (N=1500)
      DOUBLE PRECISION A(N,N), B(N,N), C(N,N)

      ALPHA = 1.0 
      BETA = 0.0

      DO I = 1, N
        DO J = 1, N
          A(I,J) = (I-1) * N + J
          B(I,J) = -((I-1) * N + J)
          C(I,J) = 0.0
        END DO
      END DO

      CALL DGEMM('N','N',N,N,N,ALPHA,A,N,B,N,BETA,C,N)

      STOP 

      END

