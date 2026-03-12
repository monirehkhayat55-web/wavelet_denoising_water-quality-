# Wavelet Denoising for Water Quality Time-Series

## Overview
Wavelet-ANFIS for TP Time Series Prediction
This repository presents a Wavelet-ANFIS workflow for modeling and reconstructing the total phosphorus (TP) time series from water quality variables
##📌The workflow includes:

Splitting the dataset into training and test periods
Decomposing input signals using DWT
Constructing the low-pass TP target using a surrogate regression equation
Training an ANFIS model on the low-frequency components
Evaluating model performance on training and test data
Reconstructing the predicted TP time series using inverse DWT (IDWT)

##📌 study Period

The example code uses a time window from January 1 to February 10:
Training set: January 1 to January 30
Test set: January 31 to February 10

##📌 Methodology

Wavelet transform: DWT / IDWT
Wavelet family: db4
Model: ANFIS
FIS initialization: Subtractive Clustering
Optimization: Hybrid learning

##📌The code produces:

ANFIS predictions for training and test datasets
RMSE values for train and test phases
plots of targets, outputs, and errors
reconstructed TP time series
final model file (TP_FIS)
