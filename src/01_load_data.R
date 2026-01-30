DEBUG <- TRUE

library(dplyr)
library(readr)

dir.create("data", showWarnings = FALSE)

data_initial <- read_csv(
  "https://raw.githubusercontent.com/alpaalp/csv_proje/refs/heads/main/nba_games%20(1).csv",
  show_col_types = FALSE
)

data_initial <- data_initial %>% arrange(date)

team_vec <- data_initial %>%
  distinct(team) %>%
  pull(team)

if (DEBUG) {
  cat("Rows:", nrow(data_initial), "\n")
  cat("Columns:", ncol(data_initial), "\n")
  cat("Teams:", length(team_vec), "\n\n")
  print(head(data_initial[, c("team", "team_opp", "date", "won")]))
}

saveRDS(data_initial, "data/data_initial.rds")
saveRDS(team_vec, "data/team_vec.rds")

cat("Saved: data/data_initial.rds and data/team_vec.rds\n")