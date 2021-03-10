/*==============================================================================
purpose: 		creates a dataset meant to describe the linked data w outcomes.
date 
created: 		21/06/2019
last updated: 	07/08/2019
				22/05/2020 - replaced passac5em with glevel2em 
last run: 		01/02/2020
				27/04/2020
author: 		maximiliane verfuerden
Adds NPD Gender
Adds KS2 and KS4 Maths and English outcomes (raw and scaled)
Adds SEN support
Adds school years
Creates variables for school year and SEN patterns
*==============================================================================*/
clear
cd 			"S:\Head_or_Heart\max\post-trial-extension"
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
cap qui		do "S:\Head_or_Heart\max\attributes\7-ado\dropmiss.ado"
cap	qui		do "S:\Head_or_Heart\max\attributes\7-ado\renvars.ado"
cap qui 	do	"S:\Head_or_Heart\max\post-trial-extension\00-ado\groups.ado"
capture 	log close
log 		using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\cr_addoutcomes$S_DATE.log", replace
use			"${datadir}\matches15andup_non_dup.dta",clear
drop		fup1* fup2*
duplicates 	tag studyid1, gen(test)
tab			test 
********************************************************************************
*			IDENTIFY LINKED PARTICIPANT RECORDS						   *
********************************************************************************
// cross check IDs: enables me to creates flag of twins and multiple trial participants
merge 		1:1 studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\importantvars.dta", keepusing(ID_* idmulti* )
drop if		_merge==2 															
drop		_merge
count if	check==1
// get all characteristics
merge 		1:1 studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\all\attributedataset_randomised.dta" 
drop if		_merge==2 															
drop		_merge
** just make sure twin variable is complete
replace		multiple=multiple_birth if multiple==.								
replace		multiple=1 if ID_twin !=.
replace		multiple=1 if idmulti1 !=""
replace		multiple=1 if idmulti2 !=""
replace		multiple=1 if idmulti3 !=""
** flag linked participant records
duplicates 	tag pupilreference, gen(dupPID)
replace		twotrials=1 if ID_redcaplinkedrec!=. & multiple!=1 					
count		if twotrials==1 & dupPID>0 											
sort		twotrials pupilreference studyid1 ID_redcap ID_redcaplinkedrec
order		twotrials pupilreference studyid1 ID_redcap ID_redcaplinkedrec
gen			studyid2 = ""
** I need to go backwards and forwards to fill in the missings
replace 	studyid2 = studyid1[_n-1] if ID_redcap==ID_redcaplinkedrec[_n-1] &  ID_redcaplinkedrec !=. 
codebook 	studyid2 if twotrials==1 & dupPID>0 & ID_redcap!=. &  ID_redcaplinkedrec !=. 
replace 	studyid2 = studyid1[_n+1] if ID_redcap==ID_redcaplinkedrec[_n+1] & studyid2=="" &  ID_redcaplinkedrec !=.
codebook 	studyid2 if twotrials==1 & dupPID>0 & ID_redcap!=. &  ID_redcaplinkedrec !=. 
replace 	studyid2 = studyid1[_n+1] if ID_redcap[_n+1] == ID_redcaplinkedrec & studyid2=="" &  ID_redcaplinkedrec !=.
replace 	studyid2 = studyid1[_n-1] if ID_redcap[_n-1] == ID_redcaplinkedrec & studyid2=="" &  ID_redcaplinkedrec !=.
codebook 	studyid2 if twotrials==1 & dupPID>0 & ID_redcap!=. &  ID_redcaplinkedrec !=. 
codebook	studyid2
** flag studyids of twins
drop		ID_twin
gen			studyid_twin1 = ""
gen			studyid_twin2 = ""
gen			studyid_twin3 = ""
replace 	studyid_twin1 = idmulti1
replace 	studyid_twin2 = idmulti2
replace 	studyid_twin3 = idmulti3
count if 	multiple==1 
drop		idmulti*
count 		if matchlen==1 & group!=4
count 		if matchcons==1 & group!=4
cap drop	test
duplicates 	tag studyid1, gen(test)
tab			 test // 0
********************************************************************************
*						CLEAN SOME VARIABLES					 	   *
********************************************************************************
/* create a temporary datatset that treats studyid2 as if it was studyid1 and then
merge it back in to update missing values in the other datasets*/
count		//  1,831
preserve 
tempfile	legitcopies
drop if		studyid2==""
replace 	studyid1=studyid2 
count		// 106
save		`legitcopies'
restore
merge		1:m studyid1 using `legitcopies', update keepusing(studyid_twin1 matedu studyid_twin2 studyid_twin3 ///
			ethn* bwt alc* smok* gestage bayley* iq_* died later* apgar* kps* delivmode)  
count		// 1,831 - / 46 missings were updated
cap drop 	wanted	
// not everything was copied over. this fills in some further missing values:
sort 		pupilreference
foreach 	var of varlist ethn* bwt alc* smok* gestage bayley_MDI deliv* matedu bayley_PDI iq_score later_iq_score apgargrp5m sga d_iq d_iq_later d_kps kps_adaptive kps_finemotor kps_fullscore kps_grossmotor kps_language kps_perssoc apgar1m apgar5m delivmode later_piq_score later_viq_score {
replace 	`var' = `var'[_n-1] if studyid1 == studyid2[_n-1] & `var'==.
}
foreach 	var of varlist ethn* bwt alc* smok* gestage bayley_MDI deliv* matedu bayley_PDI iq_score later_iq_score apgargrp5m sga d_iq d_iq_later d_kps kps_adaptive kps_finemotor kps_fullscore kps_grossmotor kps_language kps_perssoc apgar1m apgar5m delivmode later_piq_score later_viq_score {
replace 	`var' = `var'[_n+1] if studyid1 == studyid2[_n+1] & `var'==.
}
order 		twotrials pupilreference studyid* ID_redcap ID_redcap* trial group birthyear sex
** check where the the same participants are conflicting
drop		_merge
count 		if matchlen==1 & group!=4
count 		if matchcons==1 & group!=4
cap drop	test
duplicates 	tag studyid1, gen(test)
tab			 test // 0
********************************************************************************
*			ADD OUTCOMES					 	  		   *
********************************************************************************
/* add in academic years*/
merge		m:1 pupilreference using	"S:\Head_or_Heart\max\post-trial-extension\1-data\alldatawide.dta"
duplicates	tag studyid1, gen(dupSID)
tab 		dupSID
sort		studyid1 														 
drop if		_merge==2 
drop		dup* _merge
count 		if matchlen==1 & group!=4
count 		if matchcons==1 & group!=4
********************************************************************************
*			Top school enrolment patterns					 	  		       *
********************************************************************************
/* add in academic years*/
egen		y2000 = anymatch(acyear*), v(2000)
egen		y2001 = anymatch(acyear*), v(2001)
egen		y2002 = anymatch(acyear*), v(2002)
egen		y2003 = anymatch(acyear*), v(2003)
egen		y2004 = anymatch(acyear*), v(2004)
egen		y2005 = anymatch(acyear*), v(2005)
egen		y2006 = anymatch(acyear*), v(2006)
egen		y2007 = anymatch(acyear*), v(2007)
egen		y2008 = anymatch(acyear*), v(2008)
egen		y2009 = anymatch(acyear*), v(2009)
egen		y2010 = anymatch(acyear*), v(2010)
egen		y2011 = anymatch(acyear*), v(2011)
egen		y2012 = anymatch(acyear*), v(2012)
egen		y2013 = anymatch(acyear*), v(2013)
egen		y2014 = anymatch(acyear*), v(2014)
egen		y2015 = anymatch(acyear*), v(2015)
egen		y2016 = anymatch(acyear*), v(2016)
egen		schoolpattern = concat(y2*)
drop 		y20*
/* list school enrolment patterns by frequency */
groups		schoolpattern, order(high)
drop		acyear* 
count 		if matchlen==1 & group!=4
count 		if matchcons==1 & group!=4
********************************************************************************
*			EXTRACT SPECIAL EDUCATIONAL NEEDS  		  				           *
********************************************************************************
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\cr_alldatasen.do"
/* which year was the SEN? */
forval		i=2000/2015{
gen			sen`i' = 0
}
forval		i=2000/2015{
forval		y=1/18{
replace		sen`i' = 1 if strpos(senyear`y', "`i'")>0
}
}
/* list SEN patterns by frequency */
drop 		senyear*
egen		senpattern = concat(sen20*)
groups		senpattern, order(high)
********************************************************************************
*			EXTRACT IDACI  		  				          					   *
********************************************************************************
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\cr_alldataidaci.do"
********************************************************************************
*			EXTRACT ETHNICITY / FIRST LANGUAGE 								   *
********************************************************************************
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\cr_alldataethn.do"
********************************************************************************
*		    EXTRACT SCHOOL YEAR		 				 	  		  			   *
********************************************************************************
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\cr_alldataschyr.do"
********************************************************************************
*		     EXTRACT FREE SCHOOL MEALS										   *
********************************************************************************
/* calls a do-file that extracts fsm from alldata.dta */
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\cr_alldatafsm.do"
********************************************************************************
*		    EXTRACT KS2 (ALL DATA)   				 	  		  			   *
********************************************************************************
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\cr_alldatak2.do"																		
********************************************************************************
*		    EXTRACT KS4 (ALL DATA)   				 	  		  			   *
********************************************************************************
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\cr_alldatak4.do"																	
********************************************************************************
*	        EXTRACT KS2 (ALLDATASUBJ.DTA)	                   *
********************************************************************************
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\cr_allsubjk2exams.do"
********************************************************************************
*	        EXTRACT KS4 (ALLDATASUBJ.DTA)	                   *
********************************************************************************
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\cr_allsubjk4exams.do"
********************************************************************************
*			THRESHOLD MEASURES 		  											   *
********************************************************************************
preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", clear
tempfile	fiveac
keep if 	strpos(npdfieldreference, "PASS_AC5EM")>0 | strpos(npdfieldreference, "EBACCAG_PTQ_EE")>0  | strpos(npdfieldreference, "EBACC_PTQ_EE")>0  |strpos(npdfieldreference, "ANYPASS")>0 | strpos(npdfieldreference, "LEVEL2")>0 | strpos(npdfieldreference, "GNVQ_AC")
keep if 	strpos(dataset, "KS4")>0 | strpos( dataset, "ks4")>0 
drop if		strpos(npdfieldreference, "GCSE")>0 | strpos(npdfieldreference, "MFL")>0  | strpos(npdfieldreference, "ANYPASS_PTQ_EE")>0  
drop if		strpos(npdfieldreference, "LEVEL2")>0 & !(strpos(npdfieldreference, "EM")>0)
drop		tableid laestab unique
replace		indicatorvalue= trim(indicatorvalue)
replace		acyear= trim(acyear)
drop if		indicatorvalue=="" 	
/* drop all duplicates except for the first observation*/
sort		pupilreference dataset acyear npdfieldreference indicatorvalue
by			pupilreference dataset acyear npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 															
drop		dup
/* five a-c (incl English & Maths )*/
gen			passac5 = ""
replace		passac5 = indicatorvalue if strpos(npdfieldreference, "GLEVEL2EM")>0
replace		passac5 = indicatorvalue if strpos(npdfieldreference, "PASS_AC5EM")>0 & passac5==""
destring	passac5, replace
/* EBAC A-C*/
gen			ebacc_ac= ""
replace		ebacc_ac = indicatorvalue if strpos(npdfieldreference, "EBACC_PTQ_EE")>0
lab var		ebacc_ac "achieved EBACC A-C"
destring	ebacc_ac, replace
/* EBAC A-G*/
gen			ebacc_ag = ""
replace		ebacc_ag = indicatorvalue if strpos(npdfieldreference, "EBACCAG_PTQ_EE")>0
lab var		ebacc_ag "achieved EBACC A-G"
destring	ebacc_ag, replace
/* any qualifications */
gen			anypass = ""
replace		anypass = indicatorvalue if strpos(npdfieldreference, "ANYPASS")>0  
lab var		anypass "any pass in GCSE or equivalent"
destring	anypass, replace
gen			yr_anypass = ""
replace		yr_anypass = acyear if anypass !=.
lab var		yr_anypass "year for any/no pass at GCSE or equivalent"
/* number for passes at A*-C */
gen			nrpass_ac = ""
replace		nrpass_ac = indicatorvalue if strpos(npdfieldreference, "GLEVEL2EM")>0  
lab var		nrpass_ac "number of passes achieved at A-C in KS4"
destring	nrpass_ac, replace
gen			yr_nrpass_ac = ""
replace		yr_nrpass_ac= acyear if nrpass_ac !=.
lab var		yr_nrpass_ac "year for number of passes at GCSE or equivalent"
drop		dataset acyear npdfield* indic*
/* copy information over within pupilnumber */
bysort 		pupilreference: egen max_passac5 = max(passac5)
bysort 		pupilreference: egen max_anypass = max(anypass)
bysort 		pupilreference: egen max_nrpass_ac = max(nrpass_ac)
bysort 		pupilreference: egen max_ebacc_ac = max(ebacc_ac)
bysort 		pupilreference: egen max_ebacc_ag = max(ebacc_ag)
drop		passac5  anypass nrpass_ac ebacc_ac ebacc_ag
sort		pupilreference yr_anypass
bysort 		pupilreference: replace  yr_anypass = yr_anypass[_N]
sort		pupilreference yr_nrpass_ac
bysort 		pupilreference: replace  yr_nrpass_ac = yr_nrpass_ac[_N]
/* drop all duplicates except for the first observation*/
sort		pupilreference max_ebacc_ac max_ebacc_ag max_passac5 max_anypass yr_anypass max_nrpass_ac yr_nrpass_ac
by			pupilreference max_ebacc_ac max_ebacc_ag max_passac5 max_anypass yr_anypass max_nrpass_ac yr_nrpass_ac:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 															
drop		dup*															   
/* left school without qualifications */
gen			noquals= 1 if max_anypass ==0 |max_anypass ==.
replace		noquals =0 if noquals==.
rename		max_* * 
dropmiss	_all, force 													
save		`fiveac'
restore
merge		m:1 pupilreference using `fiveac'
drop if		_merge==2
drop		_merge
gen 			gcse2210_score58 = gcse2210_score
tab				gcse2210_score58
recode	 		gcse2210_score58 (8=58) (7=52) (6=46) (5=40) (4=34) (3=28) (2=22) (1=16)
tab				gcse2210_score58 gcse2210_score
gen 			gcse5030_score58 = gcse5030_score
tab				gcse5030_score58
recode	 		gcse5030_score58 (8=58) (7=52) (6=46) (5=40) (4=34) (3=28) (2=22) (1=16)
tab				gcse5030_score58 gcse5030_score
********************************************************************************
*			CHARACTERISTICS BY MATCH WEIGHT THRESHOLD						 *
********************************************************************************
* without trial 1 and 2 and  without breastfeds
count 			if matchlen==1 & group!=4 & trial !=1 & trial !=2
count 			if matchcons==1 & group!=4 & trial !=1 & trial !=2
foreach var of varlist sen_ever fsm_ever passac5 {
display as text	"sensitive threshold 8+:"
tab 		`var' if matchlen==1 & group!=4  & trial !=1 & trial !=2
display as text	"specific threshold 15+:"
tab 		`var' if matchcons==1 & group!=4  & trial !=1 & trial !=2
}
foreach var of varlist gcse*score* ks2*raw {
display as text	"lenient match weight 8+:"
tabstat 		`var' if  matchlen==1  & group!=4 & trial !=1 & trial !=2, s(mean sd)  format(%9.1g)
display as text _dup(59) "_"
display as text	"conservative match weight 15+:"
tabstat 		`var' if  matchcons==1  & group!=4 & trial !=1 & trial !=2, s(mean sd) format(%9.1g)
}
* don't need these variables
drop		*_ppd *_new sex
dropmiss	_all, force 
rename		RCTsex sex
order		studyid1* pupilreference trial birthyear iq_score bayley_* gcse*_score ks2_mat_raw ks2_engread_raw  sen_ever *idaci*  matedu fsm_ever	
sort		birthyear
/*===============================================================================*/
compress
descr, 		full 
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\finalsampleandmainoutcomes.dta", replace
cap log 	close