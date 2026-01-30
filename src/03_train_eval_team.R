DEBUG <- TRUE

library(dplyr)
library(caret)
library(pROC)
library(ggplot2)

dir.create("results", showWarnings = FALSE)
dir.create("results/plots", showWarnings = FALSE)

plot_roc <- function(y_true, prob, title, outpath) {
  roc_obj <- roc(response = y_true, predictor = prob, quiet = TRUE)
  
  df_roc <- tibble(
    fpr = 1 - roc_obj$specificities,
    tpr = roc_obj$sensitivities
  )
  
  p <- ggplot(df_roc, aes(x = fpr, y = tpr)) +
    geom_line(linewidth = 1) +
    geom_abline(linetype = "dashed") +
    coord_equal() +
    labs(title = title, x = "False Positive Rate", y = "True Positive Rate") +
    theme_minimal(base_size = 12)
  
  ggsave(outpath, p, width = 7, height = 5)
  
  if (DEBUG) {
    print(p)
    cat("Saved plot:", outpath, "\n")
  }
  
  as.numeric(auc(roc_obj))
}

train_eval <- function(team_code, seed = 11, cutoff = 0.70) {
  
  path <- paste0("data/model/model_", team_code, ".rds")
  data_mod <- readRDS(path)
  
  set.seed(seed)
  idx <- createDataPartition(data_mod$won, p = 0.7, list = FALSE)
  train_data <- data_mod[idx, ]
  test_data  <- data_mod[-idx, ]
  
  # -------- Model 1 (all vars_keep) --------
  glm_fit <- glm(won ~ ., data = train_data, family = binomial)
  prob <- predict(glm_fit, newdata = test_data, type = "response")
  pred <- factor(ifelse(prob > 0.5, "1", "0"), levels = c("0","1"))
  
  cm <- confusionMatrix(pred, test_data$won, positive = "1")
  y_true <- as.numeric(as.character(test_data$won))
  auc1 <- plot_roc(
    y_true, prob,
    title = paste0(team_code, " ROC (Model 1: all vars)"),
    outpath = paste0("results/plots/roc_", team_code, "_model1.png")
  )
  acc1 <- as.numeric(cm$overall["Accuracy"])
  
  if (DEBUG) {
    cat("\n--- Confusion Matrix (Model 1) ", team_code, " ---\n", sep = "")
    print(cm$table)
    cat("Accuracy:", round(acc1, 3), "AUC:", round(auc1, 3), "\n")
  }
  
  # -------- Model 2 (remove high correlated vars) --------
  X <- train_data %>% select(-won)
  corr_mat <- cor(X, use = "pairwise.complete.obs")
  high_corr <- findCorrelation(corr_mat, cutoff = cutoff)
  vars_clean <- colnames(X)[-high_corr]
  
  train_last <- train_data %>% select(won, all_of(vars_clean))
  test_last  <- test_data  %>% select(won, all_of(vars_clean))
  
  glm_fit2 <- glm(won ~ ., data = train_last, family = binomial)
  prob2 <- predict(glm_fit2, newdata = test_last, type = "response")
  pred2 <- factor(ifelse(prob2 > 0.5, "1", "0"), levels = c("0","1"))
  
  cm2 <- confusionMatrix(pred2, test_last$won, positive = "1")
  y_true2 <- as.numeric(as.character(test_last$won))
  auc2 <- plot_roc(
    y_true2, prob2,
    title = paste0(team_code, " ROC (Model 2: corr<", cutoff, ")"),
    outpath = paste0("results/plots/roc_", team_code, "_model2.png")
  )
  acc2 <- as.numeric(cm2$overall["Accuracy"])
  
  if (DEBUG) {
    cat("\n--- Confusion Matrix (Model 2) ", team_code, " ---\n", sep = "")
    print(cm2$table)
    cat("Accuracy:", round(acc2, 3), "AUC:", round(auc2, 3), "\n")
    cat("\n--- Vars kept after corr filter (", team_code, ") ---\n", sep = "")
    print(vars_clean)
  }
  
  cat("\n===", team_code, "===\n")
  cat("Model 1: Accuracy =", round(acc1, 3), " AUC =", round(auc1, 3), "\n")
  cat("Model 2: Accuracy =", round(acc2, 3), " AUC =", round(auc2, 3), "\n")
  
  out <- paste0(
    "Team: ", team_code, "\n",
    "Model1_Accuracy: ", round(acc1, 3), "\n",
    "Model1_AUC: ", round(auc1, 3), "\n",
    "Model2_Accuracy: ", round(acc2, 3), "\n",
    "Model2_AUC: ", round(auc2, 3), "\n",
    "Vars_clean: ", paste(vars_clean, collapse = ", "), "\n"
  )
  writeLines(out, paste0("results/metrics_", team_code, ".txt"))
  
  invisible(list(
    team = team_code,
    model1 = list(acc = acc1, auc = auc1),
    model2 = list(acc = acc2, auc = auc2),
    vars_clean = vars_clean
  ))
}

train_eval("BOS")
train_eval("MIL")