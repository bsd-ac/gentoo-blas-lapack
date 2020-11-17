      PROGRAM   MAIN

      IMPLICIT NONE

      DOUBLE PRECISION ALPHA, BETA
      INTEGER          M, K, N, I, J
      PARAMETER        (M=1500, K=1500, N=1500)
      DOUBLE PRECISION A(M,K), B(K,N), C(M,N)

10    FORMAT(a,I5,a,I5,a,I5,a,I5,a)
      ALPHA = 1.0 
      BETA = 0.0

      DO I = 1, M
        DO J = 1, K
          A(I,J) = (I-1) * K + J
        END DO
      END DO

      DO I = 1, K
        DO J = 1, N
          B(I,J) = -((I-1) * N + J)
        END DO
      END DO

      DO I = 1, M
        DO J = 1, N
          C(I,J) = 0.0
        END DO
      END DO

      CALL DGEMM('N','N',M,N,K,ALPHA,A,M,B,K,BETA,C,M)

 20   FORMAT(6(F12.0,1x))

 30   FORMAT(6(ES12.4,1x))

      STOP 

      END

