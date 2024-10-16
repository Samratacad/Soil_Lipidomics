# Required libraries
library(ggplot2)
library(readxl)
library(scales)
library(grid)
library(dplyr)

# Function to calculate calibration parameters, LOD, and LOQ
calculate_calibration_parameters <- function(row, injection_columns, blk_columns) {
  concentrations <- c()
  areas <- c()
  point_type <- c()  # To store the point type (Standard)
  
  initial_concentration <- row[["Initial concentration"]]
  
  for (col in injection_columns) {
    if (!is.na(row[[col]])) {
      if (grepl("^0_0", col)) {
        effective_concentration <- 0
      } else {
        volume <- as.numeric(unlist(strsplit(col, "_"))[2])
        factor <- 1 / (2 ^ (as.numeric(unlist(strsplit(col, "_"))[1]) - 1))
        concentration <- initial_concentration * factor
        effective_concentration <- concentration * volume
      }
      area <- row[[col]]
      concentrations <- c(concentrations, effective_concentration)
      areas <- c(areas, area)
      point_type <- c(point_type, "Standard")
    }
  }
  
  data <- data.frame(concentrations = concentrations, areas = areas, point_type = point_type)
  
  # Filter non-zero concentrations and areas for linear regression
  data <- data %>%
    filter(concentrations > 0, areas > 0)
  
  if (nrow(data) >= 2) {
    # Perform linear regression on the original scale (no log10 transformation)
    model <- lm(areas ~ concentrations, data = data)
    slope <- coef(model)[2]
    intercept <- coef(model)[1]
    r_squared <- summary(model)$r.squared
  } else {
    return(NULL)  # Skip if not enough points for a valid regression
  }
  
  # Calculate LOD and LOQ based on blank areas or lowest concentrations
  blk_areas <- row[blk_columns] %>% as.numeric() %>% na.omit()
  
  if (length(blk_areas) > 0 && any(blk_areas > 0)) {
    blk_std <- sd(blk_areas)
    lod_area <- 3 * blk_std
    loq_area <- 10 * blk_std
  } else {
    lowest_three_areas <- sort(data$areas)[1:3]
    if (length(lowest_three_areas) >= 3) {
      areas_std <- sd(lowest_three_areas)
      lod_area <- 3 * areas_std
      loq_area <- 10 * areas_std
    } else {
      lod_area <- NA
      loq_area <- NA
    }
  }
  
  # Find LOD and LOQ based on concentration
  lod_concentration <- min(data$concentrations[data$areas >= lod_area], na.rm = TRUE)
  loq_concentration <- min(data$concentrations[data$areas >= loq_area], na.rm = TRUE)
  
  # Adjust LOQ if it's the same as LOD (set LOQ to 10 times the LOD)
  if (!is.na(lod_concentration) && (is.na(loq_concentration) || lod_concentration == loq_concentration)) {
    loq_concentration <- lod_concentration * 10
  }
  
  return(list(
    slope = slope,
    intercept = intercept,
    r_squared = r_squared,
    lod_concentration = lod_concentration,
    loq_concentration = loq_concentration,
    data = data
  ))
}

# Load your data from Excel
data <- read_excel("ESTD-COMB.xlsx", sheet = "Sheet2")

# Define injection and blank columns (modify according to your dataset structure)
injection_columns <- grep("^[0-9]_[0-9]", colnames(data), value = TRUE)
blk_columns <- grep("^BLK", colnames(data), value = TRUE)

# Create a list to store the results and plots
results <- list()
plot_list <- list()

# Loop through the data to calculate parameters and create plots
for (i in 1:nrow(data)) {
  row <- data[i, ]
  result <- calculate_calibration_parameters(row, injection_columns, blk_columns)
  
  if (!is.null(result)) {
    # Filter out results where R² is less than 0.95
    if (result$r_squared >= 0.95) {
      molecule <- row[["Molecule"]]
      
      # Store the results
      results[[i]] <- data.frame(
        Molecule = molecule,
        Precursor_Adduct = row[["Precursor Adduct"]],
        Retention_Time = row[["Mean Best Retention Time"]],
        Retention_Time_Std_Dev = row[["Stdev Best Retention Time"]],
        Molecule_List = row[["Molecule List"]],
        Slope = result$slope,
        Intercept = result$intercept,
        R_squared = result$r_squared,
        LOD = result$lod_concentration,
        LOQ = result$loq_concentration
      )
      
      # Create the plot (plot on log scale but fit on original scale)
      plot_data <- result$data
      p <- ggplot(plot_data, aes(x = concentrations, y = areas, color = point_type, shape = point_type)) +
        geom_point(size = 3) +
        geom_smooth(data = plot_data[plot_data$point_type == "Standard", ], 
                    aes(x = concentrations, y = areas), method = "lm", se = FALSE, color = "red") +
        scale_x_log10() +
        scale_y_log10() +  # Plot on log scale
        labs(
          title = paste("Calibration Curve of", molecule),
          x = "Concentration (log scale)",
          y = "Area (log scale)"
        ) +
        scale_color_manual(values = c("Standard" = "black")) +
        scale_shape_manual(values = c("Standard" = 19)) +
        geom_vline(xintercept = result$lod_concentration, color = "red", linetype = "dashed", size = 1) +
        geom_vline(xintercept = result$loq_concentration, color = "blue", linetype = "dashed", size = 1) +
        annotate("text", x = Inf, y = Inf, label = paste0(
          "Slope: ", round(result$slope, 2), "\n",
          "Intercept: ", round(result$intercept, 2), "\n",
          "R²: ", round(result$r_squared, 4), "\n",
          "LOD: ", round(result$lod_concentration, 3), "\n",
          "LOQ: ", round(result$loq_concentration, 3), "\n",
          "Adduct: ", row[["Precursor Adduct"]]
        ), hjust = 1.1, vjust = 2, size = 3)
      
      plot_list[[i]] <- p
    }
  }
}

# Combine all results into a single dataframe
results_df <- do.call(rbind, results)

# Save all plots to a single PDF file
pdf("calibration_curves_with_lod_loq_adjusted_logscale.pdf", width = 8, height = 6)
for (p in plot_list) {
  print(p)
}
dev.off()

# Save the results as a CSV file with the requested columns
write.csv(results_df, "calibration_results_filtered.csv", row.names = FALSE)

# --- Step 2: Generate the best adducts CSV based on the highest R² ---
best_adducts_df <- results_df %>%
  group_by(Molecule) %>%
  filter(R_squared == max(R_squared)) %>%
  ungroup()

# Save the best adducts as a CSV file
write.csv(best_adducts_df, "best_adducts_per_molecule.csv", row.names = FALSE)

# --- Step 3: Generate the best R² for each Molecule List ---
best_r2_molecule_list_df <- results_df %>%
  group_by(Molecule_List) %>%
  filter(R_squared == max(R_squared)) %>%
  ungroup()

# Save the best R² for each Molecule List as a CSV file
write.csv(best_r2_molecule_list_df, "best_r2_per_molecule_list.csv", row.names = FALSE)

# First, check column names to make sure we are using the correct names
print(colnames(data))  # This will print all the column names to verify the correct column names

# Ensure Molecule List and Molecule column names exist
molecule_colname <- "Molecule"  # Adjust this if necessary based on actual column name
molecule_list_colname <- "Molecule List"  # Adjust this if necessary

if (!(molecule_colname %in% colnames(data)) || !(molecule_list_colname %in% colnames(data))) {
  stop("Column names for Molecule or Molecule List are incorrect or missing.")
}

# --- Step 4: Generate a PDF plot for the best compound for each Molecule List ---
pdf("best_compound_per_molecule_list_plots.pdf", width = 8, height = 6)

for (i in 1:nrow(best_r2_molecule_list_df)) {
  row <- best_r2_molecule_list_df[i, ]
  
  # Convert to lowercase and trim spaces to avoid matching issues
  row_molecule <- tolower(trimws(row[[molecule_colname]]))
  row_molecule_list <- tolower(trimws(row[[molecule_list_colname]]))
  
  # Check if Molecule List is missing or empty, and skip if so
  if (is.na(row_molecule_list) || row_molecule_list == "") {
    cat("Warning: Skipping Molecule due to missing or empty Molecule List:", row_molecule, "\n")
    next
  }
  
  # Debugging: Print the row variables to ensure they contain valid data
  print(paste("Processing Molecule:", row_molecule, "and Molecule List:", row_molecule_list))
  
  # Extract concentrations and areas for the corresponding molecule and molecule list
  matching_data <- data %>%
    filter(
      tolower(trimws(data[[molecule_colname]])) == row_molecule &
        tolower(trimws(data[[molecule_list_colname]])) == row_molecule_list
    )
  
  # If no data is found, print a warning and skip to the next iteration
  if (nrow(matching_data) == 0) {
    cat("Warning: No matching data found for Molecule:", row[[molecule_colname]], "and Molecule List:", row[[molecule_list_colname]], "\n")
    next
  }
  
  # Filter out rows with NaN values in the concentration columns
  plot_data <- matching_data[injection_columns] %>% 
    select_if(~!all(is.na(.))) %>%
    na.omit()  # Remove rows with NaN values
  
  if (nrow(plot_data) == 0) {
    cat("Warning: No valid data for plotting after filtering NaN values for Molecule:", row[[molecule_colname]], "\n")
    next
  }
  
  # Convert plot data to numeric vectors
  plot_data <- data.frame(
    concentrations = as.numeric(unlist(plot_data[injection_columns])),
    areas = as.numeric(unlist(plot_data[injection_columns]))
  )
  
  # Create the plot for the best compound
  p <- ggplot(plot_data, aes(x = concentrations, y = areas)) +
    geom_point(size = 3) +
    geom_smooth(method = "lm", se = FALSE, color = "red") +
    scale_x_log10() +
    scale_y_log10() +  # Plot on log scale
    labs(
      title = paste("Best Compound for Molecule List:", row[[molecule_list_colname]]),
      x = "Concentration (log scale)",
      y = "Area (log scale)"
    ) +
    geom_vline(xintercept = row[["LOD"]], color = "red", linetype = "dashed", size = 1) +
    geom_vline(xintercept = row[["LOQ"]], color = "blue", linetype = "dashed", size = 1) +
    annotate("text", x = Inf, y = Inf, label = paste0(
      "Slope: ", round(row[["Slope"]], 2), "\n",
      "Intercept: ", round(row[["Intercept"]], 2), "\n",
      "R²: ", round(row[["R_squared"]], 4), "\n",
      "LOD: ", round(row[["LOD"]], 3), "\n",
      "LOQ: ", round(row[["LOQ"]], 3), "\n",
      "Adduct: ", row[["Precursor_Adduct"]]
    ), hjust = 1.1, vjust = 2, size = 3)
  
  # Print the plot to the PDF
  print(p)
}
dev.off()

# Print a message indicating successful completion
cat("Plots for the best compound for each Molecule List have been successfully generated in best_compound_per_molecule_list_plots.pdf.")
