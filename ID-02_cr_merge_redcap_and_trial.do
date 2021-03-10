/*******************************************************************************
Project: 	head or heart
Purpose: 	cleans and merges ID database
Author: 	Max Verfuerden
Created:	25.04.2017
*******************************************************************************/
/* 			this file comes after: cr_import_redcap.do*/
*step 1: run ado file "drop miss"
********************************************************************************
// run the dropmiss-ado-file (is pinned on left hand side in project view)
*step 2: set filepaths, start log
********************************************************************************
qui do 		"S:\Head_or_Heart\max\archive\2-do\00-global.do"
cd 			"$projectdir"
cap log 	close
log using 	"${logdir}\cr_merge_redcap_and_trial_$S_DATE.log", replace 
*step 3: deduplicate redcap data
*******************************************************************************
**** must make sure that I give different names to the d_dob variables before matching, so I know when there are inconsistencies
preserve
use			"${datadir}\ID_database 2017-06-16.dta", clear
order		_all, alphab
order		studyid1 pid trial centre1 d_dob sex street1 city1
sort 		studyid1
drop if		studyid1==""				
duplicates 	report studyid1 
duplicates 	tag studyid1, gen(dupl1)
tab			dupl1
gen			sourceredcap=1
save		"${datadir}\ID_database 2017-06-16.dta", replace 
descr,		s 
restore
********************************************************************************
*step 4:  with clinical data (more than in redcap) /// start here if I have run this do-file on same file before
********************************************************************************
use			"S:\Head_or_Heart\max\attributes\1-Data\all\expected IDs.dta" , clear  
order		_all, alphab
order		studyid1 trial d_dob sex 
rename		sex sex_clin
descr, s
rename		d_dob d_dob_clin
rename		trial trial_clin
*step 5: merge in redcap multiple times using the different recorded studyids
********************************************************************************
// reason: so I catch those with more than 1 record (e.g. participated in multiple trials)
* first merge in redcap
merge 1:1 	 studyid1 using "${datadir}\ID_database`time_string'.dta" 
* drop non-matches from redcap(using)
drop if		_merge==2
drop		_merge
** now pretend I am starting from new, having a cohort in which about half of them are enriched with redcap info
* match on other available identifier1
rename		studyid1 studyid1_originalclinical
rename		studyid_other1 studyid1
replace		studyid1 = studyid1_originalclinical if studyid1=="."
replace		studyid1 = studyid1_originalclinical if studyid1==" "
replace		studyid1 = studyid1_originalclinical if studyid1==""
order		studyid1 trial d_dob sex sex_clin
duplicates 	report studyid1
* merge redcap in again round two using alternative identifiers
merge 1:1 	studyid1 using  "${datadir}\ID_database`time_string'.dta"
* drop non-matches from redcap(master)
drop if		_merge==2
drop		_merge
** now pretend I am starting from new again, having a cohort where most are enriched with clinical info
* match on other available identifier2
rename		studyid1 studyid1_matchround2
rename		studyid_other2 studyid1
replace		studyid1 = studyid1_matchround2 if studyid1=="."
replace		studyid1 = studyid1_matchround2 if studyid1==" "
replace		studyid1 = studyid1_matchround2 if studyid1==""
duplicates 	report studyid1
* merge round three using alternative identifiers
merge 1:1 	studyid1 using  "${datadir}\ID_database`time_string'.dta"
* revert to original studyid
rename		studyid1 studyid1_matchround3
gen			studyid1 = studyid1_originalclinical
replace		studyid1 = studyid1_matchround2 if studyid1==""
replace		studyid1 = studyid1_matchround3 if studyid1==""
duplicates	report studyid1
duplicates	tag studyid1, gen(d)
tab 		d, m
drop if		_merge==2 & d==1
drop 		d
* gain overview:
order		_all, alphab
order		studyid1 trial centre1 pid d_dob sex sex_clin
sort		studyid1
replace		sourceredcap=0 if sourceredcap==.
replace		sourceclinical=0 if sourceclinical==.
tab			sourceredcap sourceclinical, m
* now try to merge using the alternative studyid from redcap
rename		studyid_alt studyid_altorig
gen			studyid_alt=studyid1
drop		_merge
merge 1:1 	studyid_alt using  "${datadir}\ID_database`time_string'.dta" 
duplicates	report studyid1
duplicates	tag studyid1, gen(d)
drop if		_merge==2 & d==1
drop		d _merge
sort		studyid1 
order		studyid1
replace		sourceredcap=0 if sourceredcap==.
replace		sourceclinical=0 if sourceclinical==.
* drop odd ids:
drop if		studyid1=="#" | studyid1=="x""
sort		studyid1
********************************************************************************
* clean a bit before moving to next step
********************************************************************************
rename		trial A
drop		trialc* trialg* trialh* triall* trials* trialn* triali* trialk* trialo*
rename		A trial
rename		studyid1 A
rename		pid B
rename		A studyid1 
rename		B pid
drop 		*_complete pcodesource* sourceadd*
dropmiss	city* add* d_* fup* pcode* sources* street* county* entry* alt*, force 
rename		sources___1 s01
rename		sources___2 s02
rename		sources___3 s03
rename		sources___4 s04
rename		sources___5 s05
rename		sources___6 s06
rename		sources___7 s07
rename		sources___8 s08
rename		sources___9 s09
rename		entryperson___1 entry_max
rename		entryperson___2 entry_kathy
rename		entryperson___3 entry_marina
rename		entryperson___4 entry_natalie
rename		entryperson___5 entry_helper
local 		i=10
foreach 	var of varlist sources_*  {
			rename `var' s`i'
			local i = `i' + 1 
}	
lab def 	yesno 0"no" 1"yes"
foreach 	var of varlist entry_* s0* s1* s2* s3* {
label 		val `var' yesno
}
foreach 	var of varlist city* county* *name* street* *firstna* *lastna* patnot* {
replace		`var' = lower(`var')
replace		`var' = trim(`var')
}
foreach 	var of varlist patnot* {
replace 	`var'= subinstr(`var', ".", "",.)
}
foreach 	var of varlist city* street* *firstna* *lastna* {
replace 	`var'= subinstr(`var', "  ", " ",.)
}
foreach 	postcode of varlist pcode* {
replace		`postcode' = upper(`postcode')
replace		`postcode' = trim(`postcode')
}
replace 	street1 = subinstr(street1, "   ", " ",.)
replace 	street1 = subinstr(street1, "  ", " ",.)
*** ok now we have merged in those that we expect to see with those that we have in redcap
gen			clinicalonly=0
replace		clinicalonly=1 if sourceclinical==1 & sourceredcap==0
********************************************************************************
* how many addresses per person in total?
********************************************************************************
gen			address_tot = 0
replace		address_tot = 1 if !missing(street1) & missing(street2, street3, street4)
replace		address_tot = 2 if !missing(street1, street2) & missing(street3, street4)
replace		address_tot = 3 if !missing(street1, street2, street3) & missing(street4)
replace		address_tot = 4 if !missing(street1, street2, street3, street4)
lab var		address_tot  "total no of recorded addresses in redcap"
tab			address_tot
********************************************************************************
* how many postcodes per person in total?
********************************************************************************
gen			pcode_tot = 0
replace		pcode_tot = 1 if !missing(pcode1) & missing(pcode2, pcode3, pcode4)
replace		pcode_tot = 2 if !missing(pcode1, pcode2) & missing(pcode3, pcode4)
replace		pcode_tot = 3 if !missing(pcode1, pcode2, pcode3) & missing(pcode4)
replace		pcode_tot = 4 if !missing(pcode1, pcode2, pcode3, pcode4)
lab var		pcode_tot  "total no of recorded pcodees in redcap"
tab			pcode_tot
*******************************************************************************
* what is the recorded maximum and minimum age at each (street-) address?
********************************************************************************
rename		d_form	timestamp
foreach 	var of varlist d_* {
replace		`var'=. if `var'==5479  // this is Jan 1 1975 - wrongly set date - not able to clear in redcap
}
* find the age from the date of address - not necessarily in chronoligical order, hence "ABCD"
gen			age1_addA= int((d_address1-d_dob)/365.25 ) if !missing(d_address1, d_dob)
gen			age1_addB= int((d_address2-d_dob)/365.25 ) if !missing(d_address2, d_dob)
gen			age1_addC= int((d_address3-d_dob)/365.25 ) if !missing(d_address3, d_dob)
gen			age1_addD= int((d_address4-d_dob)/365.25 ) if !missing(d_address4, d_dob)
* generate separate ages for the other recorded dates 
gen			age2_addA=int((d_address11-d_dob)/365.25)
gen			age3_addA=int((d_address12-d_dob)/365.25)
gen			age2_addB=int((d_address21-d_dob)/365.25)
gen			age3_addB=int((d_address22-d_dob)/365.25)
gen			age2_addC=int((d_address31-d_dob)/365.25)
gen			age3_addC=int((d_address31-d_dob)/365.25)
gen			age2_addD=int((d_address41-d_dob)/365.25)
gen			age3_addD=int((d_address41-d_dob)/365.25)
* set to missing if age at address was below 0 years
foreach 	var of varlist age1_* age2_* age3_* {
replace		`var'=. if `var'<0
}
* find the minimum age for each address 
egen		ageminaddA = rowmin(age1_addA age2_addA age3_addA)  // min age address A
egen		ageminaddB = rowmin(age1_addB age2_addB age3_addB)  // min age address B
egen		ageminaddC = rowmin(age1_addC age2_addC age3_addC)  // min age address C
egen		ageminaddD = rowmin(age1_addD age2_addD age3_addD)  // min age address D
* find the maximum age for each address 
egen		agemaxaddA = rowmax(age1_addA age2_addA age3_addA)  // max age address A
egen		agemaxaddB = rowmax(age1_addB age2_addB age3_addB)  // max age address B
egen		agemaxaddC = rowmax(age1_addC age2_addC age3_addC)  // max age address C
egen		agemaxaddD = rowmax(age1_addD age2_addD age3_addD)  // max age address D
* find the minimum date for each address 
egen		d_minaddA = rowmin(d_address1 d_address11 d_address12)  // min date address A
egen		d_minaddB = rowmin(d_address2 d_address21 d_address22)  // min date address B
egen		d_minaddC = rowmin(d_address3 d_address31 d_address32)  // min date address C
egen		d_minaddD = rowmin(d_address4 d_address41)  			// min date address D
* find the maximum date for each address 
egen		d_maxaddA = rowmax(d_address1 d_address11 d_address12)  // max date address A
egen		d_maxaddB = rowmax(d_address2 d_address21 d_address22)  // max date address B
egen		d_maxaddC = rowmax(d_address3 d_address31 d_address32)  // max date address C
egen		d_maxaddD = rowmax(d_address4 d_address41)  			// max date address D
* find the duration for each address 
gen			durationaddA = agemaxaddA-ageminaddA 
lab var		durationaddA "known duration address A (years)"
gen			durationaddB = agemaxaddB-ageminaddB
lab var		durationaddB "known duration address B (years)"
gen			durationaddC = agemaxaddC-ageminaddC 
lab var		durationaddC "known duration address C (years)"
gen			durationaddD = agemaxaddD-ageminaddD 
lab var		durationaddD "known duration address D (years)"
* find the earliest age any address was recorded 
egen		age_firstadd = rowmin(ageminaddA ageminaddB ageminaddC ageminaddD)  
lab	var		age_firstadd "earliest age any address was recorded (years)"
* find the latest age any address was recorded 
egen		age_lastadd = rowmax(agemaxaddA agemaxaddB agemaxaddC agemaxaddD)  
lab	var		age_lastadd "latest age any address was recorded (years)"
* find the earliest date any address was recorded 
egen		d_firstadd = rowmin(d_minaddA d_minaddB d_minaddC d_minaddD)  
lab	var		d_firstadd "earliest date any address was recorded (years)"
* find the latest date any address was recorded 
egen		d_lastadd = rowmax(d_maxaddA d_maxaddB d_maxaddC d_minaddD)  
lab	var		d_lastadd "latest date any address was recorded (years)"
drop		d_add* age1* age2* age3*  
order		_all, alpha
order		studyid1 pid trial firstnamechild lastnamechild sex d_dob 
********************************************************************************
* how many addresses in first 5 years per person?
********************************************************************************
* create an indicator, below five at certain address
gen			addAb5 =0
replace		addAb5 =1 if ageminaddA <5
gen			addBb5 =0
replace		addBb5 =1 if ageminaddB <5
gen			addCb5 =0
replace		addCb5 =1 if ageminaddC <5
gen			addDb5 =0
replace		addDb5 =1 if ageminaddD <5
egen		nraddbelow5= anycount(addAb5 addBb5 addCb5 addDb5), v(1)
lab var		nraddbelow5 "nr of addresses recorded below age 5y"
drop		addA* addB* addC* addD*
********************************************************************************
* how many addresses after age 5 years per person?
********************************************************************************
* create an indicator, below five at certain address
gen			addAa5 =0
replace		addAa5 =1 if agemaxaddA >5 & !missing(agemaxaddA)
gen			addBa5 =0
replace		addBa5 =1 if agemaxaddB >5 & !missing(agemaxaddB)
gen			addCa5 =0 
replace		addCa5 =1 if agemaxaddC >5 & !missing(agemaxaddC)
gen			addDa5 =0
replace		addDa5 =1 if agemaxaddD >5 & !missing(agemaxaddD)
egen		nraddabove5= anycount(addAa5 addBa5 addCa5 addDa5), v(1)
lab var		nraddabove5 "nr of addresses recorded above age 5y"
drop		addA* addB* addC* addD*
********************************************************************************
* flag control participants
********************************************************************************
gen			control = 0
replace		control = 1 if strpos(studyid1, "TC")
replace		control = 1 if strpos(studyid1, "PC")
lab val		control yesno
tab			trial control
********************************************************************************
* flag if we know patient died
********************************************************************************
replace		died = 1 if strpos(patnotes, "died")
replace		died = 1 if strpos(patnotes, "dead")
replace		died = 1 if strpos(patnotes, "rip")
tab			trial died
********************************************************************************
* clean up
********************************************************************************
rename		pid redcapid
rename		dup_pid redcapidofdup
rename		studyid1_matchround2 othid1
rename		studyid1_matchround3 othid2
rename		studyid2 othid3
rename		studyid_alt othid4
rename		studyid_altorig othid5
rename		studyidnr othid6
rename		studyidnuc othid7
rename		studyid1_originalclinical othid8
drop 		agem* patcount* dupl*
cap lab		drop trial2
lab 		def	trial2 1"OAB" 2"OAB" 3"PDP" 4"LCPUFA_pret" 5"LCPUFA_term" 6"NUC" 7"Iron" 8"SGA" 9"PAL" 
lab var		s01 "2 Boxes: Nucleotides (162+163)"
lab var		s02 "Blue Notebook: OAB 5y"
lab var		s03 "Red Notebook: PPD/SGA 18m 5-6y & LCPUFA"
lab var		s04 "Green Notebook: OAB Blood fup"
lab var		s05 "Box: PPD/SGA Blood 16y (no ref)"
lab var		s06 "Box: OAB 10y + 20y (56)"
lab var		s07 "Excel: OAB 20y"
lab var		s08 "Long back-up sheet: Iron/LCPRE/LCTER/SGA 9/18m (166)" 
lab var		s09 "Box: Iron 1993 (110)"
lab var		s10 "Box: OAB Cognitive 2000/2001 (112)" 
lab var		s11 "Box: PPD consent (121)" 
lab var		s12 "Box: Palm rand.(150)" 
lab var		s13 "Box: Palm recr. bf + 10y (151)"
lab var		s14 "Box: LCPRE BP+ body comp PDP/SGA 9/18m (186)"
lab var		s15 "Box: LCTER '94/95 (153)" 
lab var		s16 "Box: SGA/PDP '93/95 some 18m (156)"
lab var		s17 "Box: SGA/PPD 2002/03 2010 15-17y (157)"
lab var		s18 "Folder: SGA Glas Vasc fup stratum1"
lab var		s19 "SGA/PDP 2000/01 BPressure (167)" 
lab var		s20 "Folder: SGA Glas recr strat1"
lab var		s21 "SGA Glas recr strat2" 
lab var		s22 "Box: LCP Glas 9/18m 10y (114)"
lab var		s23 "-"
lab var		s24 "Box: LCTER 4-6y (154)" 
lab var		s25 "Box: LCPRE (168)"
lab var		s26 "Folder: SGA Glas vasc strat2" 
lab var		s27 "-"
lab var		s28 "-"
lab var		s29 "-"
lab var		s30 "-"
lab			def sex 1"male" 2"female"
lab val		sex sex
lab val		sex_clin sex
format		d_*	%tdDD_Mon_CCYY 
* drop variables with all values missing incl follow ups, ids, street, city dates
dropmiss 	*fup* *id* s* c* d_* ent*, force
foreach 	var of varlist s0* s1* s2* s3* source* {
replace		`var'=. if `var'==0
dropmiss 	`var', force
}
* replace missing values with 0 for certain variables
replace		twotrials=0 if twotrials==.
foreach 	var of varlist entry* fup* {
replace 	`var'=0 if `var'==.
}
compress
save		"${datadir}\ID_merged_database.dta", replace
cap log 	close