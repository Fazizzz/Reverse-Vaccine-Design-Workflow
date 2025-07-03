# Load required packages
library(dplyr)
library(readr)
library(ggplot2)
library(tidyr)
library(reshape2)
library(pheatmap)
library(tibble)

# Load input data
iedb <- read_csv("MHCII_IEDB_Epitope_Summary_Table.csv")
tepi <- read_csv("TepiTool_Epitope_Summary.csv")

# Merge by common peptide sequence
consensus <- inner_join(iedb, tepi, by = "peptide", suffix = c("_IEDB", "_TepiTool"))

# Calculate consensus score
consensus <- consensus %>%
  mutate(Consensus_Score = (Avg_Rank + Avg_Percentile) / 2) %>%
  arrange(Consensus_Score)

# Save consensus table
write_csv(consensus, "Consensus_MHCII_Epitopes_TepiTool_IEDB.csv")

# Select top 5 epitopes
top5 <- consensus %>% slice_min(order_by = Consensus_Score, n = 5)

# Save top 5 summary
write_csv(top5, "Top5_Consensus_MHCII_Epitopes.csv")

# Prepare heatmap data (normalize rank scores: 100 - value)
heatmap_data <- top5 %>%
  select(peptide, Num_Alleles_IEDB, Num_Alleles_TepiTool, Avg_Rank, Avg_Percentile) %>%
  mutate(
    Adj_Rank = 100 - Avg_Rank,
    Adj_Percentile = 100 - Avg_Percentile
  ) %>%
  select(peptide, Num_Alleles_IEDB, Num_Alleles_TepiTool, Adj_Rank, Adj_Percentile) %>%
  rename(
    "IEDB Alleles" = Num_Alleles_IEDB,
    "TepiTool Alleles" = Num_Alleles_TepiTool,
    "IEDB Rank (inverted)" = Adj_Rank,
    "TepiTool Percentile (inverted)" = Adj_Percentile
  ) %>%
  column_to_rownames("peptide")

# Plot heatmap
fig <- pheatmap(
  mat = as.matrix(heatmap_data),
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  display_numbers = TRUE,
  main = "Top 5 Consensus MHC-II Epitopes (IEDB + TepiTool)",
  color = colorRampPalette(c("white", "#33FFFF"))(50),
  fontsize_number = 10,
  angle_col = 45
)

ggsave("Top5_Consensus_MHCII_Epitope_Heatmap.png", plot = fig, dpi=300)
