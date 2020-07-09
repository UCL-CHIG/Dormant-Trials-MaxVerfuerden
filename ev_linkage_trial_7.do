/*******************************************************************************
purpose: 		evaluate linkage for the iron RCT
date 
created: 		03/04/2019
last updated: 	29/04/2019
last updated: 	21/04/2020 (changed source of sex and group allocation)
author: 		maximiliane verfuerden


*******************************************************************************/

********************************************************************************
* 								SET FILEPATHS 								   *
********************************************************************************
clear
cd 			"S:\Head_or_Heart\max\post-trial-extension"
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
cap qui		do "S:\Head_or_Heart\max\attributes\7-ado\dropmiss.ado"
cap	qui		do "S:\Head_or_Heart\max\attributes\7-ado\renvars.ado"
cap qui 	do	"S:\Head_or_Heart\max\post-trial-extension\00-ado\groups.ado"

********************************************************************************
*								 SET LOG 								 	   *
********************************************************************************
capture 	log close
log 		using "${logdir}\04-ev_linkage_trial_7 $S_DATE.log", replace 

********************************************************************************
*								 BASEFILE								 	   *
********************************************************************************
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\linktable.dta", clear 
// this is the FFT file that gives me all the possible links
duplicates 	tag studyid, gen(dup_studyid)
count if	dup_studyid>0 // yes there are ----369---- duplicate study IDs
count if	pupilreference==. // 0
count if	studyid1=="" // 0

********************************************************************************
*                   merge in trial d_dob and assigned group                    *
********************************************************************************
/* edit 20 Apr 2020 - will use the dataset sent to FFT as basis (not attribute data) because it is more recently cleaned. Also its the dataset that FFT used (minus the trial data)
merge 		m:1 studyid using "S:\Head_or_Heart\max\attributes\1-Data\all\basicinfo.dta", keepusing(*dob* sex trial *group*)
*/
merge 		m:1 studyid using "S:\Head_or_Heart\max\archive\1-data\populationforfft_deidentified 2.dta", keepusing(*dob* idmulti* *oth* *exp* sex trial *twotrials* *group*)
count if 	_merge==1 // those who are not in trial data? - original preterm control subjects - can be dropped
count if	pupilreference==. // 1,569
count if	studyid1=="" // 0
drop if		_merge==1
gen			unmatched =0
replace		unmatched =1 if _merge==2
drop		_merge
drop		tableid
count if	pupilreference==. // 1,569
count if	studyid1=="" // 0
rename 		sex RCTsex

********************************************************************************
*                merge in birth characteristics and addresses                  *
********************************************************************************
merge 		m:1 studyid using "S:\Head_or_Heart\max\attributes\1-Data\all\attributedataset_randomised.dta", update keepusing(bayley_PDI bayley_MDI parity smokdur matage matedu alcdur apgar5m kps_fullscore iq_score centre gestage bwt multiple address_tot age_firstadd age_lastaddgrp byr age_lastadd fup*)
replace		unmatched =1 if _merge==2
count if	pupilreference==. // 1,569
count if	studyid1=="" // 0
drop		_merge


********************************************************************************
*                            keep only those from trial 7                      *
********************************************************************************
keep if		trial==7
count if	trial==7 //517
tab			group, m 
count if	pupilreference==. // 2
count if	studyid1=="" // 0
gen			rct7plausfirstacyr = 1998


********************************************************************************
*                I need a variable for birthyear later on                      *
********************************************************************************
gen			birthyear = year(d_dob) 


********************************************************************************
*                   merge in academic year info                                *
********************************************************************************
merge 		m:1 pupilreference using "S:\Head_or_Heart\max\post-trial-extension\1-data\alldatawide.dta", keepusing(*acy* obs)
count if	pupilreference==. // 2
count if	studyid1=="" // 3,086
drop if		_merge == 2 // some pupilrefs dont have a linked studyid (drop these) 
drop		_merge // but keep unmatched study IDs
count		// 311
count if	pupilreference==. // 4
count if	studyid1=="" // 0
egen		rct7_avg1stacyr = mean(first_acyr)
lab var		rct7_avg1stacyr "RCT 7 average first academic year"


********************************************************************************
*                 are there any study ID duplicates?                           *
********************************************************************************
count if	dup_studyid>0 & dup_studyid !=. // yes there are ----47---- duplicate study IDs
count if	studyid1=="" // 0
/* having duplicate study ids mean that one kid matches to different pupil nrs 
since its one row per studyid*/


********************************************************************************
*                are there any pupil ID duplicates?                            *
********************************************************************************
duplicates 	tag pupilref if pupilref!=. , gen(dup_pupilid)
count if	dup_pupilid>0 & dup_pupilid<. // there are ----17---- duplicate pupil IDs
count if        dup_pupilid>0 & dup_pupilid<.
/* having duplicate pupil ids mean that multiple kids match to the same pupil nrs 
grr 17?? need to check this out. ok they are all twins. What to do now? is this 
a problem? they can be distinguished by firsname score and perhaps if
they are also represented in the studyid duplicates  */


********************************************************************************
*            what is the age at the first linked academic year?                *
********************************************************************************
gen			day = 1
gen			month = 9
gen			first_acdate = mdy(month,day,first_acyr)
format		first_acdate
gen			firstagelink = (first_acdate-d_dob)/365.25
replace		firstagelink = int(firstagelink)
order		pupilref studyid trial d_dob firstagelink first_acyr
count if	firstagelink <4 // 0
count if	firstagelink >20 // 6
egen		rct7_avgage1stlink = mean(firstagelink)
lab var		rct7_avgage1stlink "RCT 7 average first age at link"


********************************************************************************
*          plausibility check for "true matches"  
********************************************************************************

gen			truematch =0 
lab var		truematch "goldstandard true match"
lab def		truefalse 0"-" 1"+"
lab val		truematch truefalse

* if any 3 are completely matching
replace		truematch =1 if (fnscore ==1 | fnscore ==2 | fnscore ==3 ) & snscore==3 & (locationscore ==1 | locationscore ==2) & first_acyr >1997 & first_acyr <2013 // LC preterm
replace		truematch =1 if (fnscore ==1 | fnscore ==2 | fnscore ==3 ) & snscore==3 & dbscore ==1 & first_acyr >1997 & first_acyr <2013 // LC preterm
replace		truematch =1 if (fnscore ==1 | fnscore ==2 | fnscore ==3 ) & (locationscore ==1 | locationscore ==2) & dbscore ==1 & first_acyr >1997 & first_acyr <2013 // LC preterm
replace		truematch =1 if snscore==3 & (locationscore ==1 | locationscore ==2) & dbscore ==1 & first_acyr >1997 & first_acyr <2013 // LC preterm

* how many true matches? 
tab			truematch if unmatched==0, m  // 76.02% true matches (n=393)


********************************************************************************
*         plausibility check for "false matches"           
********************************************************************************
gen			falsematch = 0 
lab var		falsematch "potential false match"
lab val		falsematch truefalse

codebook	*score* // yes, the scores I chose to define match are correct

* if none of the determinants has a good score
replace		falsematch =1 if (fnscore!=1 | fnscore!=2 | fnscore!=3) & snscore!=3 & dbscore!=1 & (locationscore !=1 & locationscore !=2) 

*by academic year
replace		falsematch =1 if first_acyr <1998 | (first_acyr >2012 & first_acyr !=.)
replace		falsematch =1 if last_acyr <1998 | (last_acyr >2013 & last_acyr !=.)
replace		falsematch =1 if firstagelink > 18 & firstagelink !=.

* how many false matches? 
tab			falsematch, m 
replace		falsematch =. if unmatched==1 // 0% false matches (n=0)


********************************************************************************
* 		tag those that were manually reviewed                                  *
********************************************************************************
gen			manuallyreviewed =0
replace		manuallyreviewed =1 if truematch==1 | falsematch==1 
tab			manuallyreviewed

order		studyid1 pupilreference manuallyreviewed truematch falsematch birthyear first_acyr
sort		trial d_dob first_acyr

tab			truematch falsematch if manuallyreviewed ==1  // none overlapping 

********************************************************************************
* save 
********************************************************************************
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\04-ev_linkage_t7.dta", replace

