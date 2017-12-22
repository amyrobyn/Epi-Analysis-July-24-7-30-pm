#sensitivity of clinician vs lab
library(haven)
library(tibble)
library(caret)

data_outcome_collapsed <- read_dta("C:/Users/amykr/OneDrive/epi analysis/data/data_outcome_collapsed.dta")
glimpse(data_outcome_collapsed)
attach(data_outcome_collapsed)

table(outcome_collapsed, Lab_result)

data_outcome_collapsed$clinical<-NA
data_outcome_collapsed <- within(data_outcome_collapsed, clinical[outcome_collapsed=="Dengue"] <- 1)
data_outcome_collapsed <- within(data_outcome_collapsed, clinical[outcome_collapsed=="Severe Dengue"] <- 1)
data_outcome_collapsed <- within(data_outcome_collapsed, clinical[outcome_collapsed=="Chikungunya"] <- 0)
data_outcome_collapsed <- within(data_outcome_collapsed, clinical[outcome_collapsed=="Zika"] <- 0)
table(data_outcome_collapsed$clinical)

table(data_outcome_collapsed$prueba)
data_outcome_collapsed$dengue_test<-"0"
data_outcome_collapsed <- within(data_outcome_collapsed, dengue_test[prueba=="E0"] <- "NS1")
data_outcome_collapsed <- within(data_outcome_collapsed, dengue_test[prueba=="4"] <- "PCR")
data_outcome_collapsed <- within(data_outcome_collapsed, dengue_test[prueba=="2"] <- "IGM")
data_outcome_collapsed <- within(data_outcome_collapsed, dengue_test[prueba=="3"] <- "IGG")
data_outcome_collapsed <- within(data_outcome_collapsed, dengue_test[prueba=="5"] <- "viral isolation")
table(data_outcome_collapsed$dengue_test)

#all dengue
#all lab test
data_outcome_collapsed$neg_pos_lab<-NA
data_outcome_collapsed <- within(data_outcome_collapsed, neg_pos_lab[Lab_result=="Positive"] <- 1)
data_outcome_collapsed <- within(data_outcome_collapsed, neg_pos_lab[Lab_result=="Negative"] <- 0)
confusionMatrix(data_outcome_collapsed$clinical, data_outcome_collapsed$neg_pos_lab,  positive="1")


#igm
data_outcome_collapsed$igm_pos_neg<-NA
data_outcome_collapsed <- within(data_outcome_collapsed, igm_pos_neg[dengue_test=="IGM" & neg_pos_lab ==1] <- 1)
data_outcome_collapsed <- within(data_outcome_collapsed, igm_pos_neg[dengue_test=="IGM" & neg_pos_lab ==0] <- 0)
table(data_outcome_collapsed$igm_pos_neg, data_outcome_collapsed$clinical)
confusionMatrix(data_outcome_collapsed$clinical, data_outcome_collapsed$igm_pos_neg,  positive="1")


#PCR
data_outcome_collapsed$pcr_pos_neg<-NA
data_outcome_collapsed <- within(data_outcome_collapsed, pcr_pos_neg[dengue_test=="PCR" & neg_pos_lab ==1] <- 1)
data_outcome_collapsed <- within(data_outcome_collapsed, pcr_pos_neg[dengue_test=="PCR" & neg_pos_lab ==0] <- 0)
confusionMatrix(data_outcome_collapsed$clinical, data_outcome_collapsed$pcr_pos_neg,  positive="1")

#igg
data_outcome_collapsed$igg_pos_neg<-NA
data_outcome_collapsed <- within(data_outcome_collapsed, igg_pos_neg[dengue_test=="IGG" & neg_pos_lab ==1] <- 1)
data_outcome_collapsed <- within(data_outcome_collapsed, igg_pos_neg[dengue_test=="IGG" & neg_pos_lab ==0] <- 0)
confusionMatrix(data_outcome_collapsed$clinical, data_outcome_collapsed$igg_pos_neg,  positive="1")

#ns1
data_outcome_collapsed$ns1_pos_neg<-NA
data_outcome_collapsed <- within(data_outcome_collapsed, ns1_pos_neg[dengue_test=="NS1" & neg_pos_lab ==1] <- 1)
data_outcome_collapsed <- within(data_outcome_collapsed, ns1_pos_neg[dengue_test=="NS1" & neg_pos_lab ==0] <- 0)
confusionMatrix(data_outcome_collapsed$clinical, data_outcome_collapsed$ns1_pos_neg,  positive="1")




#severe dengue
#all lab test
data_outcome_collapsed$clinical_severe<-NA
data_outcome_collapsed <- within(data_outcome_collapsed, clinical_severe[outcome_collapsed=="Severe Dengue"] <- 1)
data_outcome_collapsed <- within(data_outcome_collapsed, clinical_severe[outcome_collapsed=="Chikungunya"] <- 0)
data_outcome_collapsed <- within(data_outcome_collapsed, clinical_severe[outcome_collapsed=="Zika"] <- 0)
confusionMatrix(data_outcome_collapsed$clinical_severe, data_outcome_collapsed$neg_pos_lab,  positive="1")

#igm
confusionMatrix(data_outcome_collapsed$clinical_severe, data_outcome_collapsed$igm_pos_neg,  positive="1")


#PCR
confusionMatrix(data_outcome_collapsed$clinical_severe, data_outcome_collapsed$pcr_pos_neg,  positive="1")

#igg
confusionMatrix(data_outcome_collapsed$clinical_severe, data_outcome_collapsed$igg_pos_neg,  positive="1")

#ns1
confusionMatrix(data_outcome_collapsed$clinical_severe, data_outcome_collapsed$ns1_pos_neg,  positive="1")
table(data_outcome_collapsed$clinical_severe)


dengue<-data_outcome_collapsed[which(data_outcome_collapsed$outcome_collapsed=='Dengue' | data_outcome_collapsed$outcome_collapsed=='Severe Dengue')  , ]
