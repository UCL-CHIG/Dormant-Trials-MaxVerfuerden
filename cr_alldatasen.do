/*******************************************************************************
purpose: 		Extract special educational needs data from alldata.dta
date 
created: 		01/08/2019
last updated: 	01/08/2019
author: 		maximiliane verfuerden

*******************************************************************************/

********************************************************************************
*				ADD SPECIAL EDUCATIONAL NEEDS  		  				           *
********************************************************************************
/* I will focus on any type b/c numbers are quite small */
preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", clear
tempfile	SEN
count																			// 1,766,399
keep if 	strpos(npdfieldreference, "SEN")>0
drop if 	strpos(npdfieldreference, "PSENG")>0  | strpos( npdfieldreference, "pseng")>0 
drop		tableid laestab unique
replace		indicatorvalue= trim(indicatorvalue)
drop if		indicatorvalue==""
drop if		indicatorvalue=="N" 												// means no SEN 
drop if		indicatorvalue=="0" 												// I assume means no SEN
drop if		strpos(indicatorvalue, "No Spe")>0 									// I assume means no SEN
/* drop all duplicates except for the first observation*/
sort		pupilreference dataset acyear npdfieldreference indicatorvalue
by			pupilreference dataset acyear npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 															// 17 obs deleted
drop		dup
by          pupilreference, sort: gen jvar = _n
tab			jvar 																// 18 - this is managable 
reshape		wide dataset acyear npdfieldreference indicatorvalue, i(pupilreference) j(jvar)  
dropmiss	_all, force 														// none were empty
gen			sen_ever = 1
forval		i = 1/18 {
rename		acyear`i' senyear`i'
rename		dataset`i' sensource`i'
rename		indicatorvalue`i' senlevel`i'
}
count																			// 1,219
save		`SEN'
restore

merge		m:1 pupilreference using `SEN', keepusing(senyear* sen_ever)
drop if		_merge==2
drop		_merge
replace		sen_ever=0 if sen_ever==.
