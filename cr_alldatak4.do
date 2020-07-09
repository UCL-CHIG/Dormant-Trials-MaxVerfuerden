/*******************************************************************************
purpose: 		Extract KS4 Exam points, grades and years from alldata.dta
date 
created: 		01/08/2019
last updated: 	06/08/2019
author: 		maximiliane verfuerden

*******************************************************************************/


********************************************************************************
*		    KS4 from all data				 	  		  			   *
********************************************************************************

/* maybe I should convert GRADES DIRECTLY?*/

preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", clear
tempfile	ks4alldata
count		// 1,766,399
keep if 	strpos(dataset, "KS4")>0 | strpos(npdfieldreference, "KS4")>0 | strpos(npdfieldreference, "Ks4")>0 | strpos( dataset, "ks4")>0 | strpos(npdfieldreference, "ks4")>0  // (982,154 observations deleted)

* which variables in KS4 have the most entries?
tab			npdfieldreference, sort
keep if 	strpos(npdfieldreference, "HPG")>0 | strpos(npdfieldreference, "PTST")>0  | strpos(npdfieldreference, "PTSC")>0 | strpos(npdfieldreference, "APMAT")>0 | strpos(npdfieldreference, "APENG")>0  | strpos(npdfieldreference, "SLOT")>0 | strpos(npdfieldreference, "A8")>0  | strpos(npdfieldreference, "ENGLAN")>0  // (748,049 observations deleted)
drop if		strpos(npdfieldreference, "GPTS")>0 // (884 observations deleted)
drop if		strpos(npdfieldreference, "PTSCAP")>0 | strpos(npdfieldreference, "VAPTSC")>0 | strpos(npdfieldreference, "NEWG")>0 | strpos(npdfieldreference, "OLDG")>0 // (6,788 observations deleted)
tab			npdfieldreference, sort
replace		acyear= trim(acyear) // (0 real changes made)
replace		indicatorvalue= trim(indicatorvalue) // (191 real changes made)
drop if		indicatorvalue=="" 	// (18,605 observations deleted)
drop		tableid laestab unique
sort 		pupilref* dataset npdfieldreference // for browsing the variables

/* drop all duplicates except for the first observation*/
sort		pupilreference dataset acyear npdfieldreference indicatorvalue
by			pupilreference dataset acyear npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 // (27 observations deleted)
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
drop if		gcse_mat_hp==. & gcse_total==. & gcse_capped==. & gcse_eng_hp==. & yr_gcse_mat_hp=="" & yr_gcse_eng_hp==""  // (158 observations deleted)

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
drop		if dup>1 // (7,273 observations deleted)
duplicates 	tag pupilreference, gen(duppid)
tab			duppid 	 // no duplicates yay!
drop		dup*

// histogram	gcse_capped, freq
// histogram	gcse_total, freq
// br if 		gcse_total <200	

			
count		// 2,619
save		`ks4alldata'
restore

merge		m:1 pupilreference using `ks4alldata'
drop if		_merge==2
drop		_merge






/*
/* attempted Maths at GCSE (KS4)*/
gen			gcse_mat_att =.
replace		gcse_mat_att =1 if indicatorvalue=="1" & strpos(npdfieldreference, "GCSE_MATHATT")>0  
lab var		gcse_mat_att "GCSE maths attempted"
gen			yr_gcse_mat_att = acyear if gcse_mat_att ==1
lab var		yr_gcse_mat_att "year GCSE maths attempted"

/* GCSE Maths: level*/
gen			gcse_mat_lev = indicatorvalue if strpos(npdfieldreference, "LEVELGMATH")>0  
destring	gcse_mat_lev, replace
gen			yr_gcse_mat_hp = acyear if gcse_mat_hp !=.
lab var		yr_gcse_mat_hp "year gcse maths attempted from result field"

/* GCSE Maths: passed A-G*/
gen			gcse_mat_ag = indicatorvalue if strpos(npdfieldreference, "GCSE_MATHAG")>0  
destring	gcse_mat_ag, replace
lab var		gcse_mat_ag "passed GCSE maths A-G"



/* Maths at KS2*/
gen			ks2_mat_raw = indicatorvalue if strpos(npdfieldreference, "MTOT")>0 
lab var		ks2_mat_raw "maths total aw score ks2 (out of 100)"
gen			ks2_mat_fg = indicatorvalue if strpos(npdfieldreference, "MATT_FG")>0 & !(strpos(npdfieldreference, "FLAG")>0)
destring	ks2_mat_fg, replace
lab var		ks2_mat_fg "maths fine grade ks2"
gen			ks2_mat_lev	= indicatorvalue if strpos(npdfieldreference, "MATT")>0 & !(strpos(npdfieldreference, "FLAG")>0) & !(strpos(npdfieldreference, "FG")>0) 
lab var		ks2_mat_lev "maths level ks2 (contains non-numeric)"

* clean string outcomes to make them numeric
* creates a local with characters to remove, the loops through the variables that
* need to be stripped of these characters 
tab 		ks2_mat_raw
replace		ks2_mat_raw ="0" if ks2_mat_raw=="A"
local 		remove "_NV - B T Z"
di			"`remove'"
foreach		x of varlist ks2_mat_raw   {
foreach		y of local remove {
replace		`x' =subinstr(`x', "`y'", "",.)
}	
}
foreach		x of varlist ks2_mat_raw {
cap 		destring `x', replace 
}
tab 		ks2_mat_raw


*/
