library(dplyr)
library(lubridate)
library(fda)
library(tidyr)
library(MASS)

url <- 'https://raw.githubusercontent.com/Nixtla/transfer-learning-time-series/refs/heads/main/datasets/pjm_in_zone.csv'
df <- read.csv(url)
df$ds <- ymd_hms(df$ds, tz = "UTC")

result <- df %>%
  group_by(unique_id) %>%
  slice_head(n = 2)

test_df <- df %>%
  group_by(unique_id) %>%
  slice_tail(n = 1752)

input_df <- df %>%
  group_by(unique_id) %>%
  slice((n() - 8783):(n() - 1752)) %>% 
  ungroup() 

input_df <- input_df %>%
  mutate(
    date = as.Date(ds),      
    hour = format(ds, "%H")   
  )

functional_matrices <- input_df %>%
  group_by(unique_id) %>% 
  group_split() %>%       
  setNames(unique(input_df$unique_id))

create_hourly_matrix <- function(series) {
  series <- series[order(series$date, series$hour), ]
  y_values <- series$y
  num_rows <- floor(length(y_values) / 24)
  hourly_matrix <- matrix(
    y_values[1:(num_rows * 24)],  # Use only complete 24-hour cycles
    ncol = 24,
    byrow = TRUE
  )
  colnames(hourly_matrix) <- c(
    "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", 
    "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", 
    "00", "01", "02", "03"
  )
  
  return(hourly_matrix)
}
functional_matrices <- lapply(functional_matrices, create_hourly_matrix)

# test functional matrices
test_functional_matrices <- test_df %>%
  mutate(
    date = as.Date(ds),
    hour = format(ds, "%H")
  ) %>%
  group_by(unique_id) %>%
  group_split() %>%
  setNames(unique(test_df$unique_id)) %>%
  lapply(create_hourly_matrix)

train_set <- functional_matrices$`AP-AP`
test_set <- test_functional_matrices$`AP-AP`
v <- seq(0, 23, by = 1)
n_pc <- 5

#FPCA 
train_fd <- mat2fd(mat_obj = train_set, argvals = v, range_val = range(v))
train_fpca <- pca.fd(fdobj = train_fd, nharm = n_pc)
fpca_train_scores <- train_fpca$scores  # matrix - n_train x n_pc


train_avg <- rowMeans(train_set)

fpca_train_df <- as.data.frame(fpca_train_scores)
names(fpca_train_df) <- paste0("PC", 1:n_pc)
fpca_train_df$avg <- train_avg
reg_model_fpca <- lm(avg ~ ., data = fpca_train_df)
mean_func <- as.vector(train_fpca$meanfd$coefs)        #length = length(v)
eigen_functions <- train_fpca$harmonics$coefs          # matrix -length(v) x n_pc

n_test <- nrow(test_set)
fpca_test_scores <- matrix(NA, nrow = n_test, ncol = n_pc)

for(i in 1:n_test) {
  test_curve <- test_set[i, ]
  test_fd <- mat2fd(mat_obj = matrix(test_curve, nrow = 1), argvals = v, range_val = range(v))
  test_values <- as.vector(eval.fd(v, test_fd))
  test_centered <- test_values - mean_func
  fpca_test_scores[i, ] <- as.vector(t(test_centered) %*% ginv(t(eigen_functions)))
}

fpca_test_df <- as.data.frame(fpca_test_scores)
names(fpca_test_df) <- paste0("PC", 1:n_pc)

pred_fpca_avg <- predict(reg_model_fpca, newdata = fpca_test_df)
actual_avg <- rowMeans(test_set)

mse_fpca <- mean((pred_fpca_avg - actual_avg)^2)
cat("FPCA MSE:", mse_fpca, "\n")


# ----------------------- PCA ---7-- -----------------------

pca_model <- prcomp(train_set, center = TRUE, scale. = FALSE)
pca_train_scores <- pca_model$x[, 1:n_pc]

pca_train_df <- as.data.frame(pca_train_scores)
names(pca_train_df) <- paste0("PC", 1:n_pc)
pca_train_df$avg <- train_avg

reg_model_pca <- lm(avg ~ ., data = pca_train_df)

pca_test_scores <- predict(pca_model, newdata = test_set)[, 1:n_pc]
pca_test_df <- as.data.frame(pca_test_scores)
names(pca_test_df) <- paste0("PC", 1:n_pc)

pred_pca_avg <- predict(reg_model_pca, newdata = pca_test_df)

mse_pca <- mean((pred_pca_avg - actual_avg)^2)
cat("PCA MSE:", mse_pca, "\n")


#
par(mfrow = c(1, 1))
plot(actual_avg, type = "l", col = "blue", lwd = 2,
     ylab = "Daily Average", xlab = "Day", 
     main = "Actual vs Predicted (5 pc)")
lines(pred_fpca_avg, col = "red", lwd = 2, lty = 2)
lines(pred_pca_avg, col = "green", lwd = 2, lty = 3)
legend("topright", legend = c("Actual", "FPCA Prediction", "PCA Prediction"),
       col = c("blue", "red", "green"), lty = c(1,2,3), lwd = 2)


plot(actual_avg, pred_fpca_avg, 
     main = "FPCA vs PCA (5)",
     xlab = "Actual Average", ylab = "Predicted Average",
     col = "red", pch = 16, xlim = range(actual_avg, pred_fpca_avg, pred_pca_avg),
     ylim = range(actual_avg, pred_fpca_avg, pred_pca_avg))
points(actual_avg, pred_pca_avg, col = "green", pch = 16)
abline(0, 1, col = "blue", lwd = 2, lty = 2)
legend("topleft", legend = c("FPCA Prediction", "PCA Prediction", "45° Line"),
       col = c("red", "green", "blue"), pch = c(16,16,NA), lty = c(NA,NA,2), lwd = 2)
