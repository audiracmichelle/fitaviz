import numpy as np

def get_consecutive_ids(x):
  curr_id_zero = 0
  curr_id_non_zero = 0
  # output holders
  N = len(x)
  ids_zero = [0] * N
  ids_non_zero = [0] * N
  # initialize
  if np.isnan(x[0]):
    ids_zero[0] = np.nan
    ids_non_zero[0] = np.nan
  elif x[0] == 0:
    curr_id_zero += 1
    ids_zero[0] = curr_id_zero
    ids_non_zero[0] = np.nan
  else:
    curr_id_non_zero += 1
    ids_zero[0] = np.nan
    ids_non_zero[0] = curr_id_non_zero
  for i in range(1, len(x)):
    if np.isnan(x[i]):
        ids_zero[i] = np.nan
        ids_non_zero[i] = np.nan
    elif x[i] == 0:
        if np.isnan(x[i - 1]) or (not (x[i - 1] == 0)):  # new series
            curr_id_zero += 1
        ids_zero[i] = curr_id_zero
        ids_non_zero[i] = np.nan
    else:  # example is obs
        if np.isnan(x[i - 1]) or (x[i - 1] == 0):  # new series
            curr_id_non_zero += 1
        ids_zero[i] = np.nan
        ids_non_zero[i] = curr_id_non_zero
  return ids_zero, ids_non_zero
