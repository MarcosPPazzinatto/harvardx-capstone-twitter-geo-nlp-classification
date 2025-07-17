
# Author: Marcos Paulo Pazzinatto

# Install and load required packages
# Here we are installing the libraries needed for the project
# "rstudioapi", "dplyr", "readr", "stringr", "fs", "httr", "utils", "tidymodels", "textrecipes", "scales", "ranger", "kernlab"
required_packages <- c("rstudioapi", "dplyr", "readr", "stringr", "fs", "httr", "utils", "tidymodels", "textrecipes", "scales", "ranger", "kernlab")


#In this loop we install all the packages needed for the project
#We check if the package is already installed and if it is not, we install the package.
#This part of the code takes time when the packages are not installed yet.
for (pkg in required_packages) {
  # Check if package is installed; if not, install it
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

# Load additional required libraries
# Although I did the load above, here I leave the load explicit in an alternative way.
library(scales)
library(dplyr)
library(readr)
library(stringr)
library(tidyr)
library(ggplot2)
library(tidymodels)

# Set working directory to the path where this script is located
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# Create folders if they don't exist
dir.create("data", showWarnings = FALSE)
dir.create("rdas", showWarnings = FALSE)
dir.create("report_files", showWarnings = FALSE)

# Define download URL and local file paths
download_url <- "https://archive.ics.uci.edu/static/public/1050/twitter+geospatial+data.zip"
zip_path_1 <- file.path("data", "twitter_geospatial_data.zip")
zip_path_2 <- file.path("data", "twitter.zip")
data_dir <- "data"

# Download the dataset if not already downloaded
#Here we have a timeout set to 10 minutes, 
#in case the dataset download takes a while, 
#the default is 60 seconds, but in some cases it is not enough
if (!file.exists(zip_path_1)) {
  message("Downloading dataset...")
  options(timeout = max(600, getOption("timeout")))
  download.file(download_url, destfile = zip_path_1, mode = "wb")
  message("Download complete: ", zip_path_1)
} else {
  message("Dataset already downloaded.")
}

#As the dataset comes with a zip inside the other zip.
#the extraction is performed separately twice layers
#I could have done it with loop
# Unzip the first layer
if (!file.exists(zip_path_2)) {
  unzip(zip_path_1, exdir = data_dir)
  message("First unzip complete: ", zip_path_2)
  message("Removed first zip: ", zip_path_1)
} else {
  message("First zip already extracted.")
}

# Unzip the second layer
unzipped_files <- list.files(data_dir, pattern = "\\.csv$", full.names = TRUE)

if (length(unzipped_files) == 0) {
  unzip(zip_path_2, exdir = data_dir)
  message("Second unzip complete: CSV files extracted.")
  message("Removed second zip: ", zip_path_2)
} else {
  message("CSV files already extracted.")
}

# Load CSV file
tweets <- read_csv("data/twitter.csv")

# View structure of the dataset
glimpse(tweets)

# Rename columns
colnames(tweets) <- c("longitude", "latitude", "timestamp", "timezone")

# Filter invalid coordinates
tweets <- tweets %>%
  filter(!is.na(longitude), !is.na(latitude)) %>%
  filter(longitude >= -180 & longitude <= 180) %>%
  filter(latitude >= -90 & latitude <= 90)

# Create regions based on latitude and longitude
tweets <- tweets %>%
  mutate(region = case_when(
    latitude >= 35 & longitude <= -90 ~ "West",
    latitude >= 35 & longitude > -90 ~ "East",
    latitude < 35 ~ "South",
    TRUE ~ "Other"
  ))

# Plot tweet count per region
tweets %>%
  count(region) %>%
  ggplot(aes(x = region, y = n, fill = region)) +
  geom_bar(stat = "identity") +
  labs(title = "Tweet Count per Region", x = "Region", y = "Count") +
  scale_y_continuous(labels = label_comma()) +
  theme_minimal()



# Sample for EDA to improve performance
# Here I put a smaller sample to make it easier to run the script
# If you run at 100% sampling, you will need more than 120 GB of RAM.
set.seed(123)
eda_sample <- tweets %>%
  group_by(region) %>%
  sample_n(size = min(500, n()), replace = FALSE) %>%
  ungroup()

# Plot tweet count by timezone
p1 <- eda_sample %>%
  count(timezone) %>%
  ggplot(aes(x = reorder(as.factor(timezone), -n), y = n)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(title = "Tweet Count by Timezone (Sample)", x = "Timezone", y = "Count") +
  scale_y_continuous(labels = label_comma()) +
  theme_minimal()
print(p1)

# Plot tweet geolocations
p2 <- eda_sample %>%
  ggplot(aes(x = longitude, y = latitude)) +
  geom_point(alpha = 0.1, color = "darkgreen") +
  labs(title = "Tweet Geolocations (Sample)", x = "Longitude", y = "Latitude") +
  scale_y_continuous(labels = label_comma()) +
  theme_minimal()
print(p2)

set.seed(42)

# Sample for modeling
# Here I put a smaller sample to make it easier to run the script
tweets_sampled <- tweets %>%
  group_by(region) %>%
  sample_n(size = min(500, n()), replace = FALSE) %>%
  ungroup() %>%
  mutate(region = as.factor(region)) %>%
  mutate(timestamp = as.character(timestamp))

# Split into training and testing sets
split <- initial_split(tweets_sampled, prop = 0.8, strata = region)
train_data <- training(split)
test_data  <- testing(split)

# Preprocessing recipe for text modeling
log_recipe <- recipe(region ~ timestamp, data = train_data) %>%
  step_tokenize(timestamp) %>%
  step_stopwords(timestamp) %>%
  step_tokenfilter(timestamp, max_tokens = 1000) %>%
  step_tfidf(timestamp)

# Logistic Regression model setup
log_model <- logistic_reg() %>%
  set_engine("glm") %>%
  set_mode("classification")

# Workflow
log_workflow <- workflow() %>%
  add_model(log_model) %>%
  add_recipe(log_recipe)

# Train logistic regression model
log_fit <- log_workflow %>%
  fit(data = train_data)

# Predict and evaluate logistic regression
log_preds <- predict(log_fit, new_data = test_data) %>%
  bind_cols(test_data)
log_metrics <- log_preds %>%
  metric_set(accuracy, precision, recall, f_meas)(truth = region, estimate = .pred_class)
log_cm <- conf_mat(log_preds, truth = region, estimate = .pred_class)
log_metrics
autoplot(log_cm, type = "heatmap") +
  ggtitle("Logistic Regression – Confusion Matrix")

# Random Forest model setup
rf_recipe <- recipe(region ~ timestamp, data = train_data) %>%
  step_tokenize(timestamp) %>%
  step_stopwords(timestamp) %>%
  step_tokenfilter(timestamp, max_tokens = 1000) %>%
  step_tfidf(timestamp)

rf_model <- rand_forest(mtry = 10, trees = 100, min_n = 5) %>%
  set_engine("ranger") %>%
  set_mode("classification")

rf_workflow <- workflow() %>%
  add_model(rf_model) %>%
  add_recipe(rf_recipe)

# Train random forest model
rf_fit <- rf_workflow %>%
  fit(data = train_data)

# Predict and evaluate random forest
rf_preds <- predict(rf_fit, new_data = test_data) %>%
  bind_cols(test_data)
rf_metrics <- rf_preds %>%
  metrics(truth = region, estimate = .pred_class)
rf_cm <- conf_mat(rf_preds, truth = region, estimate = .pred_class)
rf_metrics
autoplot(rf_cm, type = "heatmap") +
  ggtitle("Random Forest – Confusion Matrix")

# Support Vector Machine model setup
svm_model <- svm_linear() %>%
  set_engine("kernlab") %>%
  set_mode("classification")

# Add workflow on model
svm_workflow <- workflow() %>%
  add_model(svm_model) %>%
  add_recipe(log_recipe)

# Train SVM model
svm_fit <- svm_workflow %>%
  fit(data = train_data)

# Predict and evaluate SVM
svm_preds <- predict(svm_fit, new_data = test_data) %>%
  bind_cols(test_data)
svm_metrics <- svm_preds %>%
  metrics(truth = region, estimate = .pred_class)
svm_metrics