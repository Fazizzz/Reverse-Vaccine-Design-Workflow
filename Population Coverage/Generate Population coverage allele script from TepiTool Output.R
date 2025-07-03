# Load libraries
library(dplyr)
library(readr)

# Step 1: Read in Tepitool full output
tepitool <- read_csv("tepitool_complete_results.csv")
head(tepitool)

# Step 2: Filter by IC50 and Percentile Rank
# - Strong binders usually have IC50 <= 50 nM and percentile_rank <= 1
filtered <- tepitool %>%
  filter(ic50 <= 50, percentile_rank <= 1)

# Step 3: Create 'Epitope' and 'Allele' columns formatted for IEDB Population Coverage Tool
# - We need a CSV with two columns: Epitope (peptide) and Allele (HLA)
iedb_format <- filtered %>%
  select(peptide, allele) %>%
  distinct() %>%
  rename(Epitope = peptide, Allele = allele)

# Optional: sort for neatness
iedb_format <- iedb_format %>% arrange(Epitope, Allele)

# Step 4: Write to CSV for IEDB input
write_csv(iedb_format, "IEDB_PopulationCoverage_Input.csv")
