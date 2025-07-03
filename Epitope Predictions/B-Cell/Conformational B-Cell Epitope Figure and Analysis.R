# Load required libraries
library(ggplot2)
library(readr)
library(dplyr)

# Read the DiscoTope data
disco <- read_csv("DiscoTope scores.csv")

# Plotting
figure <- ggplot(disco, aes(x = residue_id, y = discotope_score)) +
  geom_line(color = "black", size = 1) +
  geom_hline(yintercept = -7.7, color = "red", linetype = "dashed", size = 0.8) +
  geom_ribbon(aes(ymin = ifelse(discotope_score > -7.7, -7.7, NA),
                  ymax = ifelse(discotope_score > -7.7, discotope_score, NA)),
              fill = "green", alpha = 0.3) +
  geom_ribbon(aes(ymin = ifelse(discotope_score <= -7.7, discotope_score, NA),
                  ymax = ifelse(discotope_score <= -7.7, -7.7, NA)),
              fill = "pink", alpha = 0.3) +
  labs(title = "DiscoTope Prediction",
       x = "Residue Position",
       y = "DiscoTope Score",
       caption = "Red dashed line = Threshold (-7.7); Green = Predicted epitope") +
  theme_minimal(base_size = 14) +
  theme(
    panel.border = element_rect(color = "black", fill = NA, size = 1),
    plot.title = element_text(hjust = 0.5, face = "bold")
  )

ggsave("Conformational B-cell Epitopes predicted per Residue figure.png",plot = figure,dpi = 600)

### Get top 5 Conformational B-Cell Epitopes -----------

# Define domain boundaries
get_domain <- function(pos) {
  if (pos >= 1   & pos <= 259) return("Domain 1")
  if (pos >= 260 & pos <= 489) return("Domain 2")
  if (pos >= 490 & pos <= 594) return("Domain 3")
  if (pos >= 595 & pos <= 735) return("Domain 4")
  return("Outside Known Domains")
}

# Amino acid 3-letter to 1-letter mapping
aa_map <- c(
  ALA = "A", ARG = "R", ASN = "N", ASP = "D", CYS = "C",
  GLN = "Q", GLU = "E", GLY = "G", HIS = "H", ILE = "I",
  LEU = "L", LYS = "K", MET = "M", PHE = "F", PRO = "P",
  SER = "S", THR = "T", TRP = "W", TYR = "Y", VAL = "V"
)


# Annotate domain and sequence
disco <- disco %>%
  mutate(
    Domain = sapply(residue_id, get_domain),
    AA = aa_map[residue_name]
  )

# Filter positive predictions
positive <- disco %>%
  filter(discotope_score > -7.7) %>%
  arrange(residue_id) %>%
  mutate(Group = cumsum(c(TRUE, diff(residue_id) != 1)))

# Summarize epitope regions with sequence
top_epitopes <- positive %>%
  group_by(Group) %>%
  summarise(
    Start = min(residue_id),
    End = max(residue_id),
    Length = n(),
    Sequence = paste(AA, collapse = ""),
    Avg_Score = round(mean(discotope_score), 3),
    Domain = names(sort(table(Domain), decreasing = TRUE))[1]
  ) %>%
  arrange(desc(Avg_Score)) %>%
  slice_head(n = 5)

# View result
print(top_epitopes)

# Optional: write to CSV
write_csv(top_epitopes, "Top5_DiscoTope_Epitopes_withSequence.csv")

