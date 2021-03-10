/*******************************************************************************
purpose: 		evaluate linkage for all RCTs together 
date 
created: 		03/04/2019
last updated: 	10/01/2020
author: 		maximiliane verfuerden
this uses appended versions of deduplicated evaluation files (true and false
matches folder)
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
log 		using "${logdir}\04.1-ev_linkage_alltrials $S_DATE.log", replace 
capture		drop _merge
********************************************************************************
*					APPEND ALL EVALUATION FILES								   *
********************************************************************************
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\04-ev_linkage_t1.dta", clear 
append 		using "${datadir}\04-ev_linkage_t3" "${datadir}\04-ev_linkage_t4.dta" "${datadir}\04-ev_linkage_t5.dta" "${datadir}\04-ev_linkage_t6.dta" "${datadir}\04-ev_linkage_t7.dta" "${datadir}\04-ev_linkage_t8.dta" "${datadir}\04-ev_linkage_t9.dta"
capture		drop _merge
merge 		m:1 studyid using "S:\Head_or_Heart\max\attributes\1-Data\importantvars.dta"
drop if 	_merge==2  
count if	studyid1=="" // 0
tab			_merge // all others match
drop		_merge 
save		"${datadir}\04.1-ev_linkage_alltrials.dta", replace
descr
count		
tab			trial group if unmatched==1
