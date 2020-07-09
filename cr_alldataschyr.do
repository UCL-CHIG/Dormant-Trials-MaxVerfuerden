/*******************************************************************************
purpose: 		Extract school year
date 
created: 		07/08/2019
last updated: 	07/08/2019
author: 		maximiliane verfuerden

*******************************************************************************/


preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", clear
tempfile	year
count
keep if 	strpos(npdfieldreference, "YEAR")>0  | strpos( npdfieldreference, "year")>0 
keep if 	strpos(indicatorvalue, "20")>0
drop		tableid laestab unique acyear
replace		indicatorvalue= trim(indicatorvalue)
drop if		indicatorvalue==""
sort		pupilreference dataset npdfieldreference indicatorvalue
by			pupilreference dataset npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 															// 1 obs deleted
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
tab			jvar 																// 5 - this is managable
reshape		wide KS* year*, i(pupilreference) j(jvar)  
dropmiss	_all, force															// some years were dropped
destring 	_all, replace 														// (otherwise egen function cannot be used)
rename		year21 year_2 														// thats the only non empty one
egen		year_6 = rowmin(year6*)		
egen		year_9 = rowmin(year9*)	
egen		year_11 = rowmin(year11*)
drop		year6* year9* year11*
egen		year_KS1 = rowmin(KS1*)		
egen		year_KS2 = rowmin(KS2*)	
egen		year_KS3 = rowmin(KS3*)
egen		year_KS4 = rowmin(KS4*)
drop		KS*
count																			// 3,019
save		`year'
restore
count																			// 2,590
merge		m:1 pupilreference using `year'
drop if		_merge==2 															// 621 dropped
drop		_merge

/* age at grade */
gen			age_y2 = int(((mdy(09,01,year_2))-d_dob)/365.25)
gen			age_y6 = int(((mdy(09,01,year_6))-d_dob)/365.25)
gen			age_y9 = int(((mdy(09,01,year_9))-d_dob)/365.25)
gen			age_y11 = int(((mdy(09,01,year_11))-d_dob)/365.25)

/* age at SEN */
forval		y =4/35{
gen			sen_age`y' =.
}

forval 		i =2000/2015{
forval		y =4/35{
replace		sen_age`y' =1 if int(((mdy(09,01,`i'))-d_dob)/365.25) ==`y' & sen`i'==1
}
}
dropmiss	_all, force 														// some vars dropped
egen		senagepattern = concat(sen_*)
groups		senagepattern, order(high)
drop		sen_age*

********************************************************************************
*			KEY STAGES						 	  		  				       *
********************************************************************************
cap drop 		KS5 KSnone KSany 
groups		KS* census, order(high)

/* key stage ages */
gen			age_ks1 = int(((mdy(09,01,year_KS1))-d_dob)/365.25)
gen			age_ks2 = int(((mdy(09,01,year_KS2))-d_dob)/365.25)
gen			age_ks3 = int(((mdy(09,01,year_KS3))-d_dob)/365.25)
gen			age_ks4 = int(((mdy(09,01,year_KS4))-d_dob)/365.25)

/* what is the mean age at each KS by birth year? */                            // this is more of an analysis - should be done in separate do-file
forval		i=1/4{
tabstat		age_ks`i', s(mean min max n) by(birthyear)
}
