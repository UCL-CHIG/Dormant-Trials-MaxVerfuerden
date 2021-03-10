/*==============================================================================
purpose: 		Extract KS4 Exam points, grades and years from alldata.dta
date 
created: 		01/08/2019
last updated: 	06/08/2019
author: 		maximiliane verfuerden
===============================================================================*/
preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", clear
tempfile	ks4alldata
keep if 	strpos(dataset, "KS4")>0 | strpos(npdfieldreference, "KS4")>0 | strpos(npdfieldreference, "Ks4")>0 | strpos( dataset, "ks4")>0 | strpos(npdfieldreference, "ks4")>0  
* which variables in KS4 have the most entries?
tab			npdfieldreference, sort
keep if 	strpos(npdfieldreference, "HPG")>0 | strpos(npdfieldreference, "PTST")>0  | strpos(npdfieldreference, "PTSC")>0 | strpos(npdfieldreference, "APMAT")>0 | strpos(npdfieldreference, "APENG")>0  | strpos(npdfieldreference, "SLOT")>0 | strpos(npdfieldreference, "A8")>0  | strpos(npdfieldreference, "ENGLAN")>0  
drop if		strpos(npdfieldreference, "GPTS")>0 
drop if		strpos(npdfieldreference, "PTSCAP")>0 | strpos(npdfieldreference, "VAPTSC")>0 | strpos(npdfieldreference, "NEWG")>0 | strpos(npdfieldreference, "OLDG")>0 
tab			npdfieldreference, sort
replace		acyear= trim(acyear) 
replace		indicatorvalue= trim(indicatorvalue)
drop if		indicatorvalue=="" 
drop		tableid laestab unique
sort 		pupilref* dataset npdfieldreference // for browsing the variables
/* drop all duplicates except for the first observation*/
sort		pupilreference dataset acyear npdfieldreference indicatorvalue
by			pupilreference dataset acyear npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1
drop		dup
/* GCSE: capped and total point score - do z-scores per year then summarise */
gen			gcse_capped = indicatorvalue if npdfieldreference == "PTSCNEWE"
replace		gcse_capped = indicatorvalue if npdfieldreference == "PTSCNEWE_PTQ" & acyear =="2015/16" 
replace		gcse_capped = indicatorvalue if npdfieldreference == "PTSCNEWE_PTQ" & acyear =="2014/15" & gcse_capped =="" 
destring	gcse_capped, replace
sort		acyear gcse_capped 
replace 	gcse_capped = ((gcse_capped*6)+10) if acyear =="2015/16" 
tabstat		gcse_capped, by(acyear) s(mean min max) 
lab var		gcse_capped "capped GCSE and equivalent pts"
gen			gcse_total = indicatorvalue if npdfieldreference == "PTSTNEWE"
replace		gcse_total = indicatorvalue if npdfieldreference == "PTSTNEWE_PTQ_EE" & acyear =="2015/16" 
replace		gcse_total = indicatorvalue if npdfieldreference == "PTSTNEWE_PTQ_EE" & acyear =="2014/15" & gcse_total =="" 
destring	gcse_total, replace
sort		acyear gcse_total 
tabstat		gcse_total, by(acyear) s(mean min max) 
replace 	gcse_total = ((gcse_total*6)+10) if acyear =="2015/16" // cant do this! dont know how many subjects! +10 is absolute and for 1 GCSE only..
tabstat		gcse_total, by(acyear) s(mean min max) 
lab var		gcse_total "total GCSE and equivalent"
/* GCSE Maths: highest points -- this is only available from 2007!*/
gen			gcse_mat_hp = indicatorvalue if strpos(npdfieldreference, "HPGMATH")>0  
destring	gcse_mat_hp, replace
* convert to same point scale*
tabstat		gcse_mat_hp, by(acyear) s(mean min max)
tab			gcse_mat_hp acyear
recode		gcse_mat_hp 1=16 2=22 3=28 4=34 5=40 6=46 7=52 8=58
tabstat		gcse_mat_hp, by(acyear) s(mean min max)
tab			gcse_mat_hp acyear
lab var		gcse_mat_hp "highest points gcse maths KS4"
gen			yr_gcse_mat_hp = acyear if gcse_mat_hp !=.
lab var		yr_gcse_mat_hp "year gcse maths attempted"
/* GCSE English: highest points -- this is only available from 2007!*/
gen			gcse_eng_hp = indicatorvalue if strpos(npdfieldreference, "HPGENG")>0  
destring	gcse_eng_hp, replace
* convert to same point scale*
tabstat		gcse_eng_hp, by(acyear) s(mean min max)
tab			gcse_eng_hp acyear
recode		gcse_eng_hp 1=16 2=22 3=28 4=34 5=40 6=46 7=52 8=58
tabstat		gcse_eng_hp, by(acyear) s(mean min max)
tab			gcse_eng_hp acyear
lab var		gcse_eng_hp "highest points gcse english KS4"
gen			yr_gcse_eng_hp = acyear if gcse_eng_hp !=.
lab var		yr_gcse_eng_hp "year gcse english attempted"
* drop row if it has no information on either of the above produced variables:
drop if		gcse_mat_hp==. & gcse_total==. & gcse_capped==. & gcse_eng_hp==. & yr_gcse_mat_hp=="" & yr_gcse_eng_hp=="" 
* don't need these anyore:
drop		dataset acyear npdfield* indic* 
/* copy information over within pupilnumber */
bysort 		pupilreference: egen all_gcse_mat_hp = min(gcse_mat_hp)
bysort 		pupilreference: egen all_gcse_eng_hp = min(gcse_eng_hp)
bysort 		pupilreference: egen all_gcse_capped = min(gcse_capped)
bysort 		pupilreference: egen all_gcse_total = min(gcse_total)
by	 		pupilreference: replace yr_gcse_mat_hp  = yr_gcse_mat_hp[_n-1] if yr_gcse_mat_hp[_n-1] !=""
by	 		pupilreference: replace yr_gcse_mat_hp = yr_gcse_mat_hp[_N] if yr_gcse_mat_hp[_N] !=""
by	 		pupilreference: replace yr_gcse_eng_hp  = yr_gcse_eng_hp[_n-1] if yr_gcse_eng_hp[_n-1] !=""
by	 		pupilreference: replace yr_gcse_eng_hp = yr_gcse_eng_hp[_N] if yr_gcse_eng_hp[_N] !=""
drop		gcse_*
rename		all_* * 
sort		pupilreference gcse_* yr_*
by			pupilreference gcse_* yr_* :	gen dup = cond(_N==1,0,_n)
drop		if dup>1 
duplicates 	tag pupilreference, gen(duppid)
tab			duppid
drop		dup*
save		`ks4alldata'
restore
merge		m:1 pupilreference using `ks4alldata'
drop if		_merge==2
drop		_merge