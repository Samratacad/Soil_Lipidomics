# High-resolution lipidomics for decoding soil biome: Improved lipid annotation, quantitation, and response to climate stress

This README describes the workflow for analyzing soil samples using the protocol provided in the paper. It also include relevant data, rnotebook, jupyternotebook files, scripts used to generate figures and tables for the published article.


## Results
Here you can find the codes, generated figures, and datafile used for figures in the respective folder

### Main Figures
- Fig1.[Integrated soil lipidomics worklfow](Results/Figure1/soil-lipidomics-workflow.svg)
- Fig2.[Retention time distribution of lipid classes from fungal lipidome analysis](Results/Figure2/FIGURE-2.svg)
- Fig3.[Comprehensive characterization of soil lipidome in climgrass experiment](Results/Figure3/Figure3.html)
- Fig4.[Predicitive modeling of lipid ionization efficiency](Results/Figure4/Final-plot-ionization-efficiency.ipynb)
- Fig5.[NMDS ordination of lipidomics profiles across organism groups](Results/Figure5/figure5.ipynb)
- Fig6. [Influence of climate and drought conditions on soil lipid composition and diversity](Results/Figure6)
- Fig7. [Heatmap of fatty acid profiles in significant lipid subclasses under climate and drought treatments](Results/Figure7)


### Supplementary files
- [Info](supplementary/Table-S1.docx)

### Supplementary Figures

- S1.[QC consistency: Bland-Altman analysis of ionization modes]()
- S2.[Lipid molecular networking using MS/MS and retention data](Results/Validation-of-current-lipidomics-workflow/LipidStandards/mass-spec-standards.ipynb)
- S3.[Hierarchical network of significant lipid in ClimGrass](supplementary/calibration_table.pdf)
- S4.[Hierarchical clustering heatmap of FDR-signficant lipid compound across treatments](supplementary/QC_percentage_differences_plot_with_threshold_neg.pdf)
- S5.[Total lipid concentration across climate and drought treatments]()
- S6.[Lipid class composition under ambient and future climate with or without drought](supplementary/retention_time_cv_distribution.pdf)
- S7.[Subclass-level variation in glycerolipids across climate and drought treatments](supplementary/Soil_lipidomcis_NISTSRM1950.png)
- S8.[Glycerophospholipid subclass changes across climate and drought treatments]()
- S9. [Sphingolipid subclass variation under climate and drought treatments](supplementary/significant_compounds_heatmap.pdf)
- S10. [Accuracy assessment of SRM 1950 metabolites in frozen human plasma using postive and negative ESI modes]()
- S11. [Quality control trendlines and retention time variability for soil lipid classes]()
- S12. [Lipid specificity across treatments]()
- S13. [Retention time distribution of lipid classes in ClimGrass samples]()

### Supplementary Tables
- S1. [Reagents and standards]()
- S2. [Lipid nomenclature of different lipid classes in this study ]()
- S3. [Microbial cultivation and preperation method]()
- S4. [UHPLC gradient]()
- S5. [HRMS/MS parameters for Q Exactive]()
- S6. [QA ILS]()
- S7. [Measurement accuracy summary compared against SRM 1950]()
- S8. [Comprehensive table of annotated compounds using SIRIUS 5, Lipidsearch 5, GNPS]()
- S9. [LOD and LOQ for best molecule each lipid subclass]()
- S10. [PaDEL molecular descriptors]()
- S11. [Top features in stepwise-regression model for each adduct type]()
- S12. [LOD & LOQ of lipid standards for each lipid subclass in all adduct formation]()
- S13. [Comparision of lipid extration recoveries between soil samples and NIST 1950 plasma]()




## Workflow Overview

1. Sample Preparation
2. Lipid Extraction
3. Chromatographic & mass spectrometry Analysis
4. Data Processing
5. Quality Control
6. Compound Identification and Quantification



### 1. Sample Preparation

- [Freeze-dried soil samples (3x per treatment)](methods/Extraction/Sample_used_for_lipid_extraction.pdf)
- [Class-specific heavy isotope standards (13 classes, 10ng/compound)](methods/Extraction/Internal_Standard_spiked_in_soil_samples.pdf)
- [NIST SRM 1950 Plasma (50ul) as a reference](https://tsapps.nist.gov/srmext/certificates/1950.pdf)

### 2. Lipid Extraction

- [Total Lipid Extraction protocol](methods/Extraction/TLE-SOP.pdf)
- [Sample Worklist (spike External Standards, pool QC Samples)](methods/Extraction/sample-worklist-climgrass.pdf)

### 3. Chromatographic & High-resolution MS/MS analysis

- LC Orbitrap MS/MS
  - [LC parameters](methods/LC-parameters.pdf)
  - [Orbitrap parameters](methods/Orbitrap-parameters.pdf)
- Untargeted analysis
  - Raw data files are deposited in [MASSIVE database](ftp://massive.ucsd.edu/v08/MSV000096136/)
 
### 4. Quality Control

Multiple QC steps are implemented throughout the workflow:
- **Lipidomics Minimal Reporting Checklist**
  - [Lipidomics sample checklist](https://github.com/Samratacad/Soil_Lipidomics/blob/main/methods/Quality-control/TableS5_QA-ILS.pdf)
- **NIST SRM Inter Laboratory Comparison**
  - [Positive Ionization Mode Table](methods/Quality-control/NIST-SRM/positive/OE12-3LipidQC-v1.0pos.pdf)
  - [Positive Ionization Mode Plot](methods/Quality-control/NIST-SRM/positive/SRM9150positive.png)
  - [Negative Ionization Mode Table](methods/Quality-control/NIST-SRM/negative/LipidQC-v1.0-neg.pdf)
  - [Negative Ionization Mode Plot](methods/Quality-control/NIST-SRM/negative/nist-neg.png)
- **POOL QC**
  - [Analysis of variance across POOL sample runs (Positive mode)](supplementary/QC_percentage_differences_plot_with_threshold_neg.pdf)
- **External Standard Calibration**
  - 
- **Lipid Recovery using Internal Standard**
    

### 5. Data Processing
*raw files are processed using Lipidsearch 5 and Mzmime3*
- [Mzmime3 files](methods/Dataprocessing/mzmine3)
- [Lipidsearch5](methods/Dataprocessing/lipidsearch5/lipidsearch5-identification.pdf)
- [Sirius5](methods/Dataprocessing/sirius5/SIRIUS5predictionSettings.pdf)
- [Skyline](methods/SKYLINE-Workflow/skyline.md) *transition list is prepared to perform a targeted analysis for quantification*
- **GNPS analysis perform online. Here are the links for files and results**
  - [GNPS_POS](https://gnps.ucsd.edu/ProteoSAFe/status.jsp?task=14a6275c9e264972849f2b6a3f39df25)
  - [GNPS_NEG](https://gnps.ucsd.edu/ProteoSAFe/status.jsp?task=6f2be01f485b4a34a77ec1c735a59357)

### 6. Compound Identification and Quantification

#### Identification:
  Here you can find the combined annotation from all [approach](supplementary/Identification/ALL-COMBINED.xlsx)
  - **Library-search**
    - [Lipidsearch 5](supplementary/Identification/lipidsearch5-identification)
    - [Online GNPS search](supplementary/Identification/GNPS-identification)
  - **Prediction-based**
    - [SIRIUS 5](supplementary/Identification/SIRIUS5-identification) 

#### Quantification:
- [Compound Classification using Class-specific standards](Results/Figure5/figure5.ipynb)
- [Compound Quantification using Ionization Efficiency Model](Results/IEmodel)

## Tools and Technologies

- LC-MS/MS: Orbitrap
- Software: LipidSearch 5, SIRIUS 5, GNPS platform

## Notes

- This workflow integrates both wet-lab techniques and computational analysis.
- Quality control measures are implemented at multiple stages to ensure data reliability.
- The process allows for both targeted and untargeted analysis of lipids in soil samples.

For more detailed information on each step, please refer to the specific folder readmd file.
