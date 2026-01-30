DEBUG <- TRUE
DEBUG_TEAM <- "BOS"

library(dplyr)
library(purrr)
library(tidyr)
library(zoo)
library(ggplot2)

data_initial <- readRDS("data/data_initial.rds")
team_vec <- readRDS("data/team_vec.rds")

# 1) team split
df_list <- split(data_initial, data_initial$team)

if (DEBUG) {
  cat("\n--- Split check ---\n")
  cat("Teams:", length(df_list), "\n")
  cat(DEBUG_TEAM, "rows:", nrow(df_list[[DEBUG_TEAM]]), "\n")
  print(head(df_list[[DEBUG_TEAM]][, c("team","team_opp","date","won")]))
}

# 2) lag5
lagify_df <- function(df) {
  df %>%
    arrange(date) %>%
    mutate(across(
      where(is.numeric),
      ~ rollapplyr(lag(.x), 5, mean, fill = NA, align = "right"),
      .names = "{.col}_lag5"
    ))
}
df_list_lag <- map(df_list, lagify_df)

if (DEBUG) {
  df_dbg <- df_list_lag[[DEBUG_TEAM]]
  lag_cols_dbg <- grep("_lag5$", names(df_dbg), value = TRUE)
  cat("\n--- Lag5 check ---\n")
  cat("Lag cols:", length(lag_cols_dbg), "\n")
  print(head(df_dbg[, c("team","team_opp","date","won", lag_cols_dbg[1])]))
}

# 3) opponent lag5 ekleme
add_opp_lag5 <- function(team_df, df_list_lag) {
  lag_cols <- grep("_lag5$", names(team_df), value = TRUE)
  
  team_df %>%
    mutate(
      opp_stats = pmap(
        list(opp = team_opp, gdate = date),
        function(opp, gdate) {
          opp_df <- df_list_lag[[opp]]
          if (is.null(opp_df)) {
            return(as_tibble(setNames(as.list(rep(NA, length(lag_cols))),
                                      paste0(lag_cols, "_opp"))))
          }
          opp_row <- opp_df %>% filter(date == gdate)
          if (nrow(opp_row) == 0) {
            as_tibble(setNames(as.list(rep(NA, length(lag_cols))),
                               paste0(lag_cols, "_opp")))
          } else {
            opp_row %>%
              select(all_of(lag_cols)) %>%
              rename_with(~ paste0(.x, "_opp"))
          }
        }
      )
    ) %>%
    unnest(opp_stats)
}

df_list_full <- imap(df_list_lag, ~ add_opp_lag5(.x, df_list_lag))

if (DEBUG) {
  df_dbg_full <- df_list_full[[DEBUG_TEAM]]
  opp_cols_dbg <- grep("_lag5_opp$", names(df_dbg_full), value = TRUE)
  cat("\n--- Opp lag5 check ---\n")
  cat("Opp lag cols:", length(opp_cols_dbg), "\n")
  print(head(df_dbg_full[, c("team","team_opp","date","won", opp_cols_dbg[1])]))
}

# 4) senin vars_keep aynen
vars_keep <- c(
  "fg_max_opp_lag5","pts_max_opp_lag5","fga_max_opp_lag5",
  "ft%_max_lag5","mp...2_lag5","mp...3_lag5",
  "mp_opp...76_lag5","mp_opp...77_lag5","ast%_max_lag5"
)

make_model_data <- function(team_code) {
  df <- df_list_full[[team_code]]
  if (is.null(df)) stop("Team not found: ", team_code)
  
  df %>%
    mutate(won = factor(ifelse(won, 1, 0), levels = c(0, 1))) %>%
    select(won, all_of(vars_keep))
}

# 5) corr plot (top 40 lag features)
plot_corr_with_won <- function(team_code) {
  df <- df_list_full[[team_code]]
  if (is.null(df)) stop("Team not found: ", team_code)
  
  num_df <- df %>%
    mutate(won_num = as.numeric(won)) %>%
    select(where(is.numeric))
  
  corr_vec <- sapply(
    num_df %>% select(-won_num),
    function(x) cor(x, num_df$won_num, use = "pairwise.complete.obs")
  )
  
  corr_df <- tibble(variable = names(corr_vec), corr = as.numeric(corr_vec)) %>%
    filter(grepl("_lag5", variable)) %>%
    arrange(desc(abs(corr))) %>%
    slice(1:40)
  
  p <- ggplot(corr_df, aes(x = reorder(variable, corr), y = corr)) +
    geom_col(width = 0.7) +
    coord_flip() +
    geom_text(aes(label = sprintf("%.2f", corr),
                  hjust = ifelse(corr > 0, -0.15, 1.15)),
              size = 3) +
    labs(
      title = paste0(team_code, ": correlation with win (top 40 lag features)"),
      x = NULL,
      y = "Pearson r"
    ) +
    theme_minimal(base_size = 11)
  
  outpath <- paste0("results/plots/corr_with_win_", team_code, ".png")
  ggsave(outpath, p, width = 10, height = 12)
  
  if (DEBUG) {
    print(p)
    cat("Saved plot:", outpath, "\n")
  }
  
  invisible(p)
}

if (DEBUG) plot_corr_with_won(DEBUG_TEAM)

saveRDS(make_model_data("BOS"), "data/model/model_BOS.rds")
saveRDS(make_model_data("MIL"), "data/model/model_MIL.rds")

cat("\nSaved: data/model/model_BOS.rds and data/model/model_MIL.rds\n")