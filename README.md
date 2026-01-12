# Hy-MAD-Seismic-Anomaly-Detection
# Hy-MAD: Seismic Anomaly Detection Algorithm

[![Language](https://img.shields.io/badge/MATLAB-R2020b%2B-orange.svg)](https://www.mathworks.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Important Note
**This repository contains the source code accompanying a manuscript currently submitted to *Computers & Geosciences*. The code is provided to assist reviewers and editors in evaluating the reproducibility of the proposed method.**

## Overview
This project implements the **Hy-MAD (Hybrid Median-Absolute-Deviation)** algorithm, a novel approach for detecting seismic anomalies in geoelectric data. The algorithm is designed to distinguish between true tectonic anomalies and high-amplitude natural noise (spikes).

This repository allows users to reproduce **Figures 1, 2, and 3** presented in the manuscript.

## Repository Structure
* `main.m`: The primary MATLAB script for simulation and visualization.
* `Hy_MAD_sample.txt`: A sample dataset (Time vs. Voltage) containing real background noise and natural spikes.
* `README.md`: Documentation.

## Requirements
* **MATLAB**: Version R2018a or later.
* **Toolboxes**: Signal Processing Toolbox.

## Installation & Usage
1.  Clone this repository:
    ```bash
    git clone https://github.com/mulukavak/Hy-MAD-Seismic-Anomaly-Detection
    ```
2.  Open MATLAB and navigate to the project folder.
3.  Run the `main.m` script:
    ```matlab
    >> main
    ```
4.  The script will automatically:
    * Load the `Hy_MAD_sample.txt` data.
    * Inject a synthetic anomaly (as described in the Methodology section of the paper).
    * Generate the comparison plots between the **Classical Method** and **Hy-MAD**.
