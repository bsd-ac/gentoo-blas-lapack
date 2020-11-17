import numpy as np

np.random.seed(0)

size = 1500
A, B = np.random.random((size, size)), np.random.random((size, size))

# Matrix multiplication
np.dot(A, B)
