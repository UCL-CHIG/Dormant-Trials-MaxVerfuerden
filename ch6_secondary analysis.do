/*******************************************************************************
purpose:		Code to run secondary analysis for PhD Chapter 6
date 
created: 		01/02/2020
last updated: 	21/05/2020 - unblinded
last run:	 	16/06/2020
author: 		maximiliane verfuerden

My secondary outcomes are:
- Mean GCSE English Exam scores (z-scores standardised to trial sample)
- Mean KS2 Maths Exam scores (z-scores standardised to trial sample)
- Mean KS2 English Exam scores (z-scores standardised to trial sample)
- Probability of receiving 5+ GCSE Grades A* to C
- Probability of receiving special educational needs support

*******************************************************************************/

***

*HOUSEKEEPING*
clear
cd 				"S:\Head_or_Heart\max\post-trial-extension"
qui do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
cap qui			do "S:\Head_or_Heart\max\attributes\7-ado\dropmiss.ado"
cap	qui			do "S:\Head_or_Heart\max\attributes\7-ado\renvars.ado"
cap qui 		do "S:\Head_or_Heart\max\post-trial-extension\00-ado\groups.ado"
cap qui 		do "S:\Head_or_Heart\max\post-trial-extension\00-ado\regsave.ado"
capture 		log close
log 			using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\ch6_primary analysis$S_DATE.log", replace
timer      	 	clear
timer       	on 1

*LOAD DATASET*
use 			"S:\Head_or_Heart\max\post-trial-extension\1-data\samplingframe.dta", clear

*DESCRIBE DATASET*
tab 			trial group, nolab		
drop 			if group==4 // to not skew the z-scores
drop			if inlist(trial, 1,2)

********************************************************************************
*				CREATE Z-SCORES										 	       
********************************************************************************


* z-score GCSE English lang:		
********************************
tabstat		gcse5030_score, by(trial) s(mean sd min max)
levelsof	trial, local(levels) 
foreach		l of local levels {
egen 		z_gcseeng_t`l' = std(gcse5030_score) if trial == `l' 
tabstat		z_gcseeng_t`l',  s(mean sd min max)
}


* z-score KS2 Mathematics:	
********************************	
tabstat		ks2_mat_raw, by(trial) s(mean sd min max)
levelsof	trial, local(levels) 
foreach		l of local levels {
egen		z_ks2mat_t`l' = std(ks2_mat_raw) if trial == `l' 
tabstat		z_ks2mat_t`l',  s(mean sd min max)
}

* z-score KS2 English lang:		
********************************
tabstat		ks2_engread_raw, by(trial) s(mean sd min max)
levelsof	trial, local(levels) 
foreach		l of local levels {
egen		z_ks2eng_t`l' = std(ks2_engread_raw) if trial == `l' 
tabstat		z_ks2eng_t`l',  s(mean sd min max)
}

* copy z-scores to all records:	
********************************
levelsof		trial, local(levels) 
foreach			l of local levels {
bysort 			pupilreference: egen min_z_gcseeng_t`l' = min(z_gcseeng_t`l')
bysort 			pupilreference: egen min_z_ks2mat_t`l' = min(z_ks2mat_t`l')
bysort 			pupilreference: egen min_z_ks2eng_t`l' = min(z_ks2eng_t`l')
drop			z_gcseeng_t`l' z_ks2mat_t`l' z_ks2eng_t`l'
}
rename			min_* * 
egen			z_gcseeng = rowmean(z_gcseeng_t*)
egen			z_ks2mat = rowmean(z_ks2mat_t*)
egen			z_ks2eng = rowmean(z_ks2eng_t*)

* Probability of receiving 5+ GCSE Grades A* to C
****************************************************
rename			passac5 temp
egen			passac5 = rowmedian(temp*)
drop			temp
codebook		passac5 
tab 			trial passac5, m // 220 missing, most of these in the nucleotides study

* Probability of receiving special educational needs support
rename			sen_ever temp
egen			sen_ever = rowmedian(temp*)
drop			temp
codebook		sen_ever 

drop 			if group ==3

********************************************************************************
*				- COMPLETE CASE	- 							 				   *
********************************************************************************
drop 			if died==1

***
*** z-score KS 4 English:
***********************************
preserve
* drop participants that were too young for GCSE in the NPD
drop if			((age_ks4 <15 & age_ks4 >16) | age_ks4==. ) & trial==7
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
eststo: 		regress		z_gcseeng ib2.group if trial==`l', base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers  mtitles("{\b Trial `l' effect on KS4 English Score (crude CC)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}
restore

***
*** z-score KS 2 Maths:
***********************************
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
eststo: 		regress		z_ks2mat ib2.group if trial==`l', base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers  mtitles("{\b Trial `l' effect on KS2 Maths Score (crude CC}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}

***
*** z-score KS 2 English:
***********************************
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
eststo: 		regress		z_ks2eng ib2.group if trial==`l', base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase title("{\b Trial `l' effect on KS2 English Score ( crude CC)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}

***
*** Probability of receiving 5+ GCSE Grades A* to C:
*******************************************************************
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
eststo:			logistic	passac5 ib2.group if trial==`l', base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide eform b(2) ci(2) alignment(l) nonumbers mtitles("Odds Ratio 5+ GCSE Grades A* to C" "CI") nobase title("{\b Trial `l' Odds Ratio 5+ GCSE Grades A* to C (crude CC)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}

***
*** Probability of receiving SEN support:
***
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
eststo:			logistic	sen_ever ib2.group if trial==`l', base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide eform b(2) ci(2) alignment(l) nonumbers mtitles("SEN Support" "CI") nobase title("{\b Trial `l' Odds of receiving SEN support (crude CC)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}


********************************************************************************
*				- MULTIPLE IMPUTATION -							 			   
********************************************************************************
*LOAD DATASET*
use				"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_mainoutcomes.dta", clear
egen			z_gcseeng = rowmean(z_gcseeng_t*)
egen			z_ks2mat = rowmean(z_ks2mat_t*)
egen			z_ks2eng = rowmean(z_ks2eng_t*)

*MERGE IN AGE AT KS4**
merge m:1 		studyid1 using "S:\Head_or_Heart\max\post-trial-extension\1-data\finalsampleandmainoutcomes.dta", keepusing(age_*)
drop if			_merge==2 
drop			_merge 

*DESCRIBE DATASET*
tab 			trial group if _mi_m==0, m  // no breastfed ones
tab 			trial group if _mi_m==0, m  //  1,727 kids (09 May 2020)
drop 			if group ==3
drop 			if died==1

***
*** z-score GCSE English: ***
*** CRUDE
preserve
* drop participants that were too young for GCSE in the NPD
drop if			((age_ks4 <15 & age_ks4 >16) | age_ks4==. ) & trial==7
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
eststo: 		mi estimate, post: regress	z_gcseeng ib2.group if trial==`l', base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers mtitles("GCSE English Z-score" "CI") nobase title("{\b Trial `l' primary analysis crude MI}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
*** ADJUSTED
eststo: 		mi estimate, post: regress	z_gcseeng ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers mtitles("GCSE English Z-score" "CI") nobase title("{\b Trial `l' primary analysis (adjusted MI)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo clear
}
restore

***
*** z-score KS2 Maths: ***
*** CRUDE
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
eststo: 		mi estimate, post: regress z_ks2mat ib2.group if trial==`l', base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers  mtitles("{\b Trial `l' effect on KS2 Maths Score (crude MI)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
*** ADJUSTED
eststo: 		mi estimate, post: regress z_ks2mat ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu  if trial==`l' , base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers  mtitles("{\b Trial `l' effect on KS2 Maths Score (adjusted MI)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}


***
*** z-score KS2 English: ***
*** CRUDE
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
eststo: 		mi estimate, post: regress z_ks2eng ib2.group if trial==`l', base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase title("{\b Trial `l' effect on KS2 English Score (crude MI)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
*** ADJUSTED
eststo: 		mi estimate, post: regress z_ks2eng ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase title("{\b Trial `l' effect on KS2 English Score (adjusted MI)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}


***
*** Probability of receiving 5+ GCSE Grades A* to C: ***
*** CRUDE
preserve
* drop participants that were too young for GCSE in the NPD
drop if			((age_ks4 <15 & age_ks4 >16) | age_ks4==. ) & trial==7
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
eststo: 		mi estimate, post : logistic passac5 ib2.group if trial==`l', base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide eform b(2) ci(2) alignment(l) nonumbers mtitles("Odds Ratio 5+ GCSE Grades A* to C" "CI") nobase title("{\b Trial `l' Odds Ratio 5+ GCSE Grades A* to C (crude MI)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
*** ADJUSTED
eststo: 		mi estimate, post : logistic passac5 ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l' , base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide eform b(2) ci(2) alignment(l) nonumbers mtitles("Odds Ratio 5+ GCSE Grades A* to C" "CI") nobase title("{\b Trial `l' Odds Ratio 5+ GCSE Grades A* to C (adjusted MI)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}
restore


***
*** Probability of receiving SEN support: ***
*** CRUDE
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
eststo: 		mi estimate, post: logistic sen_ever ib2.group if trial==`l', base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide eform b(2) ci(2) alignment(l) nonumbers mtitles("SEN Support" "CI") nobase title("{\b Trial `l' Odds of receiving SEN support (crude MI)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
*** ADJUSTED
eststo: 		mi estimate, post: logistic sen_ever ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l' , base	
esttab 			using 5-documents\ch6secondaryanalyses.rtf, noconstant append label r2 wide eform b(2) ci(2) alignment(l) nonumbers mtitles("SEN Support" "CI") nobase title("{\b Trial `l' Odds of receiving SEN support (adjusted MI)}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}

				 
*CLOSE ANALYSIS*
timer 	list 1
timer 	clear 
log 	close





