library(readxl)
library(dplyr)
library(tidyr)
library(writexl)
library(ggplot2)

# Provide the path to your file
file_path <- "Fig5-ALL-concentration-updated-with-FAKey.xlsx"

# Load the sheet
data <- read_excel(file_path, sheet = "Sheet1")

# Sample metadata
sample_data <- data.frame(
  Sample = c(19, 22, 36, 28, 44, 49, 35, 40, 52, 27, 43, 48, 50),
  Type1 = c("Ambient", "Ambient", "Ambient", "Ambient", "Ambient", "Ambient", "Future", "Future", "Future", "Future", "Future", "Future", "Future"),
  Type2 = c("No_drought", "No_drought", "No_drought", "Drought", "Drought", "Drought", "No_drought", "No_drought", "No_drought", "Drought", "Drought", "Drought", "Drought"),
  Weight = c(2.054, 1.965, 2.063, 2.048, 2.063, 2.082, 2.065, 2.032, 2.033, 2.071, 2.028, 2.027, 0.178)
)

# Identify LOD/LOQ columns with "Concentration > LOQ" in their names
lod_loq_cols <- grep("Concentration > LOQ", colnames(data), value = TRUE)

# Filter rows where all LOD/LOQ columns have a value of `1`
filtered_data_loq <- data[apply(data[lod_loq_cols], 1, function(row) all(row == 1)), ]

# Further filter rows where "Molecule List" is "Cer"
filtered_data_cer <- filtered_data_loq[filtered_data_loq$`Molecule List` == "PC", ]

# Reshape FAKey_Part columns into long format
long_data <- filtered_data_cer %>%
  select(GlobalID, starts_with("FAKey_Part"), ends_with("Concentration")) %>%
  pivot_longer(cols = starts_with("FAKey_Part"),
               names_to = "FAKey_Part_Type",
               values_to = "FAKey_Part") %>%
  filter(!is.na(FAKey_Part))  # Remove rows with NA in FAKey_Part

# Reshape concentrations into long format
long_data_with_concentration <- long_data %>%
  pivot_longer(cols = ends_with("Concentration"),
               names_to = "Sample",
               values_to = "Concentration")

# Extract numeric sample IDs from Sample column
long_data_with_concentration <- long_data_with_concentration %>%
  mutate(Sample = as.numeric(gsub(".*?(\\d+).*", "\\1", Sample)))

# Merge with sample metadata
merged_data <- long_data_with_concentration %>%
  inner_join(sample_data, by = "Sample") %>%
  mutate(Treatment = paste(Type1, Type2, sep = "_"))  # Create Treatment column

# Normalize concentrations by weight
normalized_data <- merged_data %>%
  mutate(Normalized_Concentration = Concentration / Weight)


# Prepare the heatmap data (same as before)
heatmap_data <- normalized_data %>%
  group_by(Treatment, FAKey_Part) %>%
  summarize(Total_Concentration = sum(Normalized_Concentration, na.rm = TRUE), .groups = "drop")

# Parse carbon number and double bonds for sorting
heatmap_data <- heatmap_data %>%
  mutate(
    Carbon_Info = gsub("[^0-9:]", "", FAKey_Part),  # Remove non-numeric and non-':' characters
    Carbon_Number = as.numeric(sub(":.*", "", Carbon_Info)),  # Extract carbon number
    Double_Bonds = as.numeric(sub(".*:", "", Carbon_Info))    # Extract double bond count
  )

# Sort by Carbon_Number and Double_Bonds
sorted_fa_parts <- heatmap_data %>%
  distinct(FAKey_Part, Carbon_Number, Double_Bonds) %>%
  arrange(Carbon_Number, Double_Bonds) %>%
  pull(FAKey_Part)

# Ensure the data is in the correct order
heatmap_data <- heatmap_data %>%
  mutate(FAKey_Part = factor(FAKey_Part, levels = sorted_fa_parts))

# Pivot data into wide format for plotting
heatmap_wide <- heatmap_data %>%
  select(FAKey_Part, Treatment, Total_Concentration) %>%
  pivot_wider(names_from = Treatment, values_from = Total_Concentration, values_fill = 0)

# Convert back to long format for ggplot heatmap
heatmap_long <- heatmap_wide %>%
  pivot_longer(cols = -FAKey_Part, names_to = "Treatment", values_to = "Concentration")



# Step 1: Calculate Z-Scores for Each Treatment (Column-Wise)
heatmap_long_scaled <- heatmap_long %>%
  group_by(Treatment) %>%
  mutate(Z_Score = (Concentration - mean(Concentration, na.rm = TRUE)) / sd(Concentration, na.rm = TRUE)) %>%
  ungroup()

# 1. Create a matrix of actual concentrations
concentration_wide <- dcast(
  data       = heatmap_long_scaled,  # Use the same long-format data
  formula    = FAKey_Part ~ Treatment,
  value.var  = "Concentration"  # Use actual concentrations
)

# 2. Set row names and remove FAKey_Part column
rownames(concentration_wide) <- concentration_wide[["FAKey_Part"]]
concentration_wide[["FAKey_Part"]] <- NULL

# 3. Format the actual concentration values (round for better readability)
formatted_concentrations <- round(concentration_wide, 2)  # Adjust decimal places as needed

# 4. Plot with pheatmap using Z-Scores for colors, actual concentrations for numbers
p_column <- pheatmap(
  mat              = as.matrix(heatmap_wide),  # Use Z-scores for coloring
  scale           = "column",
  cellwidth       = 40,      
  cellheight      = 40,      
  color           = colorRampPalette(c("blue", "white", "red"))(50),
  cluster_rows    = FALSE,  
  cluster_cols    = FALSE,  
  main            = "PG",
  display_numbers = formatted_concentrations,  # Show actual concentrations
  fontsize_number = 10  # Adjust font size if needed
)

# install.packages("pheatmap") if you haven't already
library(pheatmap)
library(reshape2)  # or use tidyr for pivoting

# Suppose your data frame is called `heatmap_long_scaled`
# with columns: FAKey_Part, Treatment, and Z_Score.
#  FAKey_Part = factor or character for lipid ID
#  Treatment  = factor or character for your experimental treatments
#  Z_Score    = numeric values to plot in the heatmap

# 1. Convert from long to wide form:
heatmap_wide <- dcast(
  data       = heatmap_long_scaled,
  formula    = FAKey_Part ~ Treatment,  # pivot so that each row = FAKey_Part, columns = Treatment
  value.var  = "Z_Score"
)

# 2. Move FAKey_Part to row names, remove that column
rownames(heatmap_wide) <- heatmap_wide[["FAKey_Part"]]
heatmap_wide[["FAKey_Part"]] <- NULL

# At this point, `heatmap_wide` is a matrix/data.frame of numeric Z_Scores
# with row names = FAKey_Part and column names = Treatments.

# 3. Plot with pheatmap
p_column <- pheatmap(
  mat         = heatmap_wide,
  scale = 'column',
  cellwidth   = 40,      # control the width of each box
  cellheight  = 40,      # control the height of each box
  color       = colorRampPalette(c("blue", "white", "red"))(50),  # similar to scale_fill_gradient2
  cluster_rows = FALSE,  # set to TRUE or FALSE depending on whether you want clustering
  cluster_cols = FALSE,  # likewise
  main = "PG",
  display_numbers = TRUE
)

print(p_column)
ggsave("PG.pdf", p_column, width = 12, height = 14, units = "in")




# Step 2: Plot Heatmap with Uniform Boxes and Adjusted Legend
p_column <- ggplot(heatmap_long_scaled, aes(x = Treatment, y = FAKey_Part)) +
  geom_tile(aes(fill = Z_Score), color = "gray", width = 0.9, height = 0.9) +  # Uniform boxes
  geom_text(aes(label = round(Concentration, 1)), size = 2) +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 1) +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) +
  coord_fixed(ratio=1) +  # Ensures square tiles
  labs(title = "DG Heatmap (Column-Wise Z-Score)", x = "Treatment", y = "Fatty Acid") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size =7),
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 8),
    legend.position = "right"
  ) +
  guides(fill = guide_colourbar(barwidth = 0.5, barheight = 5))  # Small legend

print(p_column)

# Save with fixed dimensions (adjust width/height as needed)
ggsave("DG_heatmap_column_zscore.pdf", p_column, width = 12, height = 8, units = "in")


# Save the plot with fixed dimensions
ggsave("DG.pdf", heatmap_plot, width = 8, height = 8, dpi = 300)















# For row-wise z-score heatmap
p_row <- ggplot(heatmap_long_scaled, aes(x = Treatment, y = FAKey_Part)) +
  geom_tile(aes(fill = Z_Score)) +
  #geom_text(aes(label = round(Concentration, 1)), size = 3) +
  geom_text(aes(label = round(Concentration, 1)), size = 3, check_overlap = TRUE)+
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0) +
  # Make sure there is no extra padding on the axes
  scale_x_discrete(expand = c(0,0)) +
  scale_y_discrete(expand = c(0,0)) +
  coord_equal() +  # Enforces equal width and height for each tile
  labs(title = "PG Heatmap (Row-Wise Z-score)", x = "Treatment", y = "Fatty Acid") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(p_row)
# Save with fixed dimensions
ggsave("PG_heatmap_row_zscore.pdf", p_row, width = 25, height = 10, units = "in")


