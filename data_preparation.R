############################################################
# Author: Marcos Paulo Pazzinatto
# Script: data_preparation.R
# Purpose: Set up the environment and prepare the dataset
# Dataset: Twitter Geospatial Data (UCI ML Repository)
############################################################

### Install and load required packages

required_packages <- c("rstudioapi", "dplyr", "readr", "stringr", "fs", "httr", "utils", "tidymodels", "textrecipes", "scales", "ranger", "kernlab")

for (pkg in required_packages) {
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

### Set working directory to the path where this script is located

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

### Create folders if they don't exist

dir.create("data", showWarnings = FALSE)
dir.create("rdas", showWarnings = FALSE)
dir.create("report_files", showWarnings = FALSE)

### Define download URL and local file paths

download_url <- "https://archive.ics.uci.edu/static/public/1050/twitter+geospatial+data.zip"
zip_path_1 <- file.path("data", "twitter_geospatial_data.zip")
zip_path_2 <- file.path("data", "twitter.zip")
data_dir <- "data"

### Download the dataset

if (!file.exists(zip_path_1)) {
  message("Downloading dataset...")
  options(timeout = max(600, getOption("timeout")))
  download.file(download_url, destfile = zip_path_1, mode = "wb")
  message("Download complete: ", zip_path_1)
} else {
  message("Dataset already downloaded.")
}

### Unzip first layer

if (!file.exists(zip_path_2)) {
  unzip(zip_path_1, exdir = data_dir)
  message("First unzip complete: ", zip_path_2)
  message("Removed first zip: ", zip_path_1)
} else {
  message("First zip already extracted.")
}

### Unzip second layer

unzipped_files <- list.files(data_dir, pattern = "\\.csv$", full.names = TRUE)

if (length(unzipped_files) == 0) {
  unzip(zip_path_2, exdir = data_dir)
  message("Second unzip complete: CSV files extracted.")
  message("Removed second zip: ", zip_path_2)
} else {
  message("CSV files already extracted.")
}

tweets <- read_csv("data/twitter.csv")

glimpse(tweets)

colnames(tweets) <- c("longitude", "latitude", "timestamp", "timezone")

tweets <- tweets %>%
  filter(!is.na(longitude), !is.na(latitude)) %>%
  filter(longitude >= -180 & longitude <= 180) %>%
  filter(latitude >= -90 & latitude <= 90)