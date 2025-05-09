# Forecasting-Hourly-Energy-Consumption-using-ARH-1-

"Forecasting Hourly Energy Consumption: Is Functional Data Analysis Worth the Complexity?" <br>
Second Reader - Zhenisbek Assylbekov, <br>
Supervisor - Rustem Takhanov, <br>
Submitted By - Rustem Kaliyev <br>


This repository accompanies thesis, **“Forecasting Hourly Energy Consumption: Is Functional Data Analysis Worth the Complexity?”** It contains the experimental pipeline used to compare a functional autoregressive Hilbertian model (ARH (1)), a classical PCA + VAR (1) model, and several modern deep‑learning baselines (NHITS, LSTM, and TimeGPT) on PJM’s (Pennsylvania-New Jersey-Maryland Interconnection) hourly load data.

> **Key takeaway:** In a clean, densely–sampled setting the simple PCA + VAR (1) approach matches the accuracy of ARH (1) (\~2 % sMAPE) and outperforms deeper neural models.

<br>

## Repository structure

|                       |                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------- |
| `dataset/`            | PJM Hourly Load CSVs (Oct 2023 – Sep 2024, five zones: AP, DOM, PN, JC, RTO).      |
| `preds/`              | Saved forecast tables produced by the notebooks.                                   |
| `ARH.ipynb`           | Implementation of the functional ARH (1), and classical PCA+VAR(1) model.         |
| `ARH_VAR_comparison.R`| Comparison of ARH (1) and PCA+VAR(1) models across varying number of components.   |
| `NNmodels.ipynb`      | TimeGPT, NHITS & LSTM experiments via **Nixtla NeuralForecast**.                   |
| `evaluation.ipynb`    | Prediction tables, computes MAE / MSE / sMAPE, and produces comparison plots.      |


<br>

## Results snapshot

A concise comparison (full tables in `evaluation.ipynb`):

| Model         | Avg sMAPE (%) | Avg MAE | Avg MSE   |
| ------------- | ------------- | ------- | --------- |
| ARH (1)       | **1.91**      | 310     | 1.9 × 10⁷ |
| PCA + VAR (1) | **1.90**      | 305     | 1.8 × 10⁷ |
| NHITS         | 2.15          | 342     | 2.2 × 10⁷ |
| LSTM          | 3.01          | 610     | 3.6 × 10⁷ |
| TimeGPT       | 1.97          | 318     | 2.0 × 10⁷ |

<br>

## Data

* **Source:** [PJM Energy Market Hourly Load Data](https://github.com/Nixtla/transfer-learning-time-series/blob/main/datasets/pjm_in_zone.csv) (public domain).
* **Zones:** AP, DOM, JC, PN, RTO.
* **Period:** 2023‑10‑01 → 2024‑09‑30 (365 days × 24 hours).

The cleaned, timezone‑aligned CSVs live in `dataset/`. Included for convenience.

<br>

## Re‑using the code on your data

1. Replace the CSVs in `dataset/` with your own hourly series.
2. Adjust the preprocessing cell at the top of each notebook (path + column names).
3. Re‑run the notebooks — all downstream steps are parameterised.

<br>


## Acknowledgements

* Special thanks to Amantay Nurlanuly, third-year Economics student for carrying out an experiment in section 5.
* **Nixtla** for *NeuralForecast* and *TimeGPT* APIs.


