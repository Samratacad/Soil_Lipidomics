# Interactive Workflow Diagram

The following diagram represents the workflow for soil sample analysis. Click on any box to view more detailed information about that process.

```mermaid
graph TD
    A[Ambient]
    click A "ambient.md" "View details about Ambient conditions"
    B[Ambient + Drought]
    click B "ambient-drought.md" "View details about Ambient + Drought conditions"
    C[Future +300 ppm CO2]
    click C "future-co2.md" "View details about Future +300 ppm CO2 conditions"
    D[Future +300 ppm CO2 + 3°C]
    click D "future-co2-temp.md" "View details about Future +300 ppm CO2 + 3°C conditions"
    E[Freeze dried soil samples]
    click E "freeze-dried-samples.md" "View details about Freeze dried soil samples"
    F[Total Lipid Extraction]
    click F "lipid-extraction.md" "View details about Total Lipid Extraction"
    G[Class specific Heavy Isotope standards]
    click G "isotope-standards.md" "View details about Class specific Heavy Isotope standards"
    H[NIST SRM 1950 Plasma Stul]
    click H "nist-srm-1950.md" "View details about NIST SRM 1950 Plasma Stul"
    I[LC/Q-Exactive MS/MS]
    click I "lc-ms-ms.md" "View details about LC/Q-Exactive MS/MS"
    J[Untargeted analysis]
    click J "untargeted-analysis.md" "View details about Untargeted analysis"
    K[Library search]
    click K "library-search.md" "View details about Library search"
    L[In-Silico MS/MS prediction]
    click L "in-silico-prediction.md" "View details about In-Silico MS/MS prediction"
    M[Online Search GNPS platform]
    click M "gnps-search.md" "View details about Online Search GNPS platform"
    N[LipidQC]
    click N "lipid-qc.md" "View details about LipidQC"
    O[POOLQC]
    click O "pool-qc.md" "View details about POOLQC"
    P[External Standard Calibration]
    click P "external-calibration.md" "View details about External Standard Calibration"
    Q[Lipid Deuterium Internal Standard]
    click Q "internal-standard.md" "View details about Lipid Deuterium Internal Standard"

    A --> E
    B --> E
    C --> E
    D --> E
    E --> F
    G --> F
    H --> F
    F --> I
    I --> J
    J --> K
    J --> L
    J --> M
    J --> N
    J --> O
    J --> P
    J --> Q

    style K fill:#90EE90
    style L fill:#90EE90
    style M fill:#90EE90
    style N fill:#00FFFF
    style O fill:#00FFFF
    style P fill:#00FFFF
    style Q fill:#00FFFF
```

## Workflow Description

1. The process begins with four different soil sample conditions: [Ambient](ambient.md), [Ambient + Drought](ambient-drought.md), [Future +300 ppm CO2](future-co2.md), and [Future +300 ppm CO2 + 3°C](future-co2-temp.md).

2. These samples are [freeze-dried](freeze-dried-samples.md) for analysis.

3. [Total Lipid Extraction](lipid-extraction.md) is performed on the freeze-dried samples, incorporating [Class specific Heavy Isotope standards](isotope-standards.md) and [NIST SRM 1950 Plasma (Stul)](nist-srm-1950.md).

4. The extracted samples undergo [LC/Q-Exactive MS/MS analysis](lc-ms-ms.md).

5. [Untargeted analysis](untargeted-analysis.md) is performed on the MS/MS data.

6. The untargeted analysis results are then processed through several pathways:
   - [Library search](library-search.md)
   - [In-Silico MS/MS prediction](in-silico-prediction.md)
   - [Online Search GNPS platform](gnps-search.md)
   - Quality control measures: [LipidQC](lipid-qc.md), [POOLQC](pool-qc.md)
   - Calibration: [External Standard Calibration](external-calibration.md), [Lipid Deuterium Internal Standard](internal-standard.md)

Note: In the diagram, green boxes represent search and prediction processes, while blue boxes represent quality control and calibration processes. Click on any box in the diagram or any link in this description to view more detailed information about that specific process.
