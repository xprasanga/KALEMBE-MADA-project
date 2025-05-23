#load packages
#install.packages("table1")
library(readxl)
library(readr)
library(dplyr)
library(ggplot2)
library(tidyverse)
library(here)
library(table1)
library(plotly)
library(ggtext)
library(broom)
library(flextable)
# load the data sets
Immunology_lab_results <- read_excel("data/raw-data/Immunology lab results.xlsx")
View(Immunology_lab_results)
GENDER_DEUTERIUM_DILUTION_DATA <- read_excel("data/raw-data/GENDER DEUTERIUM DILUTION DATA.xlsx")
View(GENDER_DEUTERIUM_DILUTION_DATA)

##data cleaning.


#select variables in both the data sets and later merge them together.

gender_data<-GENDER_DEUTERIUM_DILUTION_DATA%>%
  dplyr::select(`Participant ID`, Sex, `Participant age`,BMI, Dose,`Fat in kg`,`LBM in kg`,
          `Fat %`, `LBM in %`)
         
gender_data<-gender_data%>%
  rename("ID"= `Participant ID`)

#select variables you will need in the next data set
immune_data<-Immunology_lab_results%>%
  dplyr::select(ID,`CD4+`, `CD4 Immune activation count`)

#we can now merge the two data sets int one.
Tb_immune_data<-full_join(gender_data, immune_data,by = "ID")

#let me first save this data set. i will save this data in the processed data
# folder since this is the data that i have cleaned and plan on using through
# out the annalysis.

save_data_location <- here::here("data","processed-data","Tb_immune_data.rds")
saveRDS(Tb_immune_data, file = save_data_location)

#dropping the last observation from the dataset since the last observation
#doesnt make sense to our annalysis 
#loading the data
data<- read_rds(save_data_location)

# dropping the last observation in the dataset since it makes no sense
# to our annalysis and also dropping the variable dose since we dont really need it.
data<- data[-61,-5] #dropped already. 

#Lets categorise age so we can have a clear picture of what is happening.
#first lets look at its 
summary(data$`Participant age`)
Final_data <- data %>%
  mutate(Age_cat = case_when(
    `Participant age` >= 17 & `Participant age` < 28 ~ 0,
    `Participant age` >= 28 & `Participant age` < 40 ~ 1,
    `Participant age` >= 40 & `Participant age` < 60 ~ 2,
    `Participant age` >= 60  ~ 3,  # for all graeter than 60
    TRUE ~ NA_real_  # Handles missing or unexpected values
  ))


##eXPLORATION OF OUR DATA.
#summary of the data
summary(Final_data)
#mean age is of the participants is 30, minimum age is 17 while the maax is 70

#saving the cleaned data
save_data_location <- here::here("data","processed-data","Final_data.rds")
saveRDS(Final_data, file = save_data_location)

table(Final_data$Sex) #There are 30 males and 30 females
table(Final_data$Age_cat)

##VISUALIZING THE VARIABLES IN THE Final_data
# creating a hists 
hist(Final_data$`CD4 Immune activation count`, main="Histogram of CD4 Counts",
     xlab="CD4 counts", col="blue") #histogram showing the cd4 counts

#CD4+
ggplot(Final_data, aes(x=`CD4+`)) + geom_histogram(binwidth=10, fill="blue", 
                                             color="black")

#LBM IN KG
ggplot(Final_data, aes(x=`LBM in kg`)) + geom_histogram(binwidth=10, fill="red", 
                                             color="black")
##sexDistributions
ggplot(Final_data, aes(x=factor(Sex), y= `LBM in kg`)) +
  geom_boxplot(fill="lightblue") +
  theme_minimal()

##checking for any correlations

library(corrplot)
cor_matrix <- cor(Final_data[sapply(Final_data, is.numeric)], use="complete.obs")
print(cor_matrix)

corrplot(cor_matrix, method="color", tl.cex=0.8)
#We see that none of the variabls are correlated with each other.

library(ggplot2)
library(GGally)
ggpairs(Final_data[, c("CD4+", "Fat in kg", "BMI", "Participant age")])


#Scatter plots of numeric variables
p1<-ggplot(Final_data, aes(x=`LBM in kg`
                 , y=`CD4+`)) + 
  geom_point(color="blue") + 
  geom_smooth(method="lm", col="red") +
  theme_minimal()
plot(p1)

figure_file = here("results","figures","Scatterplot1.png")
ggsave(filename = figure_file, plot=p1, width = 5, height = 3.7, dpi = 300)


##considering immune counts
ggplot(Final_data, aes(x=`LBM in kg`
                 , y=`CD4 Immune activation count`)) + 
  geom_point(color="blue") + 
  geom_smooth(method="lm", col="red") +
  theme_minimal()



#comparing fat to cd4
p2<-ggplot(Final_data, aes(x= `Fat in kg`
                 , y=`CD4+`)) + 
  geom_point(color="black") + 
  geom_smooth(method="lm", col="green") +
  theme_minimal()
plot(p2)
figure_file = here("results","figures","Scatterplot2.png")
ggsave(filename = figure_file, plot=p2, width = 5, height = 3.7, dpi = 300)
##immune activation counts
ggplot(Final_data, aes(x= `Fat in kg`
                 , y=`CD4 Immune activation count`)) + 
  geom_point(color="black") + 
  geom_smooth(method="lm", col="green") +
  theme_minimal()

##### other visualisations

p3<-ggplot(Final_data, aes(x = factor(Sex), y = `CD4 Immune activation count`, 
                 fill = factor(Sex))) +
  geom_boxplot() +
  labs(x = "Sex", y = "CD4 Count", title = "CD4 Count Distribution by Sex") +
  theme_minimal()
plot(p3)
figure_file = here("results","figures","boxplot1.png")
ggsave(filename = figure_file, plot=p3, width = 5, height = 4, dpi = 300)



p4<-ggplot(Final_data, aes(x = Sex, y = `Fat in kg`, fill = Sex)) +
  geom_boxplot() +
  theme_minimal() +
  ggtitle("Fat in kg by Sex")
plot(p4)
figure_file = here("results","figures","boxplot2.png")
ggsave(filename = figure_file, plot=p4, width = 5, height = 3.8, dpi = 300)

##Mean cd4 count by sex
ggplot(Final_data, aes(x = factor(Sex), y = `CD4 Immune activation count`, fill = factor(Sex))) +
  stat_summary(fun = mean, geom = "bar") +
  labs(x = "Sex", y = "Mean CD4 Count", title = "Mean CD4 Count by Sex") +
  theme_minimal()

#####RUNNING MODELS ON THE Final_data.
model <- lm(`CD4 Immune activation count` ~ relevel(factor(Sex), ref = "M")+ `Participant age`+ `Fat in kg` +`LBM in kg`, data = Final_data)
summary(model)

# Regression plot
ggplot(Final_data, aes(x = factor(Sex), y = `CD4 Immune activation count`, color = factor(Sex))) +
  geom_jitter(width = 0.2, alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Sex", y = "CD4 Count", title = "CD4 Count vs. Sex (Regression)") +
  theme_minimal()


####TABLES
######making a table with sex as our exposure.
#installing the required packages for the tables.
# Load required packages
#install.packages("table1")  # Install if not already installed
#install.packages("gtsummary")

#descriptive statistics table with Sex as the exposure:
TABLE1<-table1(~ `CD4+`+`CD4 Immune activation count` + `Participant age` + `Fat in kg` 
       + `LBM in kg` | Sex, data = Final_data)
TABLE1
save_tabel1<- here::here("results","tables", "TABLE1.rds")
saveRDS(TABLE1,file =save_tabel1 )



#table version 2, correlation table
# Load necessary packages

library(gt)
library(tibble)
# Select numeric variables
cor_data <- Final_data %>%
  select(`CD4+`, `CD4 Immune activation count`, `Fat in kg`, `LBM in kg`, `Participant age`, BMI)

# Compute correlation matrix
cor_matrix <- round(cor(cor_data, use = "complete.obs"), 2)

# Convert to a data frame and make it prettier
cor_df <- as.data.frame(cor_matrix) %>%
  rownames_to_column("Variable")

# Format as a gt table
cor_table <- gt(cor_df) %>%
  tab_header(title = "Table 2: Correlation Matrix of Immune Activation and Body Composition")
cor_table
# Save as RDS for use in Quarto
saveRDS(cor_table, file = here("results", "tables", "TABLE2_Correlation.rds"))





# t-tests to compare means between sexes
t.test(`CD4 Immune activation count` ~ Sex, data = Final_data)
t.test(`Fat in kg`~ Sex, data = Final_data)



#simple models with one predictor.
#since sex is our major exposure of interst, we shall consider it first and then 
#see how our outcome performs with it. we shall first see how this goes.
model1 <- lm(`CD4+` ~ relevel(factor(Sex), ref = "F"), data = Final_data)
summary(model1)
#lets try it with the males as our reference group
model2 <- lm(`CD4+` ~ relevel(factor(Sex), ref = "M"), data = Final_data)
summary(model2)

#Using cd4 immune activation count .
model3 <- lm(`CD4 Immune activation count` ~ relevel(factor(Sex), ref = "F") + 
               BMI + `LBM in kg`  , data = Final_data)

model_summary <- summary(model3)
model_summary
confint(model3)
model_table1 <- as.data.frame(model_summary$coefficients)
knitr::kable(model_table1)


save_table2<-here::here("results","tables", "model_table1.rds")
saveRDS(model_table1,file =save_table2 )

#lets try to improve the model and also control for confounders. 


model4 <- lm(`CD4 Immune activation count`~ relevel(factor(Sex), ref = "F") +
               `Participant age` + BMI + `LBM in kg` + `Fat in kg` + `CD4+`,
            data = Final_data)
 summary(model4)
model_summary2 <- summary(model4)
model_table2 <- as.data.frame(model_summary2$coefficients)
knitr::kable(model_table2)


save_table3<-here::here("results","tables", "model_table2.rds")
saveRDS(model_table2,file =save_table3 )
#since we have our full model, lets try to perform a step wise selection procedure
#to see which model will perform better.

# First, fit your full model with all predictors so that we can see whether it is 
#relevant for us to have all these predictors or not.
model4 <- lm(`CD4 Immune activation count` ~ relevel(factor(Sex), ref = "F") + 
                   `Participant age` + BMI + `LBM in kg` + `Fat in kg` + `CD4+`,
                 data = Final_data)
#then lets have a null model
# Create the null model (intercept only)
null_model <- lm(`CD4 Immune activation count` ~ relevel(factor(Sex), ref = "F"), data = Final_data)

# Perform forward stepwise selection
library(MASS) # we shall need this package to perform a step aic for model selection.
forward_model <- stepAIC(null_model, 
                      scope = list(lower = null_model, upper = model4),
                      direction = "forward")
#we maintained the sex variable in the null model because it our main predictor and we dont
#want to lose it.

# View the summary of the selected model
summary(forward_model)

#what if i wanted to take into account the interaction effects
# Define full model with interactions
full_model_with_interactions <- lm(`CD4 Immune activation count` ~ 
                                     (relevel(factor(Sex), ref = "F") + 
                                        `Participant age` + BMI + `LBM in kg` + 
                                        `Fat in kg` + `CD4+`)^2,  # The ^2 adds all 2-way interactions
                                   data = Final_data)

# Perform forward stepwise selection with interactions
forward_model_interactions <- step(null_model, 
                                   scope = list(lower = null_model, 
                                                upper = full_model_with_interactions),
                                   direction = "forward")
summary(forward_model_interactions )
#this means the interaction effects do not contribute to the model performance a
#and hence there is no need of adding them.

#from the above, we notice that adding very many predictors did not necessarily 
#improve the model. hence we ended up just maintain the cd4 count and sex as 
#our main predictors.
model_summary3 <- summary(forward_model)
model_table3 <- as.data.frame(model_summary3$coefficients)

knitr::kable(model_table3)


save_table3<-here::here("results","tables", "model_table3.rds")
saveRDS(model_table3,file =save_table3 )

#lets try using the ml model_table1. load the necessary packages.
library(glmnet)       # For LASSO regression
library(ranger)
library(recipes)
library(tidymodels)  
library(car)
# . Set random seed for reproducibility
set.seed(1234)
rngseed <- 1234

# Fix column names
colnames(Final_data) <- make.names(colnames(Final_data))

# Impute missing response if needed
Final_data$CD4.Immune.activation.count[is.na(Final_data$CD4.Immune.activation.count)] <- 
  median(Final_data$CD4.Immune.activation.count, na.rm = TRUE)

Final_data <- Final_data %>% dplyr::select(-ID)

#we have decided to impute them since this individual has other values that are
#important in our annalysis.

# Recipe
model_recipe <- recipe(CD4.Immune.activation.count ~ ., data = Final_data) %>%
  step_impute_mean(all_numeric_predictors()) %>%
  step_impute_mode(all_nominal_predictors()) %>%
  step_dummy(all_nominal_predictors()) %>%
  step_corr(all_numeric_predictors(), threshold = 0.9) %>%
  step_normalize(all_numeric_predictors())

lasso_model <- linear_reg(penalty = tune(), mixture = 1) %>%
  set_engine("glmnet")

lasso_workflow <- workflow() %>%
  add_model(lasso_model) %>%
  add_recipe(model_recipe)

# Penalty grid
lasso_grid <- tibble(penalty = 10^seq(-5, 2, length.out = 50))

# 5x5 CV
cv_folds <- vfold_cv(Final_data, v = 5, repeats = 5)

# Tune
lasso_results <- tune_grid(
  lasso_workflow,
  resamples = cv_folds,
  grid = lasso_grid,
  metrics = metric_set(rmse)
)

# Best penalty
best_lasso <- select_best(lasso_results, metric = "rmse")

# Finalize and fit
final_lasso <- finalize_workflow(lasso_workflow, best_lasso)
final_lasso_fit <- fit(final_lasso, Final_data)

# Coefficients
lasso_coeffs <- tidy(final_lasso_fit)
print(lasso_coeffs)

#using random forest tuning and fitting
rf_model <- rand_forest(
  mtry = tune(),
  min_n = tune(),
  trees = 500
) %>%
  set_engine("ranger", importance = "impurity", seed = 1234) %>%
  set_mode("regression")

rf_workflow <- workflow() %>%
  add_model(rf_model) %>%
  add_recipe(model_recipe)

rf_grid <- grid_regular(
  mtry(range = c(1, 6)),
  min_n(range = c(1, 20)),
  levels = 5
)

rf_results <- tune_grid(
  rf_workflow,
  resamples = cv_folds,
  grid = rf_grid,
  metrics = metric_set(rmse)
)

# Best parameters
best_rf <- select_best(rf_results, metric= "rmse")

# Finalize and fit
final_rf <- finalize_workflow(rf_workflow, best_rf)
final_rf_fit <- fit(final_rf, Final_data)

##we need to get the variable importance from the underlying fitted model

rf_final_model <- extract_fit_parsnip(final_rf_fit)$fit
importance_df <- data.frame(
  Variable = names(rf_final_model$variable.importance),
  Importance = rf_final_model$variable.importance
)

variable_plot<-ggplot(importance_df, aes(x = reorder(Variable, Importance), y = Importance)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(title = "Variable Importance in Random Forest Model", 
       x = "Predictor", 
       y = "Importance Score")

variable_plot

ggsave(here("results", "figures", "Variable_plot.png"),
       plot = variable_plot, width = 8, height = 4, dpi = 300)


#Getting predictions from the random forests model and the lasso model to see
#which one has better perfomance.
# Make predictions
lasso_preds <- predict(final_lasso_fit, new_data = Final_data) %>%
  bind_cols(Final_data %>% dplyr::select(CD4.Immune.activation.count))

rf_preds <- predict(final_rf_fit, new_data = Final_data) %>%
  bind_cols(Final_data %>% dplyr::select(CD4.Immune.activation.count))

# RMSE
lasso_rmse <- rmse(lasso_preds, truth = CD4.Immune.activation.count, estimate = .pred)
rf_rmse <- rmse(rf_preds, truth = CD4.Immune.activation.count, estimate = .pred)

print(lasso_rmse)
print(rf_rmse)

#This shows that the random forests model is predicting better compared to 
#the lasso model. It is capturing more data points than the lasso model.


# Plotting the predicted over the observed.
plot_obs_vs_pred <- function(data, title) {
  ggplot(data, aes(x = CD4.Immune.activation.count, y = .pred)) +
    geom_point(alpha = 0.5) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "blue") +
    labs(title = title, x = "Observed", y = "Predicted") +
    theme_minimal()
}
library(patchwork)
combined_plot <- plot_obs_vs_pred(lasso_preds, "LASSO") +
  plot_obs_vs_pred(rf_preds, "Random Forest")
combined_plot
ggsave(here("results", "figures", "Predicted_vs_Observed.png"),
       plot = combined_plot, width = 8, height = 4, dpi = 300)

