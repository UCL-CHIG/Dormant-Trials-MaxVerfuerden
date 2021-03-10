/*==============================================================================
purpose: 		Extract school year
date 
created: 		07/08/2019
last updated: 	07/08/2019
author: 		maximiliane verfuerden
===============================================================================*/
preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", clear
tempfile	year
keep if 	strpos(npdfieldreference, "YEAR")>0  | strpos( npdfieldreference, "year")>0 
keep if 	strpos(indicatorvalue, "20")>0
drop		tableid laestab unique acyear
replace		indicatorvalue= trim(indicatorvalue)
drop if		indicatorvalue==""
sort		pupilreference dataset npdfieldreference indicatorvalue
by			pupilreference dataset npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 															
drop		dup
tab			npdfieldreference
gen			year2 = indicatorvalue if strpos(npdfieldreference, "Y2YEAR")>0 
gen			year6 = indicatorvalue if strpos(npdfieldreference, "Y6YEAR")>0 
gen			year9 = indicatorvalue if strpos(npdfieldreference, "Y9YEAR")>0 
gen			year11 = indicatorvalue if strpos(npdfieldreference, "Y11YEAR")>0 
tab			dataset
gen			KS1year = indicatorvalue if strpos(dataset, "KS1")>0 
gen			KS2year = indicatorvalue if strpos(dataset, "KS2")>0 
gen			KS3year = indicatorvalue if strpos(dataset, "KS3")>0 
gen			KS4year = indicatorvalue if strpos(dataset, "KS4")>0 
drop		dataset npdfieldreference indicatorvalue 
by          pupilreference, sort: gen jvar = _n
tab			jvar 																
reshape		wide KS* year*, i(pupilreference) j(jvar)  
dropmiss	_all, force															
destring 	_all, replace 														
rename		year21 year_2 														
egen		year_6 = rowmin(year6*)		
egen		year_9 = rowmin(year9*)	
egen		year_11 = rowmin(year11*)
drop		year6* year9* year11*
egen		year_KS1 = rowmin(KS1*)		
egen		year_KS2 = rowmin(KS2*)	
egen		year_KS3 = rowmin(KS3*)
egen		year_KS4 = rowmin(KS4*)
drop		KS*
save		`year'
restore
merge		m:1 pupilreference using `year'
drop if		_merge==2 											
drop		_merge