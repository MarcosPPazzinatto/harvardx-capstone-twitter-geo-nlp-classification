# HarvardX Capstone: Twitter Geo NLP Classification

This project is part of the HarvardX Data Science Capstone and focuses on using Natural Language Processing (NLP) techniques to classify the geographic region of tweets based on their textual content. It leverages supervised machine learning models to predict the region label of a tweet given its message content.

## Project Structure
```
harvardx-capstone-twitter-geo-nlp-classification
│
├── data/ # Raw and processed datasets
│ ├── dataset.csv
│ ├── dataset.zip
│ ├── twitter.csv
│ ├── twitter.zip
│ ├── twitter_geospatial_data.zip
│ └── __MACOSX/
│
├── rdas/ # RDS files for faster loading
│ └── dataset.data
│
├── report_files/ # Generated report files
│ └── twitter_report.pdf
│
├── data_preparation.R # Script for data cleaning and preparation
├── twitter_code.R # Machine learning model building and evaluation
├── twitter_report.Rmd # R Markdown report source
└── twitter_report.pdf # Final compiled report
```


## Objectives

- Explore and clean geotagged tweet data
- Use NLP techniques to transform tweet text into features
- Build and compare machine learning models to classify tweets by region
- Evaluate model performance and interpret results

## Machine Learning Models

The project uses two different ML models:

1. **Logistic Regression** (baseline)
2. **Support Vector Machine (SVM)** and **Random Forest** (advanced models)

## Reproducibility

The code includes installation checks for all required R packages and sets the working directory automatically based on the script’s location. All files use relative paths.

## How to Run

1. Clone the repository.
2. Run `data_preparation.R` to download and process the dataset.
3. Run `twitter_code.R` to build and evaluate the models.
4. Knit `twitter_report.Rmd` to generate the PDF report.

## Dataset

The dataset used in this project is publicly available from the UCI Machine Learning Repository:  
https://archive.ics.uci.edu/dataset/320/twitter+geospatial+data

## License

This project is for educational purposes only and does not claim ownership of the dataset.

## Author

Marcos Paulo Pazzinatto
