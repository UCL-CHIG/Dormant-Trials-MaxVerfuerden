/*==============================================================================
purpose: 		evaluate linkage for LCPUFAT RCT
date 
created: 		29/03/2019
last updated: 	29/04/2019
last updated: 	21/04/2020
author: 		maximiliane verfuerden
===============================================================================*/
clear
cd 			"S:\Head_or_Heart\max\post-trial-extension"
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
cap qui		do "S:\Head_or_Heart\max\attributes\7-ado\dropmiss.ado"
cap	qui		do "S:\Head_or_Heart\max\attributes\7-ado\renvars.ado"
cap qui 	do	"S:\Head_or_Heart\max\post-trial-extension\00-ado\groups.ado"
set 		checksum off
capture 	log close
log 		using "${logdir}\04-ev_linkage_trial_5 $S_DATE.log", replace 
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\linktable.dta", clear 
duplicates 	tag studyid, gen(dup_studyid)
********************************************************************************
*            merge in trial                    						   
********************************************************************************
merge 		m:1 studyid using "S:\Head_or_Heart\max\archive\1-data\populationforfft_deidentified 2.dta", keepusing(trial)
drop if		_merge==1
gen			unmatched =0
replace		unmatched =1 if _merge==2
drop		_merge
drop		tableid
********************************************************************************
*           merge in birth characteristics 
********************************************************************************
merge 		m:1 studyid using "S:\Head_or_Heart\max\attributes\1-Data\all\attributedataset_randomised.dta", update keepusing(bayley_PDI bayley_MDI parity byr smokdur matage matedu alcdur apgar5m kps_fullscore iq_score centre gestage bwt multiple address_tot age_firstadd age_lastaddgrp age_lastadd fup*)
replace		unmatched =1 if _merge==2
drop		_merge
********************************************************************************
*           keep only those from LCPUFAT RCT               
********************************************************************************
keep if		trial==5
********************************************************************************
*           merge in academic year info                                
********************************************************************************
merge 		m:1 pupilreference using "S:\Head_or_Heart\max\post-trial-extension\1-data\alldatawide.dta", keepusing(*acy* obs) 
drop if		_merge == 2 // some pupilrefs dont have a linked studyid (drop these) 
drop		_merge // but keep unmatched study IDs
egen		rct5_avg1stacyr = mean(first_acyr)
lab var		rct5_avg1stacyr "RCT 5 average first academic year"
********************************************************************************
*           are there any study ID duplicates?                           
********************************************************************************
count if	dup_studyid>0 & dup_studyid !=. 
count if	studyid1==""
********************************************************************************
*           are there any pupil ID duplicates?                            
********************************************************************************
duplicates 	tag pupilref if pupilref!=. , gen(dup_pupilid)
count if	dup_pupilid>0 & dup_pupilid<.
/*==============================================================================*/
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\04-ev_linkage_t5.dta", replace
log 		close