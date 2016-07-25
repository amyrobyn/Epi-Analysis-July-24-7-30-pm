/****************************************************
 *Amy Krystosik                  					*
 *chikv, dengue, and zika in cali, colombia       	*
 *PHD dissertation- epi analysis only               *
 *last updated 7:24PM July 24, 2016 
 * FILE NAME: epi_analysis_only_7-18PM_July_24_2016.do* 
 ***************************************************/
cd "C:\Users\Amy\OneDrive\epi analysis" 

use "C:\Users\Amy\OneDrive\epi analysis\temp.dta", clear

capture log close 
log using "epi_analysis_only_7-18PM_July_24_2016.smcl", text replace 
set scrollbufsize 100000
set more 1


**delete repeat observatrions (same id within one week).
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
	drop direccion dir_res_ freq_cedula4 freq_cedula2 ID_CODE localidad_ nom_upgd ndep_proce nmun_proce ndep_resi nmun_resi COD_COMUNA AREA PERIMETRO estrato_mo ACUERDO LIMITES dengue dengue_status dengue_death1 dengue_death2 dengue_death3 dengue_death4 chkv_status country append_merged direcionjavier cod_pre cod_sub pri_nom_ seg_nom_ pri_ape_ seg_ape_ tip_ide_ cod_pais_o cod_dpto_o cod_mun_o area_ cen_pobla_ vereda_ tip_ss_ cod_ase_ cod_dpto_r cod_mun_r fec_con_ tip_cas_ tip_cas_num fec_hos_ con_fin_ fec_def_ ajuste_ adjustment_num telefono_ cer_def_ cbmte_ nuni_modif fec_arc_xl nom_dil_f_ tel_dil_f_ fec_aju_ fm_fuerza fm_unidad fm_grado nmun_notif ndep_notif nreg chikv2015 control fec_exp nit_upgd cod_mun_d famantdngu direclabor fiebre cefalea dolrretroo malgias artralgia erupcionr dolor_abdo vomito diarrea somnolenci hipotensio hepatomeg hem_mucosa hipotermia caida_plaq acum_liqui aum_hemato extravasac hemorr_hem choque dao_organ muesttejid mueshigado muesbazo muespulmon muescerebr muesmiocar muesmedula muesrion classfinal_num conducta append20142015 merged sex1 sex2 freq_cedula dup

*export raw data
	save "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\dengue_chikv_oct2014-oct2015_cali.dta", replace
	save "dengue_chikv_oct2014-oct2015_cali.dta", replace
	export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\dengue_chikv_zika_oct2014-abril2016_cali.xls", firstrow(variables) replace
	export excel using "dengue_chikv_zika_oct2014-abril2016_cali.xls", firstrow(variables) sheet("sheet1") replace

*export the new addresses for javier/*export for secretary of healtlh geocoding
	export excel CODIGO ID_CODE direccion dir_res_ barrio ID_BARRIO using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\direcciones_krystosik_5mayo2016B", firstrow(variables) replace
	export excel CODIGO ID_CODE direccion dir_res_ barrio ID_BARRIO using "direcciones_krystosik_5mayo2016B", firstrow(variables) sheet("sheet1") replace


	
****************************************************************incidence****************************************************************
	*pop standardization incidence by agecatepi and sex***
		import excel "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\population\population year sex cali_epiagecats.xls", sheet("Sheet1") firstrow clear
		tostring stratavar_age, replace
		collapse (sum) popvar, by(stratavars_year stratavars_female stratavar_age)

		gen popvar_weighted_epiagecats = .
		replace popvar_weighted_epiagecats= popvar*(14/52) if stratavars_year == 2014
		replace popvar_weighted_epiagecats= popvar if stratavars_year == 2015
		replace popvar_weighted_epiagecats= popvar*(12/52) if stratavars_year == 2016

		gen popvar_weighted_epiagecats_chik = .
		replace popvar_weighted_epiagecats_chik = popvar*(1/20)
		replace popvar_weighted_epiagecats_chik = popvar_weighted_epiagecats_chik*(14/52) if stratavars_year == 2014
		replace popvar_weighted_epiagecats_chik = popvar_weighted_epiagecats_chik*(12/52) if stratavars_year == 2016

		rename stratavars_year anos 
		rename stratavars_female female 
		rename stratavar_age edad_cat_epi 

		save "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\population\population year sex cali_epiagecats.dta", replace

		use "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\origionals\dengue_chikv_oct2014-oct2015_cali.dta", replace
		tostring Age_Categories, replace
		destring anos, replace
		tostring edad_cat_epi, replace
		merge m:1 anos female edad_cat_epi using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\population\population year sex cali_epiagecats.dta"
		save "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\population_cases_epiagecats.dta", replace

	*crude incidence table by age
		gen casecount = 1
		gen crudeincidence = .
		replace crudeincidence = casecount/ popvar
		export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\arcgis analysis\gwr models\cases_incidence.xls", firstrow(variables) replace 

		egen crudeincidencesum = sum(crudeincidence), by(anos Sex Age_Categories nom_eve)
		collapse (mean) crudeincidencesum, by(anos Sex Age_Categories nom_eve)
		gen crudeincidence1000000 = crudeincidencesum*100000
		*bysort nom_eve stratavars_year stratavars_female stratavar_age: tab crudeincidence1000000
		export excel using "C:\Users\Amy\OneDrive\epi analysis\incidence.xls", firstrow(variables) replace 

************pop weighted incidence table by age****************
	use "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\population_cases.dta", replace
		gen casecount = 1
		gen incidenceweighted = .
		replace incidenceweighted = casecount/ popvar_weighted
		replace incidenceweighted = casecount/ popvar_weighted_chik if nom_eve == "Chikungunya" & anos == 2014
		replace incidenceweighted = casecount/ popvar_weighted_chik if nom_eve == "Chikungunya" & anos == 2015 & semana <= 45

*confirmed vs suspected dengue by death, severe, non-severe
	tab resultado, gen(result)
	gen confirmed = .
	replace confirmed = 1 if result1 ==1 
	replace confirmed = 0 if result1 == .  
	replace confirmed = 0 if result1 != 1 & nom_eve == "Dengue" 
	replace confirmed = 0 if result1 != 1 & nom_eve == "Severe Dengue" 
	replace confirmed = 0 if result1 != 1 & nom_eve == "Dengue Death" 

*create labels for lab positive vs negative
		gen Lab_result = "."
		replace Lab_result = "Positive" if resultado=="1" 
		replace Lab_result = "Negative" if resultado== "2"  
		replace Lab_result = "Not processed" if resultado== "3" 
		replace Lab_result = "Inadequate" if resultado== "4" 
		replace Lab_result = "Doubtfull" if resultado== "5" 
		replace Lab_result = "Value registered" if resultado== "6"
		replace Lab_result = "Compatible" if resultado== "7" 
		replace Lab_result = "Non-Reactive" if resultado== "11"
		replace Lab_result = "Not Compatible" if resultado== "15" 
		replace Lab_result = "Undefined" if resultado== "20"  
		replace Lab_result = "No Data" if resultado== ""  
		tab Lab_result, missing
		 
*make variables that allows us to look where values are females missing pregnancy values versus males.
	egen pregnant_females = concat(pregnant Sex)

*dengue collapsed (dengue grave and dengue death)
	gen outcome_collapsed = ""
	replace outcome_collapsed = "Dengue" if nom_eve =="Dengue" 
	replace outcome_collapsed = "Severe Dengue" if nom_eve =="Dengue Death" 
	replace outcome_collapsed = "Severe Dengue" if nom_eve == "Severe Dengue"
	replace outcome_collapsed = "Zika" if nom_eve =="Zika" 
	replace outcome_collapsed = "Chikungunya" if nom_eve =="Chikungunya"

*create collapsed outcome category of chikv and dengue without and with severity and grave and death. 
	gen outcome_collapsed_2 = .
	*outcome = 1 for dengue without warning
	replace outcome_collapsed_2 =1 if outcome ==1
	*outcome = 2 for dengue with warning signs
	replace outcome_collapsed_2 =2 if outcome == 2
	*outcome = 3 for dengue grave
	replace outcome_collapsed_2 = 3 if outcome == 3
	*outcome = 3 for dengue death
	replace outcome_collapsed_2 = 3 if outcome == 4 
	*outcome = 5 for dengue unclassified
	replace outcome_collapsed_2  =5 if outcome == 5 
	*outcome = 6 for chikungunya 
	replace outcome_collapsed_2 = 6 if  outcome == 6 
	*outcome = 7  for zika
	replace outcome_collapsed_2 = 7 if outcome == 7 

*tables with collapsed (dengue grave and dengue death) outcome with and without the strata for dengue with warning signs.
	table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \confirmed cat \Lab_result  cat\ Disabled cat \ Displaced cat \migrant cat \ pregnant cat \ pregnant_females cat \ youth_government_care cat \ Community_mother cat \ ex_paramil_ex_guerilla cat \ under_psychiatric_care cat \ other_group cat \ violence_victims cat) by(outcome_collapsed) saving("table1_outcome_collapsed.xls", replace ) missing 
	table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \confirmed cat \Lab_result  cat\ Disabled cat \ Displaced cat \migrant cat \ pregnant cat \ pregnant_females cat \ youth_government_care cat \ Community_mother cat \ ex_paramil_ex_guerilla cat \ under_psychiatric_care cat \ other_group cat \ violence_victims cat) by(outcome_collapsed_2) saving("table1_outcome_collapsed.xls", replace ) missing 
*table 1 for all cases by outcome where nom event is: Chikungunya	Dengue	Severe Dengue & Mortality	Zika
	table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \confirmed cat \Lab_result  cat\ Disabled cat \ Displaced cat \migrant cat \ pregnant cat \ pregnant_females cat \ youth_government_care cat \ Community_mother cat \ ex_paramil_ex_guerilla cat \ under_psychiatric_care cat \ other_group cat \ violence_victims cat) by(nom_eve) saving("C:\Users\Amy\OneDrive\epi analysis\table1_nom_eve_confirmed.xls", replace) missing test
*table 1 for all cases by outcome where 0 is chkv, 1 is dengue without warning signs, 2 is dengue with warning signs, 3 is denuge grave, 4 is dengue death
	table1, vars(Age_Categories cat\ Sex cat \ ethnicity cat \confirmed cat \Lab_result  cat\ Disabled cat \ Displaced cat \migrant cat \ pregnant cat \ pregnant_females cat \ youth_government_care cat \ Community_mother cat \ ex_paramil_ex_guerilla cat \ under_psychiatric_care cat \ other_group cat \ violence_victims cat) by(outcome) saving("C:\Users\Amy\OneDrive\epi analysis\table1_OUTCOME_confirmed.xls", replace) missing test 

save "temp2.dta", replace


*table incidence table with f to m ratios for nom_eve
	use temp2.dta, clear
		egen weightedincidencesum = sum(incidenceweighted), by(anos Sex Age_Categories outcome_collapsed)
		collapse (mean) weightedincidencesum, by(anos Sex Age_Categories outcome_collapsed confirmed Lab_result)
		gen weightedincidence1000000 = weightedincidencesum*100000
		export excel using "C:\Users\Amy\OneDrive\epi analysis\weightedincidencecollapased.xls", firstrow(variables) replace 
		bysort outcome_collapsed anos Age_Categories: gen weightedincidencemale = weightedincidence1000000 if Sex=="M"
		bysort outcome_collapsed anos Age_Categories: gen weightedincidencefemale = weightedincidence1000000 if Sex=="F"
		collapse (firstnm) weightedincidencemale  weightedincidencefemale , by(anos Age_Categories outcome_collapsed)
		bysort outcome_collapsed anos Age_Categories: gen ratioftom = weightedincidencefemale/weightedincidencemale
		gen lower = .
		replace lower = ratioftom - 1.96*sqrt((1/weightedincidencemale)  + (1/weightedincidencefemale))
		gen upper = .
		replace upper = ratioftom + 1.96*sqrt((1/weightedincidencemale)  + (1/weightedincidencefemale))
	export excel using "C:\Users\Amy\OneDrive\epi analysis\weightedincidenceratioscollapsed.xls", firstrow(variables) replace 

*table incidence table with f to m ratios for outcome_collapsed
	use temp2.dta, clear
		egen weightedincidencesum = sum(incidenceweighted), by(anos Sex Age_Categories outcome_collapsed)
		collapse (mean) weightedincidencesum, by(anos Sex Age_Categories outcome_collapsed confirmed Lab_result)
		gen weightedincidence1000000 = weightedincidencesum*100000
		bysort outcome_collapsed anos Age_Categories: gen weightedincidencemale = weightedincidence1000000 if Sex=="M"
		bysort outcome_collapsed anos Age_Categories: gen weightedincidencefemale = weightedincidence1000000 if Sex=="F"
		collapse (firstnm) weightedincidencemale  weightedincidencefemale , by(anos Age_Categories outcome_collapsed)
		bysort outcome_collapsed anos Age_Categories: gen ratioftom = weightedincidencefemale/weightedincidencemale
		gen lower = .
		replace lower = ratioftom - 1.96*sqrt((1/weightedincidencemale)  + (1/weightedincidencefemale))
		gen upper = .
		replace upper = ratioftom + 1.96*sqrt((1/weightedincidencemale)  + (1/weightedincidencefemale))
	export excel using "C:\Users\Amy\OneDrive\epi analysis\weightedincidenceratiosoutcome_collapsed.xls", firstrow(variables) replace

*use regular expressions to select the dates by format and then put all of them in the same format so i can subtract one from the other. 
	use temp2.dta, clear
	*concat some variable categories of interest
		egen diseaseyear = concat(anos nom_eve)
		egen diseaseyearsex = concat(anos nom_eve Sex)
		egen diseaseconfirmed= concat(nom_eve confirmed)
		*egen diseaseyear = concat(ano nom_eve)

	*quarters*
		gen quarter = .
		replace quarter = 1 if semana <= 13
		replace quarter = 2 if semana >13 & semana<= 26
		replace quarter = 3 if semana >26 & semana <= 39
		replace quarter = 4 if semana >39


	*export raw data
		export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\data\municipal data\dengue_chikv_zika_oct2014-abril2016_cali", firstrow(variables) replace
		export excel using "dengue_chikv_zika_oct2014-abril2016_cali", firstrow(variables) replace
	save "temp3.dta", replace

****incidence per 100,000 by barrio*****
		*pop standardization incidence
		*make population by barrio dataset.
			import excel "C:\Users\Amy\OneDrive\epi analysis\population\population bario cali.xls", sheet("barrio sex") firstrow clear
		*tostring stratavar_age, replace
			gen popvar_weighted_chik_barrio = .
			replace popvar_weighted_chik_barrio = Population
			gen str4 ID_barrio4 = string(ID_BARRIO,"%04.0f")
			save "C:\Users\Amy\OneDrive\epi analysis\population\population bario cali.dta", replace
		save "population bario cali.dta", replace

**use the cases spatially merged to barrio from arcgis becuase not all data has barrio from sec of health. 
	*chikv*
		import excel "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\chikvprojected_barrio.xls", sheet("chikvprojected_barrio") firstrow clear
		save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barrios_chikv_TableToExcel.dta", replace
		save "barrios_chikv_TableToExcel.dta", replace
			destring ID_BARRIO, replace
			gen str4 ID_barrio4 = string(ID_BARRIO,"%04.0f")
			merge m:1 ID_barrio4 using "C:\Users\Amy\OneDrive\epi analysis\population\population bario cali.dta"
			save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barriopopulation_chikv.dta", replace
			save "barriopopulation_chikv.dta", replace
			*crude incidence table by age and barrio
			gen casecount_barrio = 1
			gen crudeincidence_barrio = .
			replace crudeincidence_barrio = casecount/Population
			replace crudeincidence_barrio= casecount/ popvar_weighted_chik_barrio
			gen incidence =.
			replace incidence= casecount/popvar_weighted_chik_barrio
			export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\arcgis analysis\gwr models\chikv_incidence_population_GWR.xls", firstrow(variables) replace
			egen crudeincidence_barriosum = sum(crudeincidence_barrio), by(ID_barrio4)
			collapse (mean) crudeincidence_barriosum, by(ID_barrio4) 
			gen crudeincidence_barriosum1000000 = crudeincidence_barriosum*100000
		*bysort nom_eve ID_BARRIO: tab crudeincidence_barriosum1000000
			export excel using "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\chikv_barrio.xls", firstrow(variables) replace 
			export excel using "chikv_barrio.xls", firstrow(variables) replace 

	*dengue*
		import excel "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\dengue_projected_barrio.xls", sheet("dengue_projected_barrio") firstrow clear
		save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barrios_dengue_TableToExcel.dta", replace
		save "barrios_dengue_TableToExcel.dta", replace
				destring ID_BARRIO, replace
				gen str4 ID_barrio4 = string(ID_BARRIO,"%04.0f")
				merge m:1 ID_barrio4 using "C:\Users\Amy\OneDrive\epi analysis\population\population bario cali.dta"
				save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barriopopulation_dengue.dta", replace
				save "barriopopulation_dengue.dta", replace
			*crude incidence table by age and barrio
				gen casecount_barrio = 1
				gen crudeincidence_barrio = .
				replace crudeincidence_barrio = casecount/Population
				gen incidence =.
				replace incidence= casecount/Population
				export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\arcgis analysis\gwr models\dengue_incidence_population_GWR.xls", firstrow(variables) replace
			*replace crudeincidence_barrio= casecount/ popvar_weighted_chik_barrio if  Sheet1__nom_eve == 217
				egen crudeincidence_barriosum = sum(crudeincidence_barrio), by(ID_barrio4)
				collapse (mean) crudeincidence_barriosum, by(ID_barrio4) 
				gen crudeincidence_barriosum1000000 = crudeincidence_barriosum*100000
			*bysort nom_eve ID_BARRIO: tab crudeincidence_barriosum1000000
				export excel using "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\dengue_barrio.xls", firstrow(variables) replace 
				export excel using "dengue_barrio.xls", firstrow(variables) replace

		*zika*
				import excel "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\zikaprojected_barrio.xls", sheet("zikaprojected_barrio") firstrow clear
				save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barrios_zika_TableToExcel.dta", replace
				save "barrios_zika_TableToExcel.dta", replace
					destring ID_BARRIO, replace
					gen str4 ID_barrio4 = string(ID_BARRIO,"%04.0f")
					merge m:1 ID_barrio4 using "C:\Users\Amy\OneDrive\epi analysis\population\population bario cali.dta" 
				save "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\barriopopulation_zika.dta", replace
				save "barriopopulation_zika.dta", replace
			*crude incidence table by age and barrio
					gen casecount_barrio = 1
					gen crudeincidence_barrio = .
					replace crudeincidence_barrio = casecount/Population
					gen incidence =.
					replace incidence= casecount/Population
				export excel using "C:\Users\Amy\Google Drive\Kent\james\dissertation\chkv and dengue\arcgis analysis\gwr models\zika_incidence_population_GWR.xls", firstrow(variables) replace
			*replace crudeincidence_barrio= casecount/ popvar_weighted_chik_barrio if  Sheet1__nom_eve == 217
				egen crudeincidence_barriosum = sum(crudeincidence_barrio), by(ID_barrio4)
				collapse (mean) crudeincidence_barriosum, by(ID_barrio4) 
				gen crudeincidence_barriosum1000000 = crudeincidence_barriosum*100000
			*bysort nom_eve ID_BARRIO: tab crudeincidence_barriosum1000000
				export excel using "C:\Users\Amy\OneDrive\epi analysis\diseasebarrio\zika_barrio.xls", firstrow(variables) replace 
				export excel using "zika_barrio.xls", firstrow(variables) replace


	*******modeling*************
			use "temp3.dta", clear

			*convert barrio into numeric values
				encode barrio, generate(barrio2)
				encode fecha_nto_, generate(fecha_nto_2)

				mlogit outcome edad_cont female pregnant barrio2 fecha_nto_2
				mlogit outcome edad_cat_epi female pregnant barrio2 fecha_nto_2
