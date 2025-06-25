# ================================
# 1. Load Required Libraries
# ================================
library(dplyr)
library(vegan)
library(ggplot2)
library(ggrepel)
library(svglite)
library(DT)
library(tidyr)

# ================================
# 2. Load and Clean the Data
# ================================
# Read the CSV file. (Ensure your file "Specieslist-pos.csv" is in your working directory.)
data <- read.csv("Specieslist-pos.csv", stringsAsFactors = FALSE)

# Clean column names: replace any non-alphanumeric (and non-underscore) characters with an underscore.
colnames(data) <- gsub("[^[:alnum:]_]", "_", colnames(data))

# Check that the informative 'Molecule' column exists.
if (!"Molecule" %in% colnames(data)) {
  stop("Column 'Molecule' not found in data!")
}

# ================================
# 3. Prepare Sample Data
# ================================
# Identify the sample columns (those that include "Sum_Total_Area").
sample_columns <- grep("Sum_Total_Area", colnames(data), value = TRUE)

# Select these sample columns and convert them to numeric.
sample_data <- data %>% 
  select(all_of(sample_columns)) %>% 
  mutate(across(everything(), as.numeric))

# Because the "Molecule" column may have duplicate entries, make the row names unique.
unique_molecules <- make.unique(as.character(data$Molecule))
rownames(sample_data) <- unique_molecules

# ================================
# 4. Normalize Each Sample by Biomass
# ================================
# Create biomass_data with the provided biomass values.
biomass_data <- data.frame(
  Species = c(
    "Allium_Ursinum_OE11_E4_P14POS_Sum_Total_Area",
    "Auricularia_Polytricha_OE21_4_F7POS_Sum_Total_Area",
    "Blastobotrys_Sp_LG1401_ESA_OE21_4_E8F45POS_Sum_Total_Area",
    "Craterellus_Cornucopioides_OE21_4_F12POS_Sum_Total_Area",
    "Equisetum_Arvense_OE11_E4_P11POS_Sum_Total_Area",
    "Ginkgo_biloba_OE11_3_E4_P27POS_Sum_Total_Area",
    "Labilithrix_luteola_1B3R5D0E2_Sum_Total_Area",
    "Paenibacillus_Alginolyticus_2B2R5DOE2_Sum_Total_Area",
    "Rhodococcus_Sp_OE11_3_E4_A1POS_Sum_Total_Area",
    "Thalassiosira_weissflogii_P42POS_Sum_Total_Area",
    "Ulva_P56POS_20240924144544_Sum_Total_Area",
    "Valonia_P52POS_20240924210008_Sum_Total_Area"
  ),
  Biomass = c(21.02, 36.08, 30.11, 29.73, 17.31, 13.71, 17.06, 4.48, 1.10, 12.50, 27.50, 9.40)
)
biomass_data$Species <- gsub("[^[:alnum:]_]", "_", biomass_data$Species)

# For each sample column, divide its values by the corresponding biomass.
for (sample in sample_columns) {
  biomass_value <- biomass_data %>% 
    filter(Species == sample) %>% 
    pull(Biomass)
  
  if (length(biomass_value) == 0) {
    warning(paste("Biomass value not found for sample:", sample))
  } else {
    sample_data[[sample]] <- sample_data[[sample]] / biomass_value
  }
}

# ================================
# 5. Replace Missing Values and Log Transform
# ================================
# For each lipid (row), replace NAs with (min value / 5) or a small constant if all are NA.
sample_data <- as.data.frame(t(apply(sample_data, 1, function(row) {
  if (all(is.na(row))) {
    row[is.na(row)] <- 1e-6
  } else {
    min_val <- min(row, na.rm = TRUE)
    row[is.na(row)] <- min_val / 5
  }
  return(row)
})))

# Log10-transform the data.
transformed_data <- log10(sample_data + 1e-6)
min_val <- min(transformed_data, na.rm = TRUE)
if (min_val < 0) {
  transformed_data <- transformed_data + abs(min_val)
}

# ================================
# 6. Transpose Data for NMDS Analysis
# ================================
# At this point, rows represent lipids and columns represent samples.
# For NMDS, we need rows = samples and columns = lipid compounds.
sample_names <- colnames(transformed_data)
transformed_data <- as.data.frame(t(transformed_data))
rownames(transformed_data) <- sample_names

# ================================
# 7. Define Sample Groups
# ================================
# Create a data frame with sample names and assign each sample to a taxonomic group.
sample_groups <- data.frame(Sample = sample_names)
sample_groups$Group <- case_when(
  grepl("Labilithrix|Paenibacillus|Rhodococcus", sample_names) ~ "Bacteria",
  grepl("Auricularia|Blastobotrys|Craterellus", sample_names) ~ "Fungi",
  grepl("Allium|Equisetum|Ginkgo", sample_names) ~ "Plants",
  grepl("Thalassiosira|Ulva|Valonia", sample_names) ~ "Algae",
  TRUE ~ "Unknown"
)

# ================================
# 8. NMDS Analysis and Plotting
# ================================
# Compute the Bray–Curtis distance matrix and run NMDS.
distance_matrix <- vegdist(transformed_data, method = "bray")
nmds_result <- metaMDS(distance_matrix, k = 2, trymax = 50, trace = TRUE)

# Extract NMDS points and merge with sample group information for plotting.
nmds_points <- as.data.frame(nmds_result$points)
nmds_points$Sample <- rownames(nmds_points)
nmds_points <- left_join(nmds_points, sample_groups, by = "Sample")

# Plot the NMDS ordination.
ggplot(nmds_points, aes(x = MDS1, y = MDS2, color = Group)) +
  geom_point(size = 4) +
  theme_minimal(base_size = 14) +
  labs(title = "NMDS Analysis of Lipid Data",
       x = "NMDS1", y = "NMDS2")

# ================================
# 9. SIMPER Analysis
# ================================
# Ensure the group factor is a factor.
sample_groups$Group <- as.factor(sample_groups$Group)

# Run SIMPER analysis comparing groups.
simper_results <- simper(transformed_data, sample_groups$Group)
simper_summary <- summary(simper_results)
print(simper_summary)

cat("Pairwise comparisons available:\n")
print(names(simper_results))

# Loop through each pairwise comparison and print the top 10 contributing compounds.
for (comp in names(simper_results)) {
  cat("\n========================================\n")
  cat("Comparison:", comp, "\n")
  
  result_comp <- simper_results[[comp]]
  
  # Define the candidate columns (we expect "average", "sd", "ratio", and "cumsum").
  candidate_cols <- c("average", "sd", "ratio", "cumsum")
  
  # Select only columns that exist and whose lengths match that of 'average'.
  valid_cols <- candidate_cols[sapply(candidate_cols, function(col) {
    !is.null(result_comp[[col]]) && length(result_comp[[col]]) == length(result_comp$average)
  })]
  
  if(length(valid_cols) == 0) {
    valid_cols <- "average"
  }
  
  # Convert the selected components to a data frame.
  result_comp_df <- do.call(cbind, result_comp[valid_cols])
  result_comp_df <- as.data.frame(result_comp_df)
  
  # Sort by "average" (descending) and print the top 10 compounds.
  result_sorted <- result_comp_df[order(-result_comp_df$average), ]
  cat("Top 10 compounds by average contribution:\n")
  print(head(result_sorted, 10))
}

# ================================
# 10. Identify Unique Candidate Compounds per Group (Optional)
# ================================
# The following code uses an intersection approach: for each taxonomic group, we select
# the top contributors (here we use top 100 to be lenient) in all pairwise comparisons
# involving that group, and then compute the intersection.

groups <- c("Plants", "Fungi", "Bacteria", "Algae")
unique_compounds <- list()

for (g in groups) {
  # Identify comparisons that include the current group.
  comp_names <- names(simper_results)[grepl(g, names(simper_results))]
  
  # For each comparison, extract the top 100 compounds by average contribution.
  top_list <- lapply(comp_names, function(comp) {
    result_comp <- simper_results[[comp]]
    sorted_compounds <- names(sort(result_comp$average, decreasing = TRUE))
    top100 <- head(sorted_compounds, 100)
    return(top100)
  })
  
  # Find the intersection of the top lists for comparisons involving group g.
  if (length(top_list) > 0) {
    common <- Reduce(intersect, top_list)
  } else {
    common <- character(0)
  }
  
  unique_compounds[[g]] <- common
}

cat("\nUnique candidate compounds for each taxonomic group:\n")
print(unique_compounds)
