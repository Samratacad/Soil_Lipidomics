graph TD
    A[Ambient] --> E[Freeze dried soil samples]
    B[Ambient + Drought] --> E
    C[Future +300 ppm CO2] --> E
    D[Future +300 ppm CO2 + 3°C] --> E
    
    E --> F[Total Lipid Extraction]
    G[Class specific Heavy Isotope standards] --> F
    H[NIST SRM 1950 Plasma Stul] --> F
    
    F --> I[LC/Q-Exactive MS/MS]
    I --> J[Untargeted analysis]
    
    J --> K[Library search]
    J --> L[In-Silico MS/MS prediction]
    J --> M[Online Search GNPS platform]
    
    J --> N[LipidQC]
    J --> O[POOLQC]
    J --> P[External Standard Calibration]
    J --> Q[Lipid Deuterium Internal Standard]
    
    style K fill:#90EE90
    style L fill:#90EE90
    style M fill:#90EE90
    style N fill:#00FFFF
    style O fill:#00FFFF
    style P fill:#00FFFF
    style Q fill:#00FFFF


