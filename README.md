# Credit Risk Scoring – Data Mining Project

Academic project – L3 Sciences et Technologies  
**Authors:** Achraf Boudjemaa & Fedi Gargabou

## Project Overview

This project focuses on credit risk analysis and customer default prediction using machine learning techniques in R.

The objective is to identify customers who may default on their credit obligations by analyzing financial and demographic variables. Several classification algorithms are implemented and compared to identify the most suitable model.

The project also includes predictions for 500 new customer records.

## Objectives

- Explore and understand the dataset through Exploratory Data Analysis (EDA).
- Clean and preprocess the data.
- Handle missing values and class imbalance.
- Train and compare multiple classification models.
- Evaluate model performance using relevant classification metrics.
- Select a final model based on its ability to detect customers likely to default.

## Technologies & Libraries

- **Language:** R
- **Data manipulation:** dplyr
- **Data visualization:** ggplot2, corrplot
- **Machine Learning:** caret, rpart, randomForest, e1071, class
- **Class imbalance:** ROSE
- **Model evaluation:** pROC

## Project Workflow

### 1. Data Preprocessing

- Identification of missing values encoded as `999` in the age and address variables.
- Replacement of missing values using median imputation.
- Removal of a constant variable (`categorie`).
- Transformation of education and default variables into factors.
- Exclusion of the customer identifier from the modeling process.

### 2. Exploratory Data Analysis (EDA)

Several visualizations were created to better understand the data:

- Default class distribution.
- Boxplots of numerical variables by default status.
- Education level versus default rate.
- Correlation matrix.
- Descriptive statistics by default class.

### 3. Model Training & Comparison

The dataset is split into training (70%) and testing (30%) subsets using stratified sampling.

The ROSE technique is applied to the training data to address class imbalance.

**14 model configurations are evaluated:**

| Algorithm | Configurations |
|---|---|
| Decision Tree | Standard, cp = 0.001, balanced |
| Random Forest | 100 trees, 500 trees, balanced |
| K-Nearest Neighbors | k = 5, k = 15, balanced k = 15 |
| Naive Bayes | Standard, balanced |
| Logistic Regression | Threshold 0.5, threshold 0.3, balanced |

### 4. Model Evaluation

The models are compared using:

- Accuracy
- Recall (Sensitivity)
- Precision
- Specificity
- F1-score

The main evaluation criterion is **recall for the default class ("Oui")**, because identifying customers at risk of default is a priority in credit risk analysis.

### 5. Final Model & Prediction

The selected model is a logistic regression trained on the ROSE-balanced dataset, using a classification threshold of 0.5.

It is evaluated on the test dataset, with a confusion matrix and ROC curve.

The final model is then used to predict default risk for 500 new customer records.

## Results

The balanced logistic regression achieved the highest recall among the 14 evaluated configurations.

| Metric | Result |
|---|---:|
| Accuracy | 73.37% |
| Recall | 75.80% |
| Precision | 51.42% |
| Specificity | 72.44% |
| F1-score | 61.28% |

These results illustrate the trade-off between detecting potential defaults and limiting false positive predictions.

## Repository Structure

```text
credit-risk-scoring-data-mining/
│
├── projet.R
├── Data Projet.csv
├── Data Projet New.csv
├── resultats_modeles.csv
├── Boudjemaa_Achraf_Gargabou_Fedi.csv
│
└── graphiques/
    ├── 01_distribution_defaut.png
    ├── 02_boxplot_adresse.png
    ├── 02_boxplot_age.png
    ├── 02_boxplot_autres.png
    ├── 02_boxplot_debcarte.png
    ├── 02_boxplot_debcred.png
    ├── 02_boxplot_emploi.png
    ├── 02_boxplot_revenus.png
    ├── 03_education_vs_defaut.png
    ├── 04_correlations.png
    └── 05_courbe_roc.png
```

## How to Run the Project

### 1. Install R

Install R and RStudio if they are not already available.

### 2. Install the required packages

```r
packages <- c(
  "dplyr", "ggplot2", "caret", "rpart",
  "rpart.plot", "randomForest", "e1071",
  "class", "pROC", "ROSE", "corrplot"
)

install.packages(packages)
```

### 3. Run the script

Open `projet.R` in RStudio.

Make sure the working directory is set to the project folder, where the CSV files are located.

Run the script to reproduce the preprocessing, analysis, model comparison, evaluation, visualizations and predictions.

## Disclaimer

This is an academic project developed for educational purposes. The datasets are fictional and are not intended for real-world credit decisions.

---

**Developed by Fedi Gargabou**  
[GitHub](https://github.com/fgargabou) · [LinkedIn](https://www.linkedin.com/in/fedi-gargabou-952b34423/)
