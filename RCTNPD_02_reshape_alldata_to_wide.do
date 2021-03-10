/*==============================================================================
purpose: 	Reshape the FFT "alldata"-dataset so that there is one row per pupil
date 
created: 	20/02/2019
updated:	14/05/2019
author: 	maximiliane verfuerden
notes: 		this should also contain data from alldata_subj. 
			This is important because it contains 
			info on who sat KS4 and KS2 exams
===============================================================================*/
clear
cd 			"S:\Head_or_Heart\max\post-trial-extension"
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
cap 		do "S:\Head_or_Heart\max\attributes\7-ado\dropmiss.ado"
cap			do "S:\Head_or_Heart\max\attributes\7-ado\renvars.ado"
capture 	log close
log 		using "${logdir}\02_reshape_alldatatowide $S_DATE.log", replace 
use			"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", clear
// want to have one row per participant with academic years and datasets
keep		pupilreference dataset acyear
* how many unique pupilreferences?
codebook	pupilreference
* create jvar
by          pupilreference, sort: gen jvartest = _n
drop		jvartest
/*******************************************************************************
* exclude duplicates based on pupilreference dataset and acyear
*******************************************************************************/
duplicates	report pupilreference dataset acyear
duplicates	drop pupilreference dataset acyear, force 
* count how many unique academic years per pupil
split 		acyear, p("/") 
drop		acyear
destring	acyear*, replace
drop 		acyear2
rename		acyear1 acyear
lab var		acyear "year starting"
by          pupilreference acyear, sort: gen acyrs = _n ==1
replace		acyrs = 0 if acyear==.
by			pupilreference: replace acyrs= sum(acyrs)
by			pupilreference: replace acyrs= acyrs[_N]
codebook	acyrs 
* none accidentally dropped?
codebook	pupilreference
/*******************************************************************************
* reshape to wide
*******************************************************************************/
* generate new jvar
by          pupilreference, sort: gen jvar = _n
tab			jvar 
reshape		wide dataset acyear acyrs, i(pupilreference) j(jvar)  
dropmiss	_all, force
/*******************************************************************************
* datasets per pupil?
*******************************************************************************/
* how many datasets per pupil?
egen		datasets=rownonmiss(dataset*), strok // strok = includes strings 
codebook	datasets 
lab var		datasets "nr of linking datasets in alldata"
/*******************************************************************************
academic year
*******************************************************************************/
* how many unique academic years per pupil?
rename		acyrs1 a_acyrs
drop 		acyrs*
rename		a_acyrs acyrs
tab			acyrs
lab var		acyrs "distinct academic years linked"
* earliest ac year
egen		first_acyr = rowmin(acyear*)
lab var		first_acyr "first observed academic year"
* latest ac year
egen		last_acyr = rowmax(acyear*)
lab var		last_acyr "last observed academic year"
* observation period
gen			obsperiod = (last_acyr-first_acyr)+1
lab var		obsperiod "observation period in NPD"
* any missed years in obs period?
gen			nrmissedyrs = obsperiod-acyrs
order		pupilreference nrmissedyrs acyrs datasets obsperiod first_acyr last_acyr 
compress
save		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldatawide.dta", replace
cap			log close