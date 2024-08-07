# Soil Sample Analysis Workflow

This README describes the workflow for analyzing freeze-dried soil samples using a combination of chemical extraction, chromatography, and computational analysis techniques.

## Workflow Diagram

```mermaid
graph TD
    A[Freeze dried soil samples 3x per treatment] --> C[Total Lipid Extraction Batch]
    B[Class specific heavy isotope standards 13 classes, 10ng/compound] --> C
    D[NIST SRM 1950 Plasma 50ul] --> C
    C --> E[Sample Worklist spike External Standards, pool QC Samples]
    E --> F[LC Orbitrap MS/MS]
    F --> G[Untargeted analysis]
    G --> H[Identification]
    G --> I[Quantification]

    subgraph QC [Quality Control]
        style QC fill:#e6f3ff,stroke:#4da6ff,stroke-width:2px
        J[Quality Control]
        J --> L1[LipidQC]
        click L1 "#lipidqc"
        J --> L2[POOL QC]
        click L2 "#pool-qc"
        J --> L3[External Standard Calibration]
        click L3 "#external-standard-calibration"
        J --> L4[Lipid Recovery using Internal Standard]
        click L4 "#lipid-recovery-using-internal-standard"
    end

    subgraph ID [Identification Pathway]
        style ID fill:#e6ffe6,stroke:#66cc66,stroke-width:2px
        H --> M1[Library search LipidSearch 5]
        click M1 "#library-search-lipidsearch-5"
        H --> M2[In Silico MS/MS prediction SIRIUS 5]
        click M2 "#in-silico-msms-prediction-sirius-5"
        H --> M3[Online Search GNPS platform]
        click M3 "#online-search-gnps-platform"
        H --> M4[FBMN GNPS platform]
        click M4 "#fbmn-gnps-platform"
    end

    subgraph QUANT [Quantification Pathway]
        style QUANT fill:#fff0e6,stroke:#ffaa80,stroke-width:2px
        I --> K1[Compound Classification using Class specific standards]
        click K1 "#compound-classification-using-class-specific-standards"
        I --> K2[Compound Quantification using IS Model]
        click K2 "#compound-quantification-using-is-model"
    end
```

## Workflow Overview

1. Sample Preparation
2. Lipid Extraction
3. Chromatographic Analysis
4. Data Processing
5. Quality Control
6. Compound Identification and Quantification

## Results
1. [Lipid annotation](Results/Figure1/Figure1.ipynb)

## Detailed Steps

### 1. Sample Preparation

- Freeze-dried soil samples (3x per treatment)
- Class-specific heavy isotope standards (13 classes, 10ng/compound)
- NIST SRM 1950 Plasma (50ul) as a reference

### 2. Lipid Extraction

- Total Lipid Extraction Batch
- Sample Worklist (spike External Standards, pool QC Samples)

### 3. Chromatographic Analysis

- LC Orbitrap MS/MS
- Untargeted analysis

### 4. Data Processing

- Identification
- Quantification

### 5. Quality Control

Multiple QC steps are implemented throughout the workflow:

- LipidQC
- POOL QC
- External Standard Calibration
- Lipid Recovery using Internal Standard

### 6. Compound Identification and Quantification

#### Identification:
- Library search (LipidSearch 5)
- In Silico MS/MS prediction SIRIUS 5
- Online Search GNPS platform
- FBMN GNPS platform

#### Quantification:
- Compound Classification using Class-specific standards
- Compound Quantification using IS Model

## Tools and Technologies

- LC-MS/MS: Orbitrap
- Software: LipidSearch 5, SIRIUS 5, GNPS platform

## Notes

- This workflow integrates both wet-lab techniques and computational analysis.
- Quality control measures are implemented at multiple stages to ensure data reliability.
- The process allows for both targeted and untargeted analysis of lipids in soil samples.

For more detailed information on each step, please refer to the specific protocols and standard operating procedures.
