/*==============================================================================
purpose: merge rct group and id to school id data
date created: 19/12/2018
date updated:
author: maximiliane verfuerden
===============================================================================*/
clear
cd 			"S:\Head_or_Heart\max\post-trial-extension"
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
capture 	log close
log 		using "${logdir}\02_link linkrctschool $S_DATE.log", replace 
timer 		clear
timer 		on 1
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\linktable.dta", clear
/* 																				I want one line per individual - there are multiple possible matches for each participant
																				some have higher some lower probabilities. I will sort by participant ID then matchscore */
gsort		studyid1 -matchprobability 	// 										sort in ascending ID order with the highest matchprobabilities first
by       	studyid1, sort: gen n = _n==1 // 									flag the studyid with the highest matchprobability with n=1 (all others are n=0)
keep if		n==1d
keep		tableid studyid1 pupilreference matchprobability			
**************************** MERGE IN GROUP ************************************
merge 1:1 studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\all\basicinfo.dta"
cap drop if	_merge==1 | _merge==2 
cap drop 	_merge
rename 		sex RCTsex
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\idsandtrialgroups.dta", replace
**************************** SPLIT BY TRIAL ************************************
********************************************************************************
use "S:\Head_or_Heart\max\post-trial-extension\1-data\idsandtrialgroups.dta", clear
by          pupilreference, sort: gen unique = _n==1 							// ok, will split by trial because some participants were in multiple trials otherwise pupilnumber not unique
preserve
keep if 	trial ==1
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\idsandtrialgroups_trial1.dta", replace
cap drop		_merge
restore
preserve
keep if 	trial ==3 															// remember: there is no trial 2 (- thats within trial 1)
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\idsandtrialgroups_trial3.dta", replace
cap drop		_merge
restore
preserve
keep if 	trial ==4
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\idsandtrialgroups_trial4.dta", replace
cap drop		_merge
restore
preserve
keep if 	trial ==5
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\idsandtrialgroups_trial5.dta", replace
cap drop		_merge
restore
preserve
keep if 	trial ==6
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\idsandtrialgroups_trial6.dta", replace
cap drop		_merge
restore
preserve
keep if 	trial ==7
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\idsandtrialgroups_trial7.dta", replace
cap drop		_merge
restore
preserve
keep if 	trial ==8
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\idsandtrialgroups_trial8.dta", replace
restore
preserve
keep if 	trial ==9
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\idsandtrialgroups_trial9.dta", replace
cap cap drop		_merge
restore
*===============================================================================
timer				off 1
timer 				list 1
display as input	"time of do-file in minutes:" r(t1) / 60
timer 				clear 
log 				close