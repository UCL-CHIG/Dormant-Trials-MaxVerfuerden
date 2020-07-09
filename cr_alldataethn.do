/*******************************************************************************
purpose: 		Extract ethnicity / first language
date 
created: 		07/08/2019
last updated: 	07/08/2019
author: 		maximiliane verfuerden

*******************************************************************************/

preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", clear
tempfile	firstlang
count		// 1,766,399

* where is ethnicity saved?
tab			npdfieldreference, sort

// I think LANG1ST and FirstLanguage give an indication but there is no ethnicity variable

* keep only academic year and ethn related rows 
keep if 	strpos(npdfieldreference, "LANG")>0 | strpos(npdfieldreference, "FirstLanguage")>0 // (1,744,192 observations deleted)
drop		tableid laestab unique dataset
tab			npdfieldreference, sort

* clean value field
replace		indicatorvalue= trim(indicatorvalue) // (60 real changes made)
drop if		indicatorvalue=="" 		// (1,970 observations deleted)

tab			indicatorvalue

gen			draft_ = 1 if indicatorvalue !="ENG"
replace		draft_ =0 if draft_==.
tab			indicatorvalue draft_
bysort 		pupilreference: egen engnotfirstlang = max(draft_) 
tab			indicatorvalue engnotfirstlang

* clean up
keep		pupilreference engnotfirstlang

* drop all duplicates 
sort		pupilreference engnotfirstlang 
by			pupilreference engnotfirstlang :	gen dup = cond(_N==1,0,_n)
drop		if dup>1 // (17,361 observations deleted)

duplicates 	tag pupilreference, gen(duppid)
tab			duppid 	 // no duplicates yay!

drop		dup*

compress


* merge the new variables in
count		// 2,876
save		`firstlang'
restore

merge		m:1 pupilreference using `firstlang'
drop if		_merge==2
drop		_merge
