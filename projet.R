
# Boudjemaa Achraf & Gargabou Fedi

# installation des packages

library(dplyr)
library(ggplot2)
library(caret)
library(rpart)
library(rpart.plot)
library(randomForest)
library(e1071)
library(class)
library(pROC)
library(ROSE)
library(corrplot)

set.seed(123)

donnees <- read.csv("Data Projet.csv", sep = ",", dec = ".", header = TRUE, stringsAsFactors = FALSE)
donnees_new <- read.csv("Data Projet New.csv", sep = ",", dec = ".", header = TRUE, stringsAsFactors = FALSE)

nrow(donnees)
dim(donnees)
dim(donnees_new)
str(donnees)
str(donnees_new)
head(donnees)
summary(donnees)


# --- pre-traitement ---

# 999 = NA codes dans age et adresse
donnees$age[donnees$age == 999] <- NA
donnees$adresse[donnees$adresse == 999] <- NA
donnees_new$age[donnees_new$age == 999] <- NA
donnees_new$adresse[donnees_new$adresse == 999] <- NA

cat("NA age :", sum(is.na(donnees$age)), "| NA adresse :", sum(is.na(donnees$adresse)), "\n")

# table(donnees$age == 999)

# imputation par la mediane (calculee sur donnees uniquement)
med_age     <- median(donnees$age, na.rm = TRUE)
med_adresse <- median(donnees$adresse, na.rm = TRUE)

donnees$age[is.na(donnees$age)]         <- med_age
donnees$adresse[is.na(donnees$adresse)] <- med_adresse
donnees_new$age[is.na(donnees_new$age)]         <- med_age
donnees_new$adresse[is.na(donnees_new$adresse)] <- med_adresse

# categorie constante (toujours 12), inutile
donnees$categorie    <- NULL
donnees_new$categorie <- NULL

niveaux_edu <- c("Niveau bac", "Bac+2", "Bac+3", "Bac+4", "Bac+5 et plus")
donnees$education    <- factor(donnees$education,    levels = niveaux_edu, ordered = TRUE)
donnees_new$education <- factor(donnees_new$education, levels = niveaux_edu, ordered = TRUE)

donnees$defaut <- factor(donnees$defaut, levels = c("Non", "Oui"))

# View(donnees)

summary(donnees)
levels(donnees$education)
levels(donnees$defaut)
table(donnees$defaut)
prop.table(table(donnees$defaut))


# EDA

dir.create("graphiques", showWarnings = FALSE)

vars_num <- c("age", "emploi", "adresse", "revenus", "debcred", "debcarte", "autres")

# barplot defaut
g <- ggplot(donnees, aes(x = defaut, fill = defaut)) +
  geom_bar() +
  labs(x = "Defaut", y = "Effectif", title = "Répartition des classes") +
  theme(legend.position = "none")
ggsave("graphiques/01_distribution_defaut.png", g, width = 7, height = 5, dpi = 100)

# boxplots par variable
for (v in vars_num) {
  g <- ggplot(donnees, aes(x = defaut, y = .data[[v]], fill = defaut)) +
    geom_boxplot() +
    labs(x = "Defaut", y = v) +
    theme(legend.position = "none")
  ggsave(paste0("graphiques/02_boxplot_", v, ".png"), g, width = 7, height = 5, dpi = 100)
}

# education vs defaut
g <- ggplot(donnees, aes(x = education, fill = defaut)) +
  geom_bar(position = "fill") +
  labs(x = "Education", y = "Proportion", fill = "Defaut") +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
ggsave("graphiques/03_education_vs_defaut.png", g, width = 7, height = 5, dpi = 100)

# matrice de correlation
png("graphiques/04_correlations.png", width = 700, height = 600)
mat_cor <- cor(donnees[, vars_num])
corrplot(mat_cor, method = "color", type = "upper", addCoef.col = "black", tl.cex = 0.9, number.cex = 0.8)
dev.off()

# table(donnees$education, donnees$defaut)

# stats par classe
cat("\n--- Moyennes par classe ---\n")
print(aggregate(donnees[, vars_num], by = list(defaut = donnees$defaut), FUN = mean))
cat("\n--- Medianes par classe ---\n")
print(aggregate(donnees[, vars_num], by = list(defaut = donnees$defaut), FUN = median))
cat("\n--- Ecarts-types par classe ---\n")
print(aggregate(donnees[, vars_num], by = list(defaut = donnees$defaut), FUN = sd))


# critere principal = rappel sur Oui
# faux negatif = pret accorde a un mauvais payeur = perte cash
# on minimise les FN meme au prix de plus de FP

evaluer_modele <- function(pred, vrai, nom) {
  cm        <- confusionMatrix(pred, vrai, positive = "Oui")
  precision <- cm$byClass["Pos Pred Value"]
  rappel    <- cm$byClass["Sensitivity"]
  f_score   <- 2 * precision * rappel / (precision + rappel)
  data.frame(
    nom_modele   = nom,
    taux_succes  = cm$overall["Accuracy"],
    rappel       = rappel,
    precision    = precision,
    specificite  = cm$byClass["Specificity"],
    f_score      = f_score
  )
}

resultats <- data.frame()


# split train/test
donnees_model <- donnees
donnees_model$client <- NULL

index_train <- createDataPartition(donnees_model$defaut, p = 0.7, list = FALSE)
train <- donnees_model[index_train, ]
test  <- donnees_model[-index_train, ]

dim(train)
dim(test)
prop.table(table(train$defaut))
prop.table(table(test$defaut))

# table(train$education)

# version reequilibree avec ROSE (education deordonnee, ROSE n'accepte pas ordered)
train_tmp <- train
train_tmp$education <- factor(as.character(train_tmp$education), levels = niveaux_edu)
train_balance <- ROSE(defaut ~ ., data = train_tmp, seed = 123)$data
train_balance$education <- factor(train_balance$education, levels = niveaux_edu, ordered = TRUE)
table(train_balance$defaut)


# arbres de decision
arbre <- rpart(defaut ~ ., data = train, method = "class")
pred <- predict(arbre, test, type = "class")
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "arbre"))

arbre2 <- rpart(defaut ~ ., data = train, method = "class", control = rpart.control(cp = 0.001))
pred <- predict(arbre2, test, type = "class")
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "arbre cp=0.001"))

arbre_bal <- rpart(defaut ~ ., data = train_balance, method = "class")
pred <- predict(arbre_bal, test, type = "class")
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "arbre balance"))

# random forest
rf <- randomForest(defaut ~ ., data = train, ntree = 100)
pred <- predict(rf, test)
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "rf 100"))

rf500 <- randomForest(defaut ~ ., data = train, ntree = 500)
pred <- predict(rf500, test)
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "rf 500"))

rf_bal <- randomForest(defaut ~ ., data = train_balance, ntree = 500)
pred <- predict(rf_bal, test)
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "rf 500 balance"))

# knn (normalisation via preProcess)
knn <- train(defaut ~ ., data = train, method = "knn",
             preProcess = c("center", "scale"),
             tuneGrid = data.frame(k = 5))
pred <- predict(knn, test)
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "knn 5"))

knn15 <- train(defaut ~ ., data = train, method = "knn",
               preProcess = c("center", "scale"),
               tuneGrid = data.frame(k = 15))
pred <- predict(knn15, test)
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "knn 15"))

knn_bal <- train(defaut ~ ., data = train_balance, method = "knn",
                 preProcess = c("center", "scale"),
                 tuneGrid = data.frame(k = 15))
pred <- predict(knn_bal, test)
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "knn 15 balance"))

# naive bayes
nb <- naiveBayes(defaut ~ ., data = train)
pred <- predict(nb, test)
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "naive bayes"))

nb_bal <- naiveBayes(defaut ~ ., data = train_balance)
pred <- predict(nb_bal, test)
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "naive bayes balance"))

# regression logistique
logit <- glm(defaut ~ ., data = train, family = binomial)
prob <- predict(logit, test, type = "response")

pred <- factor(ifelse(prob > 0.5, "Oui", "Non"), levels = c("Non", "Oui"))
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "log 0.5"))

pred <- factor(ifelse(prob > 0.3, "Oui", "Non"), levels = c("Non", "Oui"))
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "log 0.3"))

logit_bal <- glm(defaut ~ ., data = train_balance, family = binomial)
prob <- predict(logit_bal, test, type = "response")
pred <- factor(ifelse(prob > 0.5, "Oui", "Non"), levels = c("Non", "Oui"))
resultats <- rbind(resultats, evaluer_modele(pred, test$defaut, "log 0.5 balance"))

resultats <- resultats[order(-resultats$rappel), ]
print(resultats)
write.csv(resultats, "resultats_modeles.csv", row.names = FALSE)


# modele final : logit sur train_balance, seuil 0.5
modele_final <- glm(defaut ~ ., data = train_balance, family = binomial)

prob_oui  <- predict(modele_final, test, type = "response")
pred_class <- factor(ifelse(prob_oui > 0.5, "Oui", "Non"), levels = c("Non", "Oui"))

# matrice de confusion complete
cm <- confusionMatrix(pred_class, test$defaut, positive = "Oui")
print(cm)

# courbe ROC + AUC
roc_obj <- roc(test$defaut, prob_oui, levels = c("Non", "Oui"))
auc_val <- auc(roc_obj)
print(auc_val)

png("graphiques/05_courbe_roc.png", width = 700, height = 500)
plot(roc_obj, main = paste("AUC =", round(auc_val, 3)))
dev.off()

# coefficients et significativite des variables
print(summary(modele_final))

cat("Modele final : logit sur train_balance (ROSE), seuil 0.5\n")
cat("Rappel =", round(cm$byClass["Sensitivity"], 3), "\n")
cat("Precision =", round(cm$byClass["Pos Pred Value"], 3), "\n")
cat("F-score =", round(2 * cm$byClass["Pos Pred Value"] * cm$byClass["Sensitivity"] /
      (cm$byClass["Pos Pred Value"] + cm$byClass["Sensitivity"]), 3), "\n")
cat("AUC =", round(auc_val, 3), "\n")


# predictions sur les 500 nouveaux clients
prob_oui_new <- predict(modele_final, donnees_new, type = "response")
pred_new     <- factor(ifelse(prob_oui_new > 0.5, "Oui", "Non"), levels = c("Non", "Oui"))

# proba de la classe predite (pas toujours proba(Oui))
prob_classe_pred <- ifelse(pred_new == "Oui", prob_oui_new, 1 - prob_oui_new)

predictions <- data.frame(
  client         = donnees_new$client,
  classe_predite = pred_new,
  probabilite    = prob_classe_pred
)

write.csv(predictions, "Boudjemaa_Achraf_Gargabou_Fedi.csv", row.names = FALSE)

table(pred_new)
prop.table(table(pred_new))

# distribution des probas par classe predite
summary(prob_classe_pred[pred_new == "Oui"])
summary(prob_classe_pred[pred_new == "Non"])

head(predictions)
tail(predictions)
