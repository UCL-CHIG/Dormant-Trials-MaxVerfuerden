/*******************************************************************************
purpose: 		Extract IDACI
date 
created: 		07/08/2019
last updated: 	07/08/2019
author: 		maximiliane verfuerden

*******************************************************************************/
preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", clear
tempfile	idaci
count		// 1,766,399

* where is IDACI saved?
tab			npdfieldreference, sort

* keep only academic year and idaci related rows 
keep if 	strpos(npdfieldreference, "IDACI")>0 // (1,757,769 observations deleted)
drop		tableid laestab unique dataset

* clean idaci field
replace		indicatorvalue= trim(indicatorvalue)
drop if		indicatorvalue=="" 		// (150 observations deleted)

* generate idaci variable by row
tab			indicatorvalue // all numeric between 0 and 1
destring	indicatorvalue, replace
gen			idaci = indicatorvalue
drop 		indicatorvalue npdfield*

* sort so that idaci in earliest academic years come first 	
sort		pupilreference acyear, stable	

* drop all duplicates 
sort		pupilreference acyear idaci 
by			pupilreference acyear idaci :	gen dup = cond(_N==1,0,_n)
drop		if dup>1 // (11 observations deleted)
drop		dup

* reshape so there is only one row per pupil
by          pupilreference, sort: gen jvar = _n
tab			jvar //max 5 rows per pupil
reshape		wide acyear idaci, i(pupilreference) j(jvar)  
dropmiss	_all, force // none were empty		

* average idaci per pupil
egen 		mean_idaci = rowmean(idaci*)

* earlist idaci per pupil
gen 		early_idaci = idaci1

* most recent idaci per pupil
egen		latest_idaci = rowlast(idaci*)

* improved ses over school years?
gen			idaci_improved = 1 if (latest_idaci - early_idaci)<0 & !missing(latest_idaci - early_idaci)
replace		idaci_improved = 0 if idaci_improved==.

* clean up
drop		acyear1-idaci5
compress

* merge the new variables in
count																			// 723
save		`idaci'
restore

merge		m:1 pupilreference using `idaci'
drop if		_merge==2
drop		_merge

