/*******************************************************************************
Project: 	head or heart
Purpose: 	creates database of expected id numbers at each fup
Author: 	Max Verfuerden
Created:	24.04.2017
Updates: 	01.10.2019 - added group allocation
*******************************************************************************/
*basics
qui do 		"S:\Head_or_Heart\max\attributes\2-Cleaning\00-global.do"
cd 			"$projectdir"
cap log 	close
log using 	"${logdir}\expected IDs $S_DATE.log", replace 
********************************************************************************
* start with master database and keep only ID sex fup variables
********************************************************************************
* I chose original preterm AB to be the master dataset (but could have been any)
use 		"${datadir}\origAB\origAB clinical clean.dta", clear
count		
keep		*id* *ID* sex* d_* fup* 
gen 		trial =.
replace		trial =1
save		"${datadir}\all\expected IDs.dta", replace
********************************************************************************
* add other databases and keep only ID d_dob sex fup variables
********************************************************************************
* iron
append		using "${datadir}\iron\iron_clean.dta", keep(*id* sex* d_* fup*)
count	
* lcpufa preterm
append		using "${datadir}\lcpufa_preterm\LCPUFA_preterm clinical to 18m_clean.dta", keep(*id* sex* d_* fup*)
count		
* lcpufa term
append		using "${datadir}\lcpufa_term\LCPUFA_term clinical vision 6y_clean.dta", keep(*id* sex* d_* fup*)
count		
* nucleotides
append		using "${datadir}\nucleotides\nucleotides clinical_clean.dta", keep(*id* sex* d_* fup*)
count		
* palmitate
append		using "${datadir}\palmitate aka betapol\palmitate clinical_clean.dta", keep(*id* *ID* sex* d_* fup*)
count		
* post discharge preterm
append		using "${datadir}\preterm postdischarge\preterm postdischarge_clean.dta", keep(*id* sex* d_* fup*)
count		
* sga term
append		using "${datadir}\sga_term\sga_term all clinical clean.dta", keep(*id* *ID* sex* d_* fup*)
count		
save		"${datadir}\all\expected IDs.dta", replace
count		
********************************************************************************
* harmonise variables
********************************************************************************
order		_all, alphab
* which trial does the participant belong to?
replace 	trial =1 	if sex_orig !=. // OAB
// no trial 2 because O A&B are together in one database
replace 	trial =3 	if sex_ppd !=.  // PDP
replace 	trial =4 	if sex_lcpre !=. | fup17y_lcpre !=. // LCPUFA preterm
replace 	trial =5 	if sex_lcterm !=. // LCPUFA term
replace 	trial =6 	if sex_nuc !="" // Nuc
replace 	trial =7 	if sex_iron !="" // Iron
replace 	trial =8 	if sex_sgaterm !=. // SGA term
replace 	trial =9 	if sex_palm !=.  // Palmitate term
lab def	trial1 1"OAB" 2"-" 3"PDP" 4"LCPUFA pret" 5"LCPUFA term" 6"NUC" 7"Iron" 8"SGA" 9"PAL" 
lab	val	trial trial1
tab trial, m
* sex
replace		sex_iron ="1" if sex_iron =="M"
replace		sex_iron ="2" if sex_iron =="F"
destring 	sex_iron sex_nuc, replace
gen			sex =.
foreach var of varlist sex_iron sex_lcglas sex_lcpre sex_lcterm sex_nuc sex_orig sex_palm sex_ppd sex_sgaglas sex_sgaterm {
replace		sex = 1 if `var' ==1
replace		sex = 2 if `var' ==2
}
drop 		sex_* sex2* sexr*
tabstat		sex, by(trial) s(mean min max)
* fup, check that I do not include 2 variables from same trial in same category which would loose information
gen			fup6w =.
foreach var of varlist fup6w_iron fup6w_lcglas fup6w_lcterm fup6w_palm fup6w_ppd fup6w_sgaterm {
replace		fup6w = `var' if `var' !=. & fup6w==.
}
drop		fup6w_*
gen			fup8w =.
foreach var of varlist fup8w_nuc fup8w_sgaglas {
replace		fup8w = `var' if `var' !=. & fup8w==.
}
drop		fup8w_*
gen			fup26w =.
foreach var of varlist fup26w_iron fup26w_lcglas fup26w_lcterm fup26w_ppd fup26w_sgaglas fup26w_sgaterm {
replace		fup26w = `var' if `var' !=. & fup26w==.
}
drop		fup26w_*
gen			fup9m =.
foreach var of varlist fup9m_iron fup9m_lcglas fup9m_lcpre fup9m_lcterm fup9m_orig fup9m_ppd fup9m_sgaterm {
replace		fup9m = `var' if `var' !=. & fup9m==.
}
drop		fup9m_*
gen			fup18m =.
foreach var of varlist fup18m_sgaterm fup18m_ppd fup18m_orig fup18m_lcterm fup18m_lcpre fup18m_lcglas fup18m_iron {
replace		fup18m = `var' if `var' !=. & fup18m==.
}
drop		fup18m_*
gen			fup10y =.
foreach var of varlist fup10y_lcglas fup10y_orig fup10y_palm fup10yr_palm {
replace		fup10y = `var' if `var' !=. & fup10y==.
}
drop		fup10y_* fup10yr_*
gen			fup12w =.
foreach var of varlist fup12w_lcglas fup12w_lcterm fup12w_palm fup12w_ppd fup12w_sgaterm fup12wks_palm {
replace		fup12w = `var' if `var' !=. & fup12w==.
}
drop		fup12w_* fup12wks_* 
gen			fup5y =.
foreach var of varlist fup5y_orig fup5y_sgaglas {
replace		fup5y = `var' if `var' !=. & fup5y==.
}
drop		fup5y_orig fup5y_sgaglas  
gen			fup6to8y =.
foreach var of varlist fup6to8y_ppd fup6y_sgaterm fup7y_orig {
replace		fup6to8y = `var' if `var' !=. & fup6to8y==.
}
drop		fup6to8y_ppd fup6y_sgaterm fup7y_orig
gen			fup11to20y =.
foreach var of varlist fup15y_orig fup16y_sgaterm fup17y_lcpre fup20y_orig {
replace		fup11to20y = `var' if `var' !=. & fup11to20y==.
}
drop		fup15y_orig fup16y_sgaterm fup17y_lcpre fup20y_orig
gen			fup16w =.
foreach var of varlist fup16w_nuc fup16w_sgaglas {
replace		fup16w = `var' if `var' !=. & fup16w==.
}
drop		fup16w_nuc fup16w_sgaglas
rename		fup15m_iron fup15m
rename		fup12m_iron fup12m
rename		fup3w_palm fup3w
rename		fup20w_nuc fup20w
rename		fup25y_orig fup25y
* dates
drop 		d_end_orig d_scbu_orig d_dobsub_ppd d_scbu_orig d_o_b2_nuc d_o_b_nuc d_res_iron
gen			d_10y =.
foreach var of varlist d_10y_lcglas d_10y_palm {
replace		d_10y = `var' if `var' !=.
}
drop		d_10y_lcglas d_10y_palm
gen			d_12w =.
foreach var of varlist d_12w_lcglas d_12w_palm d_12w_ppd d_12w_sgaterm {
replace		d_12w  = `var' if `var' !=.
}
drop		d_12w_lcglas d_12w_palm d_12w_ppd d_12w_sgaterm
gen			d_18m =.
foreach var of varlist d_18m_iron d_18m_lcglas d_18m_ppd d_18m_sgaterm {
replace		d_18m  = `var' if `var' !=.
}
drop		d_18m_iron d_18m_lcglas d_18m_ppd d_18m_sgaterm
gen			d_26w =.
foreach var of varlist d_26w_lcglas d_26w_ppd d_26w_sgaglas d_26w_sgaterm {
replace		d_26w = `var' if `var' !=.
}
drop		d_26w_lcglas d_26w_ppd d_26w_sgaglas d_26w_sgaterm
gen			d_6w =.
foreach var of varlist d_6w_lcglas d_6w_palm d_6w_ppd d_6w_sgaterm {
replace		d_6w = `var' if `var' !=.
}
drop		d_6w_lcglas d_6w_palm d_6w_ppd d_6w_sgaterm
gen			d_5y =.
foreach var of varlist d_5y_sgaglas {
replace		d_5y = `var' if `var' !=.
}
drop		d_5y_sgaglas
gen			d_9m =.
foreach var of varlist d_9m_lcglas d_9m_ppd d_9m_sgaterm  {
replace		d_9m = `var' if `var' !=.
}
drop		d_9m_lcglas d_9m_ppd d_9m_sgaterm 
gen			d_6to8y =.
foreach var of varlist d_6y_ppd d_6y_sgaterm d_7y_orig {
replace		d_6to8y = `var' if `var' !=.
}
drop		d_6y_ppd d_6y_sgaterm d_7y_orig
rename		d_12m_iron d_12m
rename		d_15m_iron d_15m
rename		d_16w_sgaglas d_16w
rename		d_16y_sgaterm d_16y
rename		d_3w_palm d_3w
rename		d_8w_sgaglas d_8w
rename		d_rand_palm d_rand
format		d_* 	%tdDD_Mon_CCYY 
order		_all, alphab
********************************************************************************
* rename and label variables
********************************************************************************
* rename
foreach var of varlist ID_orig id16_sgaterm id2_nuc ident_2_palm oldid_palm id_sgaglas patient_id_sgaterm {
tostring `var', replace
}
gen		studyid_other1 =""
foreach var of varlist ID_orig id16_sgaterm id10yr_palm id_sgaglas {
replace studyid_other1= `var' if studyid_other1 =="" 
}
gen		studyid_other2 =""
foreach var of varlist patient_id_sgaterm {
replace studyid_other2= `var' if studyid_other2 ==""
}
drop ID_orig id16_sgaterm id2_nuc ident_2_palm oldid_palm id_sgaglas patient_id_sgaterm id10yr_palm 
* label
label var	studyid1 "participant id"
label var	studyid_other1 "other known participant id 1"
label var	studyid_other2 "other known participant id 2"
label var	trial "trial name"
label var	d_dob "date of birth"
label var	sex "sex 1=male 2=female"
label var	d_10y "date of 10 year visit"
label var	d_12m "date of 12 month visit"
label var	d_12w "date of 12 week visit"
label var	d_15m "date of 15 month visit"
label var	d_16w "date of 16 week visit"
label var	d_18m "date of 18 month visit"
label var	d_26w "date of 26 week visit"
label var	d_3w "date of 3 week visit"
label var	d_5y "date of 5 year visit"
label var	d_6to8y "date of 6 to 8 year visit"
label var	d_6w "date of 6 week visit"
label var	d_8w "date of 8 week visit"
label var	d_9m "date of 9 month visit"
label var	d_rand "date of randomisation"
label var	fup10y "took part in 10 year visit"
label var	fup11to20y "took part in 11-20 year visit"
label var	fup12m "took part in 12 month visit"
label var	fup12w "took part in 12 week visit"
label var	fup15m "took part in 15 month visit"
label var	fup16w "took part in 16 week visit"
label var	fup18m "took part in 18 month visit"
label var	fup20w "took part in 20 week visit"
label var	fup25y "took part in 25 year visit"
label var	fup26w "took part in 26 week visit"
label var	fup3w "took part in 3 week visit"
label var	fup5y "took part in 5 year visit"
label var	fup6to8y "took part in 6 to 8 year visit"
label var	fup6w "took part in 6 week visit"
label var	fup8w "took part in 8 week visit"
label var	fup9m "took part in 9 month visit"
label var	fupbone_sgaglas "took part in bone fup sga glasgow"
********************************************************************************
* tag them so I know their source
********************************************************************************
gen 		sourceclinical=1
descr, s	
cap 		log close
save		"${datadir}\all\expected IDs.dta", replace