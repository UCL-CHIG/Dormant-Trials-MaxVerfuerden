/*******************************************************************************
purpose: 		Extract free school meals data from alldata dataset
date 
created: 		01/08/2019
last updated: 	01/08/2019
author: 		maximiliane verfuerden

*******************************************************************************/

********************************************************************************
*		FREE SCHOOL MEALS													   *
********************************************************************************
preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", clear
tempfile	fsm
count																			// 1,766,399
keep if 	strpos(npdfieldreference, "fsm")>0 | strpos(npdfieldreference, "FSM")>0 
drop		tableid laestab unique
replace		indicatorvalue= trim(indicatorvalue)
drop if		indicatorvalue=="" 		
drop if		indicatorvalue=="0" | indicatorvalue=="N" | indicatorvalue=="F" | indicatorvalue=="false" 	
																				// 48,801 observations deleted
replace		indicatorvalue="1" if indicatorvalue=="T" | indicatorvalue=="Y" | indicatorvalue=="true" | indicatorvalue=="True" 		
																				// 2,089 real changes made changes made	
					
/* drop all duplicates except for the first observation*/
sort		pupilreference dataset acyear npdfieldreference indicatorvalue
by			pupilreference dataset acyear npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 															// 20 observations deleted
drop		dup

/* year when fsm eligible */
gen			yr_fsm = ""
replace		yr_fsm = acyear if strpos(npdfieldreference, "FSMeligible")>0
replace		yr_fsm = acyear if strpos(npdfieldreference, "FSM")>0

/* ever fsm */
gen			ever_fsm =1

drop		dataset acyear npdfieldreference indicatorvalue

/* drop all duplicates except for the first observation*/
sort		pupilreference yr_fsm ever_fsm
by			pupilreference yr_fsm ever_fsm:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 															// 20 observations deleted
drop		dup

by          pupilreference, sort: gen jvar = _n
tab			jvar 																// 13 - this is managable
reshape		wide yr_fsm ever_fsm, i(pupilreference) j(jvar)  
dropmiss	_all, force 														// none were empty

/* ever fsm needs only one variable */
rename		ever_fsm* del_ever*
egen 		fsm_ever = rowmax(del_ever*)
drop		del*
count																			// 723
save		`fsm'
restore

merge		m:1 pupilreference using `fsm'
drop if		_merge==2
drop		_merge
replace		fsm_ever =0 if fsm_ever==.
