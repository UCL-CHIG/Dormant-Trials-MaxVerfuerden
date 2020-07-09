/*******************************************************************************
purpose: 		do some initial evaluation and then evaluate linkage 
				for original preterm (Trial 1 and 2)
date created: 	04/04/2019
last updated: 	29/04/2019
				20/04/2020 
				edit: will use the dataset sent to FFT as basis 
				(not attribute data) because it is more recently cleaned. 
				Also its the dataset that FFT used(minus the trial data).
author: 		maximiliane verfuerden
*******************************************************************************/

*HOUSEKEEPING*
clear
cd 			"S:\Head_or_Heart\max\post-trial-extension"
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
cap qui		do "S:\Head_or_Heart\max\attributes\7-ado\dropmiss.ado"
cap	qui		do "S:\Head_or_Heart\max\attributes\7-ado\renvars.ado"
cap qui 	do	"S:\Head_or_Heart\max\post-trial-extension\00-ado\groups.ado"

* set log*
capture 	log close
log 		using "${logdir}\04-ev_linkage_trial_5 $S_DATE.log", replace 
timer 		clear
timer 		on 1


*LOAD DATASET*
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\linktable.dta", clear // this is the FFT file that gives me all the possible links
duplicates 	tag studyid, gen(dup_studyid)
count if	dup_studyid>0 // yes there are -369- duplicate study IDs
count if	pupilreference==. 
count if	studyid1=="" 

*PREPARE DATASET*
*merge in date of birth from trial data and assigned group*
/*merge 	m:1 studyid using "S:\Head_or_Heart\max\attributes\1-Data\all\basicinfo.dta", keepusing(*dob* sex trial *group*)*/
merge 		m:1 studyid using "S:\Head_or_Heart\max\archive\1-data\populationforfft_deidentified 2.dta", keepusing(*dob* *exp* idmulti* *oth* sex trial  *twotrials* *group*)
count if 	_merge==1 // none
count if	pupilreference==. 
count if	studyid1=="" 
gen			unmatched =0
replace		unmatched =1 if _merge==2
drop		_merge
drop		tableid
rename 		sex RCTsex
duplicates 	report studyid1 


*INITIAL EVALUATION *

*children who participated in multiple trials
tab 		twotrials, m

/*
duplicates 	tag studyid1, gen(hasmultmatches) 
tab			hasmultmatches twotrials, m col
*/

codebook	studyid1 if  (group==1 | group==2 | group==3 ) & unmatched ==0
duplicates 	report studyid1 if (group==1 | group==2 | group==3 ) & unmatched ==0
sort		studyid1
by			studyid1:	gen dup = cond(_N==1,0,_n)
tab			trial unmatched if dup <2 & group !=. & group!=4 , m
generate	byr = year(d_dob)
tab			byr unmatched if dup <2 & group !=. & group!=4 , m
tab			group unmatched if dup <2 & group !=. & group!=4 , m col

* total randomised
sort 		studyid1 dup 
tab			trial if dup <2 & group !=. & group!=4 , m
tab			trial unmatched if dup <2 & group !=. & group!=4 , m

* total randomised candidate pairs
tab			trial unmatched if group !=. & group!=4 , m 

* 1:1 matches by trial
tab 		trial if unmatched==0 & group!=4 & group!=. & dup ==0

* 1:many matches by trial
tab 		trial if unmatched==0 & group!=4 & group!=. & dup ==1 // 1 only assigned to those with a least 1 duplicate
tab 		trial if unmatched==0 & group!=4 & group!=. & dup> 0 // 1 only assigned to those with a least 1 duplicate
* no matches by trial
tab 		trial if unmatched==1 & group!=4 & group!=.  // 1 only assigned to those with a least 1 duplicate

* who links who shouldnt and the other way around?
tab			exp_no_npd unmatched if dup <2 & group !=. & group!=4, m
tab			trial exp_no_npd  if unmatched==0 & dup <2 & group !=. & group!=4, m
tab			trial unmatched if dup <2 & group !=. & group!=4 & trial !=1 & trial !=2, m
gen			group2 = group
replace		group2 = 2 if group==3
tab 		group group2
tab			trial group2 if dup <2 & group !=. & group!=4 & trial !=1 & trial !=2, m
tab			trial group2 if dup <2 & trial !=1 & trial !=2, m

*MERGE IN BIRTHCHARATERISTICS AND ADDRESSES*
merge 		m:1 studyid using "S:\Head_or_Heart\max\attributes\1-Data\all\attributedataset_randomised.dta", update keepusing(byr bayley* parity smokdur died matage iq_score *iq* matedu alcdur apgar5m kps_fullscore teen centre gestage bwt multiple* address_tot age_firstadd age_lastaddgrp age_lastadd fup*)
replace		unmatched =1 if _merge==2
count if	pupilreference==. // 1,569
count if	studyid1=="" // 0
drop		_merge
duplicates 	report studyid1 if (group==1 | group==2 | group==3 ) & unmatched ==0 & multiple_birth==1

*FOR PROTOCOL FLOW DIAGRAM*	
tab			group2 unmatched if dup <2 & group !=. & group!=4 & trial !=1 & trial !=2, m
tab			unmatched if dup <2 & group !=. & group!=4 & trial !=1 & trial !=2, m
tab			bayley group2 if dup <2 & group !=. & group!=4 & trial !=1 & trial !=2, m
tab			iq group2 if dup <2 & group !=. & group!=4 & trial !=1 & trial !=2, m
tab			died group2 if dup <2 & group !=. & group!=4 & trial !=1 & trial !=2, m
* no follow-up planned for iron, sn-2 and nucleotides, how many?
tab			trial group2 if dup <2 & group !=. & group!=4 & (trial ==6 | trial==7 | trial==9), m
tab			trial group2 if dup <2 & group !=. & group!=4 & (trial ==6 | trial==9 ), m
tab			trial iq if dup <2 & group !=. & group!=4 & (trial !=1 & trial !=2), m // all but trials 4,5, and 8 not planned
tab			trial group2 if dup <2 & group !=. & group!=4 & (trial !=1 & trial !=2 & trial !=4 & trial !=5 & trial !=8), m 
** children who participated in multiple trials
tab 		twotrials, m


********************************************************************************
*   keep only those from trial 1                    
********************************************************************************
tab			trial
keep if		trial==1 | trial==2
count if	trial==1 //478
tab			group, m 
count if	pupilreference==. // 1,018
count if	studyid1=="" // 0


********************************************************************************
*   I need a variable for birthyear later on                
********************************************************************************
gen			birthyear = year(d_dob) 


********************************************************************************
*   merge in academic year info                                *
********************************************************************************
merge 		m:1 pupilreference using "S:\Head_or_Heart\max\post-trial-extension\1-data\alldatawide.dta", keepusing(*acy* obs)
count if	pupilreference==. // 1,018
count if	studyid1=="" // 2,633
drop if		_merge == 2 // some pupilrefs dont have a linked studyid (drop these) 
drop		_merge // but keep unmatched study IDs
count		// 1,785
count if	pupilreference==. // 1,018
count if	studyid1=="" // 0
egen		rct1_avg1stacyr = mean(first_acyr)
lab var		rct1_avg1stacyr "RCT 1 average first academic year"


********************************************************************************
*   are there any study ID duplicates?                           
********************************************************************************
count if	dup_studyid>0 & dup_studyid !=. // yes there are ----57---- duplicate study IDs
count if	studyid1=="" // 0
/* having duplicate study ids mean that one kid matches to different pupil nrs 
since its one row per studyid*/


********************************************************************************
*                are there any pupil ID duplicates?                            *
********************************************************************************
duplicates 	tag pupilref if pupilref!=. , gen(dup_pupilid)
count if	dup_pupilid>0 & dup_pupilid<. // yes there are ----17---- duplicate pupil IDs
/* having duplicate pupil ids mean that multiple kids match to the same pupil nrs 
This trial has twins / triplets.  */


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
count if	firstagelink >20 // 4
egen		rct1_avgage1stlink = mean(firstagelink)
lab var		rct1_avgage1stlink "RCT 1 average first age at link"


********************************************************************************
*            drop those with missing birthyear					               *
********************************************************************************
drop if		birthyear==.
count		// 852


********************************************************************************
*          before I choose the correct pairs I'll tag "true matches"            *
********************************************************************************

gen			truematch =0 
lab var		truematch "goldstandard true match"
lab def		truefalse 0"-" 1"+"
lab val		truematch truefalse

* if any 3 are completely matching
replace		truematch =1 if (fnscore ==1 | fnscore ==2 | fnscore ==3 ) & snscore==3 & (locationscore ==1 | locationscore ==2) & first_acyr <2004 // Orig Preterm
replace		truematch =1 if (fnscore ==1 | fnscore ==2 | fnscore ==3 ) & snscore==3 & dbscore ==1 & first_acyr <2004 // Orig Preterm
replace		truematch =1 if (fnscore ==1 | fnscore ==2 | fnscore ==3 ) & (locationscore ==1 | locationscore ==2) & dbscore ==1 & first_acyr <2004 // Orig Preterm
replace		truematch =1 if snscore==3 & (locationscore ==1 | locationscore ==2) & dbscore ==1 & first_acyr <2004 // Orig Preterm

* how many true matches among unmatched? 
tab			truematch if unmatched==0, m  // 14.56% (n=100) true matches


********************************************************************************
*          before I choose the correct pair I'll tag "false matches"           *
********************************************************************************
gen			falsematch = 0 
lab var		falsematch "potential false match"
lab val		falsematch truefalse

codebook	*score* // yes, the scores I chose to define match are correct

* if none of the determinants has a good score
replace		falsematch =1 if (fnscore!=1 | fnscore!=2 | fnscore!=3) & snscore!=3 & dbscore!=1 & (locationscore !=1 & locationscore !=2 ) 

*by academic year
replace		falsematch =1 if first_acyr >2003 & first_acyr !=.
replace		falsematch =1 if last_acyr >2004 & last_acyr !=.
replace		falsematch =1 if firstagelink > 18 & firstagelink !=.

* how many false matches? 
tab			falsematch, m 
count if	falsematch ==1 // these are all unmatched
replace		falsematch =. if unmatched==1 
count		if falsematch ==1 // 199

********************************************************************************
* 		tag those that were manually reviewed                                  *
********************************************************************************
gen			manuallyreviewed =0
replace		manuallyreviewed =1 if truematch==1 | falsematch==1 
tab			manuallyreviewed

order		studyid1 pupilreference manuallyreviewed truematch falsematch birthyear first_acyr
sort		trial d_dob first_acyr

tab			truematch falsematch if manuallyreviewed ==1 & unmatched==0 
count		if truematch==1 & falsematch==1 // 0 overlapping


********************************************************************************
* save this file as evaluation dataset										   *
********************************************************************************
cap drop 	dup byr
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\04-ev_linkage_t1.dta", replace




				

		
