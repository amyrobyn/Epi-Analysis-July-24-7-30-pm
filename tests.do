
/****************************************************
 *Amy Krystosik                  					*
 *chikv, dengue, and zika in cali, colombia       	*
 *PHD dissertation                   				*
 *last updated July 7, 2016  						*
 ***************************************************/
cd "C:\Users\Amy\OneDrive\epi analysis" 
capture log close 
log using "dissertation.smcl", text replace 
*set scrollbufsize 100000
set more on

import excel "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\zikaprojected_barrio.xls", sheet("zikaprojected_barrio") firstrow clear
save "barrios_zika_TableToExcel.dta", replace
import excel "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\dengue_projected_barrio.xls", sheet("dengue_projected_barrio") firstrow clear
save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barrios_dengue_TableToExcel.dta", replace
import excel "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\chikvprojected_barrio.xls", sheet("chikvprojected_barrio") firstrow clear
save "barrios_chikv_TableToExcel.dta", replace
import excel "C:\Users\Amy\OneDrive\epi analysis\population\population bario cali.xls", sheet("barrio sex") firstrow clear
save "population bario cali.dta", replace
import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\population\population year sex cali_epiagecats.xls", sheet("Sheet1") firstrow clear
save "population year sex cali_epiagecats.dta", replace

use "C:\Users\Amy\OneDrive\epi analysis\epi.dta", clear

**delete repeat observatrions (same id within one week). here july 6
*data cleaning
*drop freq_cedula
bysort  num_ide_ fec_not nom_eve: gen freq_cedula = _N
sort num_ide_ fec_not nom_eve
drop dup
quietly by num_ide_ fec_not nom_eve:  gen dup = cond(_N==1,0,_n)
tabulate dup nom_eve
drop if dup > 0

rename  ID_CODE_merged CODIGO
order CODIGO
tostring CODIGO, replace

*drop variables we don't use in analysis
*drop direccion dir_res_ freq_cedula4 freq_cedula2 ID_CODE localidad_ nom_upgd ndep_proce nmun_proce ndep_resi nmun_resi COD_COMUNA AREA PERIMETRO estrato_mo ACUERDO LIMITES dengue dengue_status dengue_death1 dengue_death2 dengue_death3 dengue_death4 chkv_status country append_merged direcionjavier clasfinal cod_pre cod_sub pri_nom_ seg_nom_ pri_ape_ seg_ape_ tip_ide_ cod_pais_o cod_dpto_o cod_mun_o area_ cen_pobla_ vereda_ tip_ss_ cod_ase_ cod_dpto_r cod_mun_r fec_con_ tip_cas_ tip_cas_num fec_hos_ con_fin_ fec_def_ ajuste_ adjustment_num telefono_ cer_def_ cbmte_ nuni_modif fec_arc_xl nom_dil_f_ tel_dil_f_ fec_aju_ fm_fuerza fm_unidad fm_grado nmun_notif ndep_notif nreg chikv2015 control fec_exp nit_upgd cod_mun_d famantdngu direclabor fiebre cefalea dolrretroo malgias artralgia erupcionr dolor_abdo vomito diarrea somnolenci hipotensio hepatomeg hem_mucosa hipotermia caida_plaq acum_liqui aum_hemato extravasac hemorr_hem choque dao_organ muesttejid mueshigado muesbazo muespulmon muescerebr muesmiocar muesmedula muesrion classfinal_num conducta append20142015 merged sex1 sex2 freq_cedula dup
*export raw data
save "dengue_chikv_oct2014-oct2016_cali.dta", replace

*export the new addresses for javier/*export for secretary of healtlh geocoding
	*export excel CODIGO ID_CODE direccion dir_res_ barrio ID_BARRIO using "direcciones_krystosik_5mayo2016B", firstrow(variables) sheet("sheet1") sheetmodify 

**incidence**
*pop standardization incidence by agecatepi and sex. 
use "population year sex cali_epiagecats.dta", clear
tostring  edad_cat_epi, replace
collapse (sum) popvar, by(edad_cat_epi female anos)

gen popvar_weighted_epiagecats = .
replace popvar_weighted_epiagecats= popvar*(14/52) if anos== 2014
replace popvar_weighted_epiagecats= popvar if anos == 2015
replace popvar_weighted_epiagecats= popvar*(12/52) if anos == 2016

gen popvar_weighted_epiagecats_chik = .
replace popvar_weighted_epiagecats_chik = popvar*(1/20)
replace popvar_weighted_epiagecats_chik = popvar_weighted_epiagecats_chik*(14/52) if anos == 2014
replace popvar_weighted_epiagecats_chik = popvar_weighted_epiagecats_chik*(12/52) if anos == 2016

save "population year sex cali_epiagecats.dta", replace

use "dengue_chikv_oct2014-oct2016_cali.dta", replace
tostring Age_Categories, replace
destring anos, replace
tostring edad_cat_epi, replace
merge m:1 anos female edad_cat_epi using "population year sex cali_epiagecats.dta"
save "population_cases_epiagecats.dta", replace

*crude incidence table by age
gen casecount = 1
gen crudeincidence = .
replace crudeincidence = casecount/ popvar

egen crudeincidencesum = sum(crudeincidence), by(anos Sex Age_Categories nom_eve)
collapse (mean) crudeincidencesum, by(anos Sex Age_Categories nom_eve)
gen crudeincidence1000000 = crudeincidencesum*100000
*bysort nom_eve stratavars_year stratavars_female stratavar_age: tab crudeincidence1000000
	*export excel using "incidence.xls", firstrow(variables) sheet("sheet1") sheetmodify 

************pop weighted incidence table by age****************
*use "population_cases_epiagecats.dta", clear
*use "population_cases.dta", clear

gen casecount = 1
gen incidenceweighted = .
replace incidenceweighted = casecount/ popvar_weighted
replace incidenceweighted = casecount/ popvar_weighted_chik if nom_eve == "Chikungunya" & anos == 2014
replace incidenceweighted = casecount/ popvar_weighted_chik if nom_eve == "Chikungunya" & anos == 2015 & semana <= 45

*confirmed vs suspected
tab resultado, gen(result)
gen confirmed = .
replace confirmed = 1 if result1 ==1 
replace confirmed = 0 if result1 == .  
replace confirmed = 0 if result1 != 1 & nom_eve == "Dengue" 
replace confirmed = 0 if result1 != 1 & nom_eve == "Severe Dengue" 
replace confirmed = 0 if result1 != 1 & nom_eve == "Dengue Death" 

*lab positive vs negative
gen labpositive = .
replace labpositive = 1 if result1 ==1 
replace labpositive = 0 if result2 == 1  
replace labpositive = 0 if result3 == 1  
replace labpositive = 0 if result4 == 1  
replace labpositive = 0 if result5 == 1  
replace labpositive = 0 if result6 == 1  
replace labpositive = 0 if result7 == 1  
replace labpositive = 0 if result8 == 1  
replace labpositive = 0 if result9 == 1  
replace labpositive = 0 if result10 == 1  

egen pregnant_females = concat(pregnant Sex)
*table 1 for all cases by outcome where 0 is chkv, 1 is dengue without warning signs, 2 is dengue with warning signs, 3 is denuge grave, 4 is dengue death
table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \confirmed cat \labpositive cat\ Disabled cat \ Displaced cat \migrant cat \ pregnant cat \ pregnant_females cat \ youth_government_care cat \ Community_mother cat \ ex_paramil_ex_guerilla cat \ under_psychiatric_care cat \ other_group cat \ violence_victims cat) by(nom_eve) saving("table1_nom_eve_confirmed.xls", sheet("sheet1") sheetmodify ) missing 

*dengue collapsed
gen outcome_collapsed = ""
replace outcome_collapsed = "Dengue" if nom_eve =="Dengue" 
replace outcome_collapsed = "Severe Dengue" if nom_eve =="Dengue Death" 
replace outcome_collapsed = "Severe Dengue" if nom_eve == "Severe Dengue"
replace outcome_collapsed = "Zika" if nom_eve =="Zika" 
replace outcome_collapsed = "Chikungunya" if nom_eve =="Chikungunya"
table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \confirmed cat \labpositive cat\ Disabled cat \ Displaced cat \migrant cat \ pregnant cat \ pregnant_females cat \ youth_government_care cat \ Community_mother cat \ ex_paramil_ex_guerilla cat \ under_psychiatric_care cat \ other_group cat \ violence_victims cat) by(outcome_collapsed) saving("table1_outcome_collapsed.xls", sheet("sheet1") sheetmodify ) missing 
save temp.dta, replace

*table incidence table with f to m ratios for nom_eve
use temp.dta, clear
egen weightedincidencesum = sum(incidenceweighted), by(anos Sex Age_Categories nom_eve)
collapse (mean) weightedincidencesum, by(anos Sex Age_Categories nom_eve confirmed labpositive)
gen weightedincidence1000000 = weightedincidencesum*100000
bysort nom_eve anos Age_Categories: gen weightedincidencemale = weightedincidence1000000 if Sex=="M"
bysort nom_eve anos Age_Categories: gen weightedincidencefemale = weightedincidence1000000 if Sex=="F"
collapse (firstnm) weightedincidencemale  weightedincidencefemale , by(anos Age_Categories nom_eve)
bysort nom_eve anos Age_Categories: gen ratioftom = weightedincidencefemale/weightedincidencemale
gen lower = .
replace lower = ratioftom - 1.96*sqrt((1/weightedincidencemale)  + (1/weightedincidencefemale))
gen upper = .
replace upper = ratioftom + 1.96*sqrt((1/weightedincidencemale)  + (1/weightedincidencefemale))
	*export excel using "weightedincidenceratios.xls", firstrow(variables) sheet("sheet1") sheetmodify 

*table incidence table with f to m ratios for outcome_collapsed
use temp.dta, clear
egen weightedincidencesum = sum(incidenceweighted), by(anos Sex Age_Categories outcome_collapsed)
collapse (mean) weightedincidencesum, by(anos Sex Age_Categories outcome_collapsed confirmed labpositive)
gen weightedincidence1000000 = weightedincidencesum*100000
bysort outcome_collapsed anos Age_Categories: gen weightedincidencemale = weightedincidence1000000 if Sex=="M"
bysort outcome_collapsed anos Age_Categories: gen weightedincidencefemale = weightedincidence1000000 if Sex=="F"
collapse (firstnm) weightedincidencemale  weightedincidencefemale , by(anos Age_Categories outcome_collapsed)
bysort outcome_collapsed anos Age_Categories: gen ratioftom = weightedincidencefemale/weightedincidencemale
gen lower = .
replace lower = ratioftom - 1.96*sqrt((1/weightedincidencemale)  + (1/weightedincidencefemale))
gen upper = .
replace upper = ratioftom + 1.96*sqrt((1/weightedincidencemale)  + (1/weightedincidencefemale))
	*export excel using "weightedincidenceratiosoutcome_collapsed.xls", firstrow(variables) sheet("sheet1") sheetmodify 


use "temp.dta", clear
*use regular expressions to select the dates by format and then put all of them in the same format so i can subtract one from the other. 
egen diseaseyear = concat(anos nom_eve)
egen diseaseyearsex = concat(anos nom_eve Sex)
egen diseaseconfirmed= concat(nom_eve confirmed)
*egen diseaseyear = concat(ano nom_eve)

gen quarter = .
replace quarter = 1 if semana <= 13
replace quarter = 2 if semana >13 & semana<= 26
replace quarter = 3 if semana >26 & semana <= 39
replace quarter = 4 if semana >39

*export excel using "dengue_chikv_zika_oct2014-abril2016_cali", firstrow(variables) sheet("sheet1") sheetmodify 
save "dengue_chikv_zika_oct2014-abril2016_cali.dta", replace

****incidence per 100,000 by barrio*****
*pop standardization incidence
*make population by barrio dataset.
use "population bario cali.dta", clear
*tostring stratavar_age, replace
*gen popvar_weighted_chik_barrio = .
replace popvar_weighted_chik_barrio = Population
drop ID_barrio4 
gen str4 ID_barrio4 = string(ID_BARRIO,"%04.0f")
save "population bario cali.dta", replace

**use the cases spatially merged to barrio from arcgis becuase not all data has barrio from sec of health. 
*chikv*
use "barrios_chikv_TableToExcel.dta", replace
destring ID_BARRIO, replace
gen str4 ID_barrio4 = string(ID_BARRIO,"%04.0f")
merge m:1 ID_barrio4 using "population bario cali.dta"
save "barriopopulation_chikv.dta", replace
*crude incidence table by age and barrio
gen casecount_barrio = 1
gen crudeincidence_barrio = .
replace crudeincidence_barrio = casecount/Population
replace crudeincidence_barrio= casecount/ popvar_weighted_chik_barrio
egen crudeincidence_barriosum = sum(crudeincidence_barrio), by(ID_barrio4)
collapse (mean) crudeincidence_barriosum, by(ID_barrio4) 
gen crudeincidence_barriosum1000000 = crudeincidence_barriosum*100000
*bysort nom_eve ID_BARRIO: tab crudeincidence_barriosum1000000
	*export excel using "chikv_barrio.xls", firstrow(variables) sheet("sheet1") sheetmodify 

*dengue*
use "barrios_dengue_TableToExcel.dta", clear
destring ID_BARRIO, replace
gen str4 ID_barrio4 = string(ID_BARRIO,"%04.0f")
merge m:1 ID_barrio4 using "population bario cali.dta"
save "barriopopulation_dengue.dta", replace
*crude incidence table by age and barrio
gen casecount_barrio = 1
gen crudeincidence_barrio = .
replace crudeincidence_barrio = casecount/Population
*replace crudeincidence_barrio= casecount/ popvar_weighted_chik_barrio if  Sheet1__nom_eve == 217
egen crudeincidence_barriosum = sum(crudeincidence_barrio), by(ID_barrio4)
collapse (mean) crudeincidence_barriosum, by(ID_barrio4) 
gen crudeincidence_barriosum1000000 = crudeincidence_barriosum*100000
*bysort nom_eve ID_BARRIO: tab crudeincidence_barriosum1000000
	*export excel using "dengue_barrio.xls", firstrow(variables) sheet("sheet1") sheetmodify 

*zika*
use "barrios_zika_TableToExcel.dta", clear
destring ID_BARRIO, replace
gen str4 ID_barrio4 = string(ID_BARRIO,"%04.0f")
merge m:1 ID_barrio4 using "population bario cali.dta" 
save "barriopopulation_zika.dta", replace
*crude incidence table by age and barrio
gen casecount_barrio = 1
gen crudeincidence_barrio = .
replace crudeincidence_barrio = casecount/Population
*replace crudeincidence_barrio= casecount/ popvar_weighted_chik_barrio if  Sheet1__nom_eve == 217
egen crudeincidence_barriosum = sum(crudeincidence_barrio), by(ID_barrio4)
collapse (mean) crudeincidence_barriosum, by(ID_barrio4) 
gen crudeincidence_barriosum1000000 = crudeincidence_barriosum*100000

*bysort nom_eve ID_BARRIO: tab crudeincidence_barriosum1000000
	*export excel using "zika_barrio.xls", firstrow(variables) sheet("sheet1") sheetmodify 
