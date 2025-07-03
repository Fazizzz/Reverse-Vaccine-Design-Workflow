# Load required libraries
library(ggplot2)
library(dplyr)
library(readr)

# Load the two CSV files (update file paths as needed)
bepipred <- read_csv("Bepipred-2 sequential epitope prediction.csv")
iedb <- read_csv("IEDB Linear B-cell Epitope prediction.csv")

# Rename columns for consistency
bepipred <- bepipred %>% rename(Residue_Bepi2 = AminoAcid)
iedb <- iedb %>% rename(Residue_IEDB = Residue)

# Merge the data by Position
merged <- merge(bepipred, iedb, by = "Position")

# Calculate concordance: TRUE if both tools predict the same residue at same position
merged <- merged %>%
  mutate(Concordant = Residue_Bepi2 == Residue_IEDB)

# Preview merged data
head(merged)

# Optionally write to file
write_csv(merged, "Bepipred_vs_IEDB_Residue_Concordance.csv")

# Define thresholds (customizable)
iedb_thresh <- 0.0        # Typical IEDB score threshold
bepi_thresh <- 0.5        # Common threshold for EpitopeProbability

# Create overlap mask
data <- merged %>%
  mutate(Overlap = ifelse(Score >= iedb_thresh & EpitopeProbability >= bepi_thresh, TRUE, FALSE))

# Plot

fig <- ggplot(data, aes(x = Position)) +
  geom_line(aes(y = Score), color = "#3333FF", size = 1) +
  geom_line(aes(y = EpitopeProbability), color = "black", size = 1) +
  geom_ribbon(data = subset(data, Overlap),
              aes(ymin = pmin(Score, EpitopeProbability),
                  ymax = pmax(Score, EpitopeProbability)),
              fill = "#FFCC00", alpha = 0.3) +
  geom_hline(yintercept = 0, color = "black", linetype = "solid", size = 0.6) +  # solid horizontal line at y = 0
  labs(title = "IEDB Score vs Bepipred2 Epitope Probability",
       x = "Residue Position", y = "Prediction Score",
       caption = "Blue = IEDB Score | Black = Bepipred2 Epitope Probability | Yellow Shading = Overlap") +
  theme_minimal() +
  theme(
    panel.border = element_rect(color = "black", fill = NA, size = 0.8),  # adds black border
    plot.title = element_text(face = "bold"),
    axis.title = element_text(face = "bold")
  )

ggsave("Linear B-cell Epitopes predicted per Residue figure.png",plot = fig,dpi = 600)

###Extract top 5 contiguous Epitopes ------

# Read merged file (replace with your path if needed)
merged_df <- read.csv("Bepipred_vs_IEDB_Residue_Concordance.csv")

# Define thresholds
iedb_thresh <- 0.0
bepi_thresh <- 0.5

# Identify overlapping predictions
merged_df$Overlap <- with(merged_df, Score >= iedb_thresh & EpitopeProbability >= bepi_thresh)

# Extract contiguous regions
get_regions <- function(df) {
  overlap_positions <- which(df$Overlap)
  region_list <- list()
  start_idx <- overlap_positions[1]
  
  for (i in 2:length(overlap_positions)) {
    if (overlap_positions[i] != overlap_positions[i - 1] + 1) {
      end_idx <- overlap_positions[i - 1]
      region_list <- append(region_list, list(c(start_idx, end_idx)))
      start_idx <- overlap_positions[i]
    }
  }
  # Add last region
  region_list <- append(region_list, list(c(start_idx, overlap_positions[length(overlap_positions)])))
  return(region_list)
}

regions <- get_regions(merged_df)

# Create region summaries
region_df <- do.call(rbind, lapply(regions, function(r) {
  region_data <- merged_df[r[1]:r[2], ]
  data.frame(
    Start = region_data$Position[1],
    End = region_data$Position[nrow(region_data)],
    Length = nrow(region_data),
    Sequence = paste(region_data$Residue, collapse = ""),
    Avg_Score = round(mean(c(region_data$Score, region_data$EpitopeProbability)), 3)
  )
}))

# Get top 5
top5_df <- region_df %>% arrange(desc(Avg_Score)) %>% head(5)

# Save as CSV
write.csv(top5_df, "Top_5_Consensus_Epitope_Regions.csv", row.names = FALSE)

### Map top 5 Epitopes to known domains -----

# Define known domain boundaries
assign_domain <- function(start, end) {
  domains <- list(
    "Domain 1" = 1:260,
    "Domain 2" = 261:490,
    "Domain 3" = 491:595,
    "Domain 4" = 596:9999 # allow for long tail
  )
  
  # Count how many residues fall into each domain
  domain_counts <- sapply(domains, function(range) {
    sum(start:end %in% range)
  })
  
  # Return domain with maximum overlap
  return(names(which.max(domain_counts)))
}

# Map domains to top5_df
top5_df$Domain <- mapply(assign_domain, top5_df$Start, top5_df$End)

# Print
print(top5_df)
