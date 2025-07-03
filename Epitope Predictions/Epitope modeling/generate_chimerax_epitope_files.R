# Load required libraries
library(readr)
library(dplyr)
library(stringr)

# Load ElliPro prediction data
cont <- read_csv("ElliPro Continuous Prediction results.csv")
disc <- read_csv("ElliPro Discontinuous Prediction results.csv")

# Define consistent color set for top 5 epitopes
epitope_colors <- c("red", "blue", "green", "orange", "purple")

# Header lines for ChimeraX setup
header_lines <- c(
  "set bgColor white",
  "lighting soft",
  "color gray cartoon",
  "hide",
  "show cartoon"
)

### ---- CONTINUOUS EPITOPES ---- ###
# Top 5
continuous_epitopes <- cont %>%
  slice(1:5) %>%
  mutate(Epitope_ID = 1:5)

# Build ChimeraX commands
continuous_lines <- list()

# Add header
continuous_lines <- c(continuous_lines, header_lines)

# Loop to create commands for each epitope
for (i in 1:nrow(continuous_epitopes)) {
  ep <- continuous_epitopes[i, ]
  res_indices <- seq(ep$Start, ep$End)
  selection <- paste0(ep$Chain, ":", res_indices, collapse = ",")
  ep_id <- ep$Epitope_ID
  color <- epitope_colors[ep_id]
  
  continuous_lines <- append(continuous_lines, list(
    paste0("name continuous_epitope_",ep_id," @", selection),
    paste0("color ","continuous_epitope_",ep_id," ", color)
  ))
}

# Save to file
writeLines(unlist(continuous_lines), "continuous_epitopes.cxc")



### ---- DISCONTINUOUS EPITOPES ---- ###
# Top 5
discontinuous_epitopes <- disc %>%
  slice(1:5) %>%
  mutate(Epitope_ID = 1:5)

# Build ChimeraX commands
discontinuous_lines <- list()

# Add header
discontinuous_lines <- c(discontinuous_lines, header_lines)

# Loop to create commands for each epitope
for (i in 1:nrow(discontinuous_epitopes)) {
  ep <- discontinuous_epitopes[i, ]
  clean_res <- gsub("\\s", "", ep$Residues)
  res_list <- unlist(strsplit(clean_res, ","))
  
  # Strip residue names (e.g., convert X:G18 -> X:18)
  res_list_cleaned <- gsub("([A-Z]):[A-Z]+(\\d+)", "\\1:\\2", res_list)
  
  selection <- paste(res_list_cleaned, collapse = ",")
  ep_id <- ep$Epitope_ID
  color <- epitope_colors[ep_id]
  
  discontinuous_lines <- append(discontinuous_lines, list(
    paste0("name discontinuous_epitope_", ep_id, " @", selection),
    paste0("color discontinuous_epitope_", ep_id, " ", color)
  ))
}

# Save to file
writeLines(unlist(discontinuous_lines), "discontinuous_epitopes.cxc")





