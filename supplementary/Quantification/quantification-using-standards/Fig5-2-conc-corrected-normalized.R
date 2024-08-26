library(dplyr)
library(readxl)
library(writexl)
library(openxlsx)
library(tidyverse)
library(pheatmap)
library(viridis)
library(ggplot2)
library(scales)

# Load the Excel file
file_path <- "ESTD-ALL-POS-NEG-CAL.xlsx"
df_std_cal <- read_excel(file_path, sheet = "Sheet1")

calculate_calibration_parameters <- function(row) {
  concentrations <- c(0)
  areas <- c(0)
  
  initial_concentration <- row[["Initial concentration"]]
  injection_columns <- c(names(row)[grep("^0_0", names(row))], 
                         unlist(lapply(1:7, function(i) paste0(i, "_", c(5, 1)))))
  
  for (col in injection_columns) {
    if (grepl("^0_0", col) || !is.na(row[[col]])) {
      if (grepl("^0_0", col)) {
        effective_concentration <- 0
        area <- 0
      } else {
        volume <- as.numeric(unlist(strsplit(col, "_"))[2])
        factor <- 1 / (2 ^ (as.numeric(unlist(strsplit(col, "_"))[1]) - 1))
        concentration <- initial_concentration * factor
        effective_concentration <- concentration * volume
        area <- row[[col]]
      }
      
      concentrations <- c(concentrations, effective_concentration)
      areas <- c(areas, area)
    }
  }
  
  data <- data.frame(concentrations = concentrations, areas = areas)
  model <- lm(areas ~ concentrations, data = data)
  slope <- coef(model)[2]
  intercept <- coef(model)[1]
  r_squared <- summary(model)$r.squared
  non_zero_concentrations <- concentrations[concentrations > 0 & areas > 0]
  LOD <- ifelse(length(non_zero_concentrations) > 0, min(non_zero_concentrations), NA)
  LOQ <- ifelse(!is.na(LOD), min(concentrations[concentrations >= 3 * LOD & areas > 0]), NA)
  if (is.na(LOQ)) {
    LOQ <- max(concentrations)
  }
  
  return(data.frame(
    Slope = slope,
    Intercept = intercept,
    `LOD (ng)` = LOD,
    `LOQ (ng)` = LOQ,
    `R²` = r_squared
  ))
}

calibration_params <- df_std_cal %>% 
  rowwise() %>% 
  do(calculate_calibration_parameters(.))
df_std_cal <- bind_cols(df_std_cal, calibration_params)

output_path <- "Fig5-ALL-updated.xlsx"
write_xlsx(df_std_cal, output_path)

# Load the original file
file_path <- "Fig5-ALL.xlsx"
df_ls_std <- read_excel(file_path, sheet = "LS-SIRIUS-STD")

file_path <- "Fig5-ALL-updated.xlsx"
data <- read_excel(file_path, sheet = "Sheet1")
colnames(data) <- trimws(colnames(data))

df_updated_ls_std_cal <- data %>%
  group_by(`Molecule List`, `Precursor Adduct`) %>%
  filter(R. == max(R.)) %>%
  ungroup()

merged_df <- df_ls_std %>%
  left_join(df_updated_ls_std_cal %>% select(`Molecule List`, `Precursor Adduct`, `Slope`, `Intercept`, `LOD..ng.`, `LOQ..ng.`), 
            by = c("Molecule List", "Precursor Adduct"))

merged_df <- merged_df %>%
  mutate(across(starts_with('Sum Total Area'), as.numeric),
         Slope = as.numeric(Slope),
         Intercept = as.numeric(Intercept))

sum_total_area_cols <- grep("Sum Total Area", names(merged_df), value = TRUE)

merged_df <- merged_df %>%
  mutate(across(all_of(sum_total_area_cols), 
                ~as.numeric(ifelse(.x %in% c("#N/A", "N/A", ""), NA, .x))))

concentration_columns <- sum_total_area_cols

for (col in concentration_columns) {
  concentration_col <- paste0(col, " Concentration")
  merged_df[[concentration_col]] <- (merged_df[[col]] - merged_df[["Intercept"]]) / merged_df[["Slope"]]
  
  above_loq_col <- paste0(concentration_col, " > LOQ")
  merged_df[[above_loq_col]] <- merged_df[[concentration_col]] > merged_df[["LOQ..ng."]]
}

write.xlsx(merged_df, "Fig5-ALL-concentration-updated.xlsx", sheetName = "SIRIUS-STD", rowNames = FALSE)
# Load the weight data
df_lipids <- data.frame(
  Sample = c(19, 22, 36, 28, 44, 49, 35, 40, 52, 27, 43, 48, 50),
  Type1 = c("Ambient", "Ambient", "Ambient", "Ambient", "Ambient", "Ambient", "Future", "Future", "Future", "Future", "Future", "Future", "Future"),
  Type2 = c("No_drought", "No_drought", "No_drought", "Drought", "Drought", "Drought", "No_drought", "No_drought", "No_drought", "Drought", "Drought", "Drought", "Drought"),
  Weight = c(2.054, 1.965, 2.063, 2.048, 2.063, 2.082, 2.065, 2.032, 2.033, 2.071, 2.028, 2.027, 0.178)
)

# Adjust the regular expressions to correctly capture column names.
concentration_cols <- grep(paste(samples, collapse = "|"), grep('Sum Total Area Concentration', colnames(merged_df), value = TRUE), value = TRUE)

# Extract weights for the samples relevant to the concentration columns
sample_weights <- setNames(df_lipids$Weight[df_lipids$Sample %in% as.numeric(samples)], df_lipids$Sample[df_lipids$Sample %in% as.numeric(samples)])

df <- merged_df %>%
  filter(!rowSums(is.na(select(., all_of(columns_containing_loq)))) & # Filter out rows with any NA values in LOQ columns
           !rowSums(select(., all_of(columns_containing_loq)) == 0)) %>%  # Filter out rows where LOQ columns are zero
  select(-all_of(columns_containing_loq)) %>%
  select(`Molecule List`, LipidMolecule, any_of(concentration_cols))

df <- df %>%
  group_by(`Molecule List`) %>%
  summarize(across(any_of(concentration_cols), sum, na.rm = TRUE))

# Exclude columns with "> LOQ" for normalization calculation
concentration_cols <- concentration_cols[!grepl("> LOQ", concentration_cols)]
print("Refined Concentration Columns:")
print(concentration_cols)

# Ensure column names in df and keys in sample_weights align properly
df <- df %>% rowwise() %>%
  mutate(
    across(any_of(concentration_cols), ~ . / sample_weights[as.character(sub(".*_", "", cur_column()))]),
    mean_concentration = mean(c_across(any_of(concentration_cols)), na.rm = TRUE),
    std_concentration = sd(c_across(any_of(concentration_cols)), na.rm = TRUE)
  ) %>%
  ungroup()
  
df <- merged_df %>%
  select(`Molecule List`, LipidMolecule, all_of(concentration_cols)) %>%
  group_by(`Molecule List`) %>%
  summarize(across(all_of(concentration_cols), sum, na.rm = TRUE)) %>%
  rowwise() %>%
  mutate(
    # Normalize each concentration by its corresponding weight
    across(all_of(concentration_cols), ~ . / sample_weights[which(samples == as.numeric(sub(".*_", "", cur_column())))]),
    mean_concentration = mean(c_across(all_of(concentration_cols)), na.rm = TRUE),
    std_concentration = sd(c_across(all_of(concentration_cols)), na.rm = TRUE)
  ) %>%
  ungroup()



process_molecule_list <- function(molecule_lists) {
  # Load the weight data
  df_lipids <- data.frame(
    Sample = c(19, 22, 36, 28, 44, 49, 35, 40, 52, 27, 43, 48, 50),
    Type1 = c("Ambient", "Ambient", "Ambient", "Ambient", "Ambient", "Ambient", "Future", "Future", "Future", "Future", "Future", "Future", "Future"),
    Type2 = c("No_drought", "No_drought", "No_drought", "Drought", "Drought", "Drought", "No_drought", "No_drought", "No_drought", "Drought", "Drought", "Drought", "Drought"),
    Weight = c(2.054, 1.965, 2.063, 2.048, 2.063, 2.082, 2.065, 2.032, 2.033, 2.071, 2.028, 2.027, 0.178)
  )
  
  # Function to create a summarized dataframe for a specific treatment
  create_summary_df <- function(samples, treatment_name) {
    concentration_cols <- grep(paste(samples, collapse = "|"), grep('Sum Total Area Concentration', colnames(merged_df), value = TRUE), value = TRUE)
    
    # Get weights for the samples
    sample_weights <- df_lipids$Weight[df_lipids$Sample %in% samples]
    
    df <- merged_df %>%
      select(`Molecule List`, LipidMolecule, all_of(concentration_cols)) %>%
      group_by(`Molecule List`) %>%
      summarize(across(all_of(concentration_cols), sum, na.rm = TRUE)) %>%
      rowwise() %>%
      mutate(
        # Normalize each concentration by its corresponding weight
        across(all_of(concentration_cols), ~ . / sample_weights[which(samples == as.numeric(sub(".*_", "", cur_column())))]),
        mean_concentration = mean(c_across(all_of(concentration_cols)), na.rm = TRUE),
        std_concentration = sd(c_across(all_of(concentration_cols)), na.rm = TRUE)
      ) %>%
      ungroup()
    
    df$TreatmentType <- treatment_name
    return(df)
  }
  
  # Create summarized dataframes for each treatment
  ambient_no_drought_df <- create_summary_df(c('19', '22', '36'), 'Ambient_No_drought')
  future_no_drought_df <- create_summary_df(c('35', '40', '52'), 'Future_No_drought')
  ambient_drought_df <- create_summary_df(c('28', '44', '49'), 'Ambient_Drought')
  future_drought_df <- create_summary_df(c('27', '43', '48'), 'Future_Drought')
  
  # Combine all the summarized dataframes
  combined_df <- bind_rows(ambient_no_drought_df, future_no_drought_df, ambient_drought_df, future_drought_df)
  
  # Remove rows with NA mean_concentration
  combined_df <- combined_df %>% filter(!is.na(mean_concentration))
  
  # Check if there's any data left to plot
  if(nrow(combined_df) == 0) {
    warning("No valid data for any molecule list")
    return(NULL)
  }
  
  # Calculate total concentration for each Molecule List
  total_conc <- combined_df %>%
    group_by(`Molecule List`) %>%
    summarize(total_conc = sum(mean_concentration, na.rm = TRUE)) %>%
    arrange(desc(total_conc))
  
  # Order the Molecule List factor levels based on total concentration
  combined_df$`Molecule List` <- factor(combined_df$`Molecule List`, levels = total_conc$`Molecule List`)
  
  # Create the plot
  p <- ggplot(combined_df, aes(x = TreatmentType, y = mean_concentration, fill = TreatmentType)) +
    geom_bar(stat = 'identity', position = position_dodge(), width = 0.7) +
    geom_errorbar(aes(ymin = pmax(mean_concentration - std_concentration, 0), 
                      ymax = mean_concentration + std_concentration), 
                  position = position_dodge(0.7), width = 0.25) +
    facet_wrap(~ `Molecule List`, scales = "free_y", ncol = 3) +
    scale_fill_brewer(palette = "Set2") +
    labs(title = 'Normalized Lipid Concentration Across Treatments for Each Molecule List',
         x = 'Treatment Type',
         y = 'Normalized Concentration (per gram of sample)') +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "top",
      strip.background = element_rect(fill = "lightgrey"),
      strip.text = element_text(face = "bold"),
      plot.title = element_text(hjust = 0.5, face = "bold")
    )
  
  # Save the plot
  ggsave("all_molecule_lists_comparison_ordered_normalized.pdf", plot = p, width = 15, height = 12)
  
  # Return the combined dataframe
  return(combined_df)
}















#####################################################################Lipid Classes Figure
process_molecule_list <- function(molecule_lists) {
  # Function to create a summarized dataframe for a specific treatment
  create_summary_df <- function(samples, treatment_name) {
    concentration_cols <- grep(paste(samples, collapse = "|"), grep('Sum Total Area Concentration', colnames(merged_df), value = TRUE), value = TRUE)
    
    df <- merged_df %>% 
      select(`Molecule List`, LipidMolecule, all_of(concentration_cols)) %>%
      group_by(`Molecule List`) %>%
      summarize(across(all_of(concentration_cols), sum, na.rm = TRUE)) %>%
      rowwise() %>%
      mutate(mean_concentration = mean(c_across(all_of(concentration_cols)), na.rm = TRUE),
             std_concentration = sd(c_across(all_of(concentration_cols)), na.rm = TRUE)) %>%
      ungroup()
    
    df$TreatmentType <- treatment_name
    return(df)
  }
  
  # Create summarized dataframes for each treatment
  ambient_no_drought_df <- create_summary_df(c('19', '22', '36'), 'Ambient_No_drought')
  future_no_drought_df <- create_summary_df(c('35', '40', '52'), 'Future_No_drought')
  ambient_drought_df <- create_summary_df(c('28', '44', '49'), 'Ambient_Drought')
  future_drought_df <- create_summary_df(c('27', '43', '48'), 'Future_Drought')
  
  # Combine all the summarized dataframes
  combined_df <- bind_rows(ambient_no_drought_df, future_no_drought_df, ambient_drought_df, future_drought_df)
  
  # Remove rows with NA mean_concentration
  combined_df <- combined_df %>% filter(!is.na(mean_concentration))
  
  # Check if there's any data left to plot
  if(nrow(combined_df) == 0) {
    warning("No valid data for any molecule list")
    return(NULL)
  }
  
  # Calculate total concentration for each Molecule List
  total_conc <- combined_df %>%
    group_by(`Molecule List`) %>%
    summarize(total_conc = sum(mean_concentration, na.rm = TRUE)) %>%
    arrange(desc(total_conc))
  
  # Order the Molecule List factor levels based on total concentration
  combined_df$`Molecule List` <- factor(combined_df$`Molecule List`, 
                                        levels = total_conc$`Molecule List`)
  
  # Create the plot
  p <- ggplot(combined_df, aes(x = TreatmentType, y = mean_concentration, fill = TreatmentType)) +
    geom_bar(stat = 'identity', position = position_dodge(), width = 0.7) +
    geom_errorbar(aes(ymin = pmax(mean_concentration - std_concentration, 0), 
                      ymax = mean_concentration + std_concentration),
                  position = position_dodge(0.7), width = 0.25) +
    facet_wrap(~ `Molecule List`, scales = "free_y", ncol = 3) +
    scale_fill_brewer(palette = "Set2") +
    labs(title = 'Total Lipid Concentration Across Treatments for Each Molecule List',
         x = 'Treatment Type', 
         y = 'Total Concentration') +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "top",
      strip.background = element_rect(fill = "lightgrey"),
      strip.text = element_text(face = "bold"),
      plot.title = element_text(hjust = 0.5, face = "bold")
    )
  
  # Save the plot
  ggsave("all_molecule_lists_comparison_ordered.pdf", plot = p, width = 15, height = 12)
  
  # Return the combined dataframe
  return(combined_df)
}

# Get all unique Molecule List values
molecule_lists <- unique(merged_df$`Molecule List`)

# Process all Molecule Lists
results <- process_molecule_list(molecule_lists)

###################################################################################################################################

# Sample to Treatment mapping
sample_treatment_mapping <- tibble(
  Sample = c(19, 22, 36, 28, 44, 49, 35, 40, 52, 27, 43, 48, 50),
  Treatment = c(rep('AmbientNo_drought', 3), 
                rep('AmbientDrought', 3), 
                rep('FutureNo_drought', 3), 
                rep('FutureDrought', 3),
                'FutureDrought')
)

# Assuming the data is loaded into a data frame called lipid_data
df_lipids <- data.frame(
  Sample = c(19, 22, 36, 28, 44, 49, 35, 40, 52, 27, 43, 48, 50),
  Type1 = c("Ambient", "Ambient", "Ambient", "Ambient", "Ambient", "Ambient", "Future", "Future", "Future", "Future", "Future", "Future", "Future"),
  Type2 = c("No_drought", "No_drought", "No_drought", "Drought", "Drought", "Drought", "No_drought", "No_drought", "No_drought", "Drought", "Drought", "Drought", "Drought"),
  Weight = c(2.054, 1.965, 2.063, 2.048, 2.063, 2.082, 2.065, 2.032, 2.033, 2.071, 2.028, 2.027, 0.178)
)

# Load the lipid concentration data and merge with lipid_data
# lipid_concentration_data <- ...

# Normalize the lipid concentration by dry weight
df_lipids <- df_lipids %>%
  mutate(Normalized_Concentration = ((Concentration*100) / Weight))


# Prepare data for heatmap and bar plot
heatmap_and_barplot_data <- merged_df %>%
  select(`Molecule List`, ends_with("Concentration"), ends_with("> LOQ")) %>%
  pivot_longer(cols = -`Molecule List`, 
               names_to = c("Sample", "Measure"), 
               names_pattern = "(\\d+) Sum Total Area (Concentration|Concentration > LOQ)",
               values_to = "Value") %>%
  mutate(Sample = as.numeric(Sample)) %>%
  group_by(`Molecule List`, Sample, Measure) %>%
  summarise(Value = mean(Value, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = Measure, values_from = Value) %>%
  left_join(sample_treatment_mapping, by = "Sample") %>%
  filter(Concentration > 0) %>%
  group_by(`Molecule List`, Treatment) %>%
  summarise(Summed_Concentration = sum(Concentration, na.rm = TRUE), .groups = "drop") %>%
  ungroup()

detailed_lipid_data <- merged_df %>%
  select(`Molecule List`, `LipidMolecule`, ends_with("Concentration"), -ends_with("> LOQ")) %>%
  pivot_longer(cols = -c(`Molecule List`, `LipidMolecule`), 
               names_to = "Sample", 
               values_to = "Concentration",
               names_pattern = "(\\d+) Sum Total Area Concentration") %>%
  mutate(Sample = as.numeric(Sample)) %>%
  left_join(sample_treatment_mapping, by = "Sample") %>%
  filter(Concentration > 0)

# If you want to save this data to a file, you can use:
write.csv(detailed_lipid_data, "detailed_lipid_data-sph.csv", row.names = FALSE)


# Heatmap creation
heatmap_data <- heatmap_and_barplot_data %>%
  pivot_wider(names_from = Treatment, values_from = Summed_Concentration) %>%
  mutate(Total = rowSums(select(., -`Molecule List`), na.rm = TRUE)) %>%
  arrange(desc(Total))

heatmap_matrix <- as.matrix(heatmap_data %>% select(-`Molecule List`, -Total))
rownames(heatmap_matrix) <- heatmap_data$`Molecule List`

pheatmap(heatmap_matrix, 
         scale = "row",
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         main = "Summed Concentrations by Lipid Class and Treatment (Normalized)",
         fontsize_row = 10,
         angle_col = 45,
         color = viridis(100),
         show_rownames = TRUE,
         cellwidth = 15,
         cellheight = 15)

ggsave("lipid_class_heatmap_normalized.png", width = 10, height = 12)

# Top N lipid classes
n_top_classes <- 10
top_classes <- heatmap_data %>% head(n_top_classes)

top_matrix <- as.matrix(top_classes %>% select(-`Molecule List`, -Total))
rownames(top_matrix) <- top_classes$`Molecule List`

pheatmap(top_matrix, 
         scale = "row",
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         main = paste("Top", n_top_classes, "Most Abundant Lipid Classes (Normalized)"),
         fontsize_row = 12,
         angle_col = 45,
         color = viridis(100),
         show_rownames = TRUE,
         cellwidth = 20,
         cellheight = 20)

ggsave("top_lipid_classes_heatmap_normalized.png", width = 10, height = 8)

# Bar plot creation
molecule_order <- heatmap_and_barplot_data %>%
  group_by(`Molecule List`) %>%
  summarise(Total_Concentration = sum(Summed_Concentration, na.rm = TRUE)) %>%
  arrange(desc(Total_Concentration)) %>%
  pull(`Molecule List`)

p1 <- ggplot(heatmap_and_barplot_data, aes(x = factor(`Molecule List`, levels = molecule_order), 
                                           y = Summed_Concentration, 
                                           fill = Treatment)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
        legend.position = "top",
        plot.title = element_text(hjust = 0.5)) +
  labs(title = "Summed Concentrations for Each Lipid Class and Treatment (Normalized)", 
       x = "Lipid Class", 
       y = "Summed Concentrations (log scale)") +
  scale_fill_brewer(palette = "Set2") +
  scale_y_log10(labels = scales::scientific) +
  coord_flip()

ggsave("lipid_class_barplot_log_normalized.pdf", plot = p1, width = 12, height = 20)

p2 <- ggplot(heatmap_and_barplot_data %>% filter(`Molecule List` %in% molecule_order), 
             aes(x = factor(`Molecule List`, levels = molecule_order), 
                 y = Summed_Concentration, 
                 fill = Treatment)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
        legend.position = "top",
        plot.title = element_text(hjust = 0.5)) +
  labs(title = paste("Top", n_top_classes, "Most Abundant Lipid Classes (Normalized)"), 
       x = "Lipid Class", 
       y = "Summed Concentrations (square root scale)") +
  scale_fill_brewer(palette = "Set2") +
  scale_y_sqrt(labels = scales::scientific) +
  coord_flip()

ggsave("top_lipid_classes_barplot_sqrt_normalized.pdf", plot = p2, width = 12, height = 10)
