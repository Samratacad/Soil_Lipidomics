library(dplyr)
library(vegan)
library(ggplot2)
library(ggrepel)
library(svglite)

# Step 1: Load and Clean Data
data <- read.csv("Specieslist-pos.csv")
# Clean column names: replace any non-alphanumeric and non-underscore with an underscore
colnames(data) <- gsub("[^[:alnum:]_]", "_", colnames(data))

# Step 2: Create biomass_data and clean its Species names the same way
biomass_data <- data.frame(
  Species = c(
    "Allium_Ursinum_OE11-E4-P14POS Sum Total Area",    # Absent (P14)
    "Auricularia_Polytricha_OE21-4-F7POS Sum Total Area",  # Common
    "Trichomonascus_vanleenenianus_OE21-4-E8F45POS Sum Total Area",  # Common
    "Craterellus_Cornucopioides_OE21-4-F12POS Sum Total Area",     # Common
    "Equisetum_Arvense_OE11-E4-P11POS Sum Total Area",   # Absent (P11)
    "Ginkgo_biloba_OE11-3-E4-P27POS Sum Total Area",      # Absent (P27)
    "Labilithrix_luteola_1B3R5D0E2 Sum Total Area",      # Absent (1B3)
    "Paenibacillus_Alginolyticus_2B2R5DOE2 Sum Total Area", # Absent (2B2)
    "Rhodococcus_Sp_OE11-3-E4-A1POS Sum Total Area",     # Absent (E4-A1)
    "Thalassiosira_weissflogii_P42POS Sum Total Area",    # Common
    "Ulva_P56POS_20240924144544 Sum Total Area",         # Common
    "Valonia_P52POS_20240924210008 Sum Total Area"         # Common
  ),
  Biomass = c(
    21.02,  # Allium_Ursinum (P14)
    36.08,  # Auricularia_Polytricha (common)
    30.11,  # Trichomonascus_vanleenenianus (common)
    29.73,  # Craterellus_Cornucopioides (common)
    17.31,  # Equisetum_Arvense (P11)
    13.71,  # Ginko_biloba (P27)
    17.06,  # Labilithrix_luteola (1B3)
    4.48,   # Paenibacillus_Alginolyticus (2B2)
    1.10,   # Rhodococcus_Sp (E4-A1)
    12.50,  # Thallasiosira_weissflogii (common)
    27.50,  # Ulva_P56POS (common)
    9.40    # Valonia_P52POS (common)
  )
)

# Clean the Species names in biomass_data so they match the cleaned column names in 'data'
biomass_data$Species <- gsub("[^[:alnum:]_]", "_", biomass_data$Species)

# Step 3: Select and Prepare Sample Data
# Get column names that include "Sum_Total_Area" (after cleaning, the pattern is the same)
sample_columns <- grep("Sum_Total_Area", colnames(data), value = TRUE)

# Convert selected columns to numeric (warning messages may appear if coercion introduces NAs)
sample_data <- data %>% 
  select(all_of(sample_columns)) %>% 
  mutate(across(everything(), as.numeric))

# Step 4: Normalize Each Sample by Its Biomass
for (sample in sample_columns) {
  # Find the biomass value that matches the cleaned sample name
  biomass_value <- biomass_data %>% 
    filter(Species == sample) %>% 
    pull(Biomass)
  
  if (length(biomass_value) == 0) {
    warning(paste("Biomass value not found for sample:", sample))
  } else {
    sample_data[[sample]] <- sample_data[[sample]] / biomass_value
  }
}


# Step 5: Replace NA values with 1/5 of the minimum non-NA value or a small constant if all are NA
sample_data <- as.data.frame(t(apply(sample_data, 1, function(row) {
  if (all(is.na(row))) {
    row[is.na(row)] <- 1e-6
  } else {
    min_value <- min(row, na.rm = TRUE)
    row[is.na(row)] <- min_value / 5
  }
  return(row)
})))

# Step 6: Log Transformation without Autoscaling

transformed_data <- log10(sample_data + 1e-6)
min_val <- min(transformed_data, na.rm = TRUE)
if (min_val < 0) {
  transformed_data <- transformed_data + abs(min_val)
}

# Step 7: Transpose Data for NMDS and Convert Back to Data Frame
sample_names <- colnames(transformed_data)  # Save original sample names
transformed_data <- as.data.frame(t(transformed_data))  # Transpose and convert back to data frame
rownames(transformed_data) <- sample_names  # Assign sample names as row names

# Step 8: Define Sample Groups
sample_groups <- data.frame(Sample = sample_names)
sample_groups$Group <- case_when(
  grepl("Labilithrix|Paenibacillus|Rhodococcus", sample_names) ~ "Bacteria",
  grepl("Auricularia|Trichomonascus|Craterellus", sample_names) ~ "Fungi",
  grepl("Allium|Equisetum|Ginkgo", sample_names) ~ "Plants",
  grepl("Thalassiosira|Ulva|Valonia", sample_names) ~ "Algae",
  TRUE ~ "Unknown"
)





# Step 9: Calculate Bray-Curtis Distance Matrix and Perform NMDS
distance_matrix <- vegdist(transformed_data, method = "bray")
nmds_result <- metaMDS(distance_matrix, k = 2, trymax = 50, trace = TRUE)



# Step 10: Prepare Data for Plotting
nmds_points <- as.data.frame(nmds_result$points)
nmds_points$Sample <- rownames(nmds_points)  # Convert row names to a Sample column

# Join with sample_groups to add Group information
nmds_points <- left_join(nmds_points, sample_groups, by = "Sample")

# Extract the part of the Sample name before the first underscore
nmds_points$Short_Sample <- sub("^(.*?)_.*", "\\1", nmds_points$Sample)


# Extract and round the stress value
stress_val <- round(nmds_result$stress, 3)

# Define plot with enhanced aesthetics and include the stress value in the subtitle
p <- ggplot(nmds_points, aes(x = MDS1, y = MDS2, color = Group, label = Short_Sample)) +
  geom_point(size = 4) +
  geom_text_repel(max.overlaps = 15, size = 7, fontface = "italic") +  # Avoid overlap, italicize labels
  labs(title = "NMDS Analysis of lipidome by taxonomic Group",
       subtitle = paste("Stress value:", stress_val),
       x = "NMDS Dimension 1", y = "NMDS Dimension 2") +
  scale_color_manual(values = c("Bacteria" = "blue", "Fungi" = "red", "Plants" = "darkgreen", "Algae" = "orange")) +
  theme_minimal(base_size = 18) +  # Increase base font size for better readability
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 16),  # Center and bold the title
    legend.title = element_text(face = "bold"),
    legend.position = "right",  # Position legend on the right
    legend.text = element_text(size = 12),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12)
  )

# Print the plot
print(p)

svglite("NMDS_Publication_Quality-v2.svg", width = 10, height = 8)
print(p)
dev.off()

# Alternatively, save as a high-resolution PDF
pdf("NMDS_Publication_Quality.pdf", width = 10, height = 8)
print(p)
dev.off()
