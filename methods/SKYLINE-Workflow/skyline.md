### SKYLINE WORKFLOW
**Rationale**
- Different software tools may yield varying results in peak picking and peak integration due to differences in their bioinformatics workflows. To address these discrepancies, we combined the peaks identified by multiple software programs into a single file. Peaks identified by different software were merged into a single peak if they shared a common precursor mass (within a 5 ppm tolerance), retention time (within a 0.1-minute tolerance), and precursor adduct. This approach ensures that overlapping peaks from different sources are accurately consolidated, providing a more comprehensive and reliable dataset.
- The dataset contain transition list of identified precursor ion in positive and negative mode.
  - [Negative mode](methods/SKYLINE-Workflow/SKYLINE-TRANSITION_LIST-NEG.csv)
  - [Positive mode](methods/SKYLINE-Workflow/SKYLINE-TRANSITION_LIST-POS.csv)

