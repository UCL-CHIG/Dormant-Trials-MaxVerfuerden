/*==============================================================================
purpose: 		Extract KS2 Exam points, grades and years from alldata.dta
date 
created: 		01/08/2019
last updated: 	01/08/2019
author: 		maximiliane verfuerden
===============================================================================*/
preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", clear
tempfile	ks2alldata
keep if 	strpos(dataset, "ks2")>0 | strpos(npdfieldreference, "ks2")>0 | strpos( dataset, "KS2")>0 | strpos(npdfieldreference, "KS2")>0
keep if 	strpos(npdfieldreference, "ERD")>0 | strpos(npdfieldreference, "MTOT")>0 | strpos(npdfieldreference, "ETOT")>0 | strpos(npdfieldreference, "ENTT_FG")>0 | strpos(npdfieldreference, "MATT_FG")>0  
* which variables in KS2 have the most entries?
tab			npdfieldreference, sort
replace		indicatorvalue= trim(indicatorvalue)
drop if		indicatorvalue=="" 		
drop		tableid laestab unique
/* drop all duplicates except for the first observation*/
sort		pupilreference dataset acyear npdfieldreference indicatorvalue
by			pupilreference dataset acyear npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 															
drop		dup
/* Maths at KS2*/
gen			ks2_mat_raw = indicatorvalue if strpos(npdfieldreference, "MTOT")>0 
gen			ks2_mat_fg = indicatorvalue if strpos(npdfieldreference, "MATT_FG")>0 & !(strpos(npdfieldreference, "FLAG")>0)
replace		ks2_mat_raw= trim(ks2_mat_raw)
lab var		ks2_mat_raw "maths total raw score ks2 (out of 100)"
lab var		ks2_mat_fg "maths fine grade ks2"
destring	ks2_mat_fg, replace
/* English at KS2*/
gen			ks2_engread_raw = indicatorvalue if strpos(npdfieldreference, "ERD")>0 
gen			ks2_engtot_raw = indicatorvalue if strpos(npdfieldreference, "ETOT")>0 
gen			ks2_engtot_fg = indicatorvalue if strpos(npdfieldreference, "ENTT_FG")>0 & !(strpos(npdfieldreference, "FLAG")>0)
replace		ks2_engread_raw= trim(ks2_engread_raw)
replace		ks2_engtot_raw= trim(ks2_engtot_raw)
lab var		ks2_engread_raw "english reading raw score ks2 (out of 50)"
lab var		ks2_engtot_raw "english total raw score ks2 (out of 100)"
lab var		ks2_engtot_fg "english total score fine grade ks2"
destring	ks2_engtot_fg, replace
drop		dataset acyear npdfield* indic*
* clean string outcomes to make them numeric
* creates a local with characters to remove, the loops through the variables that need to be stripped of these characters 
replace		ks2_mat_raw ="0" if ks2_mat_raw=="A" // "A" = absence
replace		ks2_engread_raw ="0" if ks2_engread_raw=="A"
replace		ks2_engtot_raw ="0" if ks2_engtot_raw=="A"
replace		ks2_engread_raw ="0" if ks2_engread_raw=="M"
local 		remove "_NV - B T Z"
di			"`remove'"
foreach		x of varlist ks2_*_raw   {
foreach		y of local remove {
replace		`x' =subinstr(`x', "`y'", "",.)
}	
}
foreach		x of varlist ks2_*_raw {
cap 		destring `x', replace 
}
tab 		ks2_mat_raw
tab 		ks2_engread_raw
tab 		ks2_engtot_raw
* drop row if it has no information on either of the above produced variables:
drop if		ks2_mat_fg==. & ks2_engtot_fg==. & ks2_mat_raw==. & ks2_engread_raw==. & ks2_engtot_raw==. 
/* copy information over within pupilnumber */
bysort 		pupilreference: egen all_ks2_mat_raw = max(ks2_mat_raw)
bysort 		pupilreference: egen all_ks2_engread_raw = max(ks2_engread_raw)
bysort 		pupilreference: egen all_ks2_engtot_raw = max(ks2_engtot_raw)
bysort 		pupilreference: egen all_ks2_engtot_fg = max(ks2_engtot_fg)
bysort 		pupilreference: egen all_ks2_mat_fg = max(ks2_mat_fg)
drop		ks2_*_raw  ks2_*_fg 
rename		all_* * 
sort		pupilreference ks2_*_raw  ks2_*_fg 
by			pupilreference ks2_*_raw  ks2_*_fg: gen dup = cond(_N==1,0,_n)
drop		if dup>1															
duplicates 	tag pupilreference, gen(duppid)										
tab			duppid 																
drop		dup*
dropmiss	_all, force 														
save		`ks2alldata'
restore
merge		m:1 pupilreference using `ks2alldata'
drop if		_merge==2
drop		_merge