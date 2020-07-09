/*******************************************************************************
purpose: 		Extract K4 Exam points, grades and years from allsubj dataset
date 
created: 		01/08/2019
last updated: 	07/08/2019
author: 		maximiliane verfuerden

Notes:			I decided to only focus on 2210 and 5030 - the others don't 
				have the right distributions. They can be found in green code
				at the end of the file.
*******************************************************************************/

preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldatasubj.dta", clear
tempfile	k4allsubj
count		// 2,784,513

* clean the subject code and values
replace		leapcode= trim(leapcode) // (540 real changes made)
replace		indicatorvalue= trim(indicatorvalue) // (406,404 real changes made)
drop if		indicatorvalue=="" 	// (652,836 observations deleted)	

/* which leapcodes are there? only keep Maths and English*/
tab			leapcode, sort  // most common: 9982 (maths ks2)  9983 (science ks2), 9981 (english ks2), 2210 (GCSE Maths), 5110(GCSE English Literature), 5030(GCSE English Language), 4610 (GCSE Religion)

* keep only rows that relate to mathematics and english subject codes
keep if 	strpos(leapcode, "2210")>0 | strpos(leapcode, "5030")>0 //(1,922,582 observations deleted)

/* which datasets are there? only keep ks4*/
tab			dataset, sort // ks2Exam and ks4Exam
keep if 	strpos(dataset, "ks4")>0 // (0 observations deleted)

* which academic years does this dataset span?
tab			acyear // 2003/04 to 2015/16

* which variables are available for these subjects?
tab			npdfieldreference, sort // 

* keep only rows that contain info about grade, points and examyear
keep if 	strpos(npdfieldreference, "GRADE")>0 | strpos(npdfieldreference, "POINTS")>0 | strpos(npdfieldreference, "EXAMYEAR")>0 // (178,717 observations deleted)
count		// 30,378

* delete variables I won't use
drop		tableid laestab unique dataset qan

/* drop all duplicates except for the first observation*/
sort		pupilreference leapcode acyear npdfieldreference indicatorvalue
by			pupilreference leapcode acyear npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 	// (2,395 observations deleted)
drop		dup

/* Exam year: copy info over to all rows with same pupil examyear and subject */
levelsof	leapcode, local(levels)
foreach		l of local levels {
gen			ks4_examyr_`l'= indicatorvalue if strpos(npdfieldreference, "EXAMYEAR")>0 & strpos(leapcode, "`l'")>0 
destring	ks4_examyr_`l', replace
bysort 		pupilreference: egen all_ks4_examyr_`l' = min(ks4_examyr_`l')
}

/* drop the variables that are not copied over */
levelsof	leapcode, local(levels)
foreach		l of local levels {
drop		ks4_examyr_`l'
}
rename		all_* * 

* which exam years does this dataset span?
tab			ks4_examyr_2210 // 2003-2016
tab			ks4_examyr_5030 // 2005-2016 // ok THIS NEEEDS TO BE INVESTIGATED

/* drop all duplicates, now examyear takes priority over acyear */
sort		pupilreference leapcode ks4_examyr* npdfieldreference indicatorvalue
by			pupilreference leapcode ks4_examyr* npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 															// (11,428 observations deleted)
drop		dup 

* dont need these rows anymore - drop examyear rows:
drop if		strpos(npdfieldreference, "EXAMYEAR")>0


/* POINTS and GRADE: create variables for each person by examyear and subject */
levelsof	leapcode, local(levels)
foreach		i of num 2003/2016   {
foreach		l of local levels {
gen			points`l'_`i' = indicatorvalue if ks4_examyr_`l'==`i' & strpos(npdfieldreference, "POINTS")>0  & strpos(leapcode, "`l'")>0 
gen			grade`l'_`i' = indicatorvalue if ks4_examyr_`l'==`i' & strpos(npdfieldreference, "GRADE")>0  & strpos(leapcode, "`l'")>0 
}	
}

destring	*points*, replace
compress

/* POINTS and GRADE: copy info over to all rows with same pupil examyear and subject */
levelsof	leapcode, local(levels)
foreach		i of num 2003/2016   {
foreach		l of local levels {
bysort 		pupilreference: egen all_points`l'_`i' = min(points`l'_`i') 
by	 		pupilreference: replace grade`l'_`i' = grade`l'_`i'[_n-1] if !missing(grade`l'_`i'[_n-1])
by	 		pupilreference: replace grade`l'_`i' = grade`l'_`i'[_N] if !missing(grade`l'_`i'[_N]) 
}
}

levelsof	leapcode, local(levels)
foreach		i of num 2003/2016   {
foreach		l of local levels {
drop		points`l'_`i' 
}
}
rename		all_* *	

sort		pupilreference leapcode npdfi*
drop		npdfield*  indic  

/* drop all rows that contain the same information */
sort		pupilreference *exam* points* grade*
by			pupilreference *exam* points* grade*: gen dup = cond(_N==1,0,_n)
order		pupilref* dup
drop if		dup>1 // (8,448 observations deleted)
drop 		dup	

/* check I can see that the grade system changed */
levelsof	leapcode, local(levels)
foreach		i of num 2003/2016   {
foreach		l of local levels {
tab 		points`l'_`i'			
}
}
/* yes it changed from 2015 onwards 0-8 instead of 0-58 
--> in 2005 English doesnt seem right values: 14 and 90?
--> in 2010 English doesnt seem right values: 0 - 135?
--> in 2013 Maths doesnt seem right values: 0 - 120?
*/


/* clean the points b/c grade system changed*/
levelsof	leapcode, local(levels)
foreach		i of num 2003/2016   {
foreach		l of local levels {
replace 	points`l'_`i' = ((points`l'_`i'*6)+10) if (ks4_examyr_`l' ==2015 | ks4_examyr_`l' ==2016 ) 
replace 	points`l'_`i' = ((points`l'_`i'*6)+10) if (points`l'_`i'<10 & points`l'_`i'>0) 

}
}

/* check it changed the points correctly */
levelsof	leapcode, local(levels)
foreach		i of num 2003/2016   {
foreach		l of local levels {
tab 		points`l'_`i'			
}
}


* check kids have not done multiple gcses:
// yes these are all either 0 or 1 so only 1 exam sat per subject
egen		nr_2210 = rownonmiss(points2210*)
egen		nr_5030 = rownonmiss(points5030*)
tab 		nr_2210
tab 		nr_5030
drop		nr_*

* bring together points from all years for same subject
egen		gcse2210_points = rowmin(points2210*)
egen		gcse5030_points = rowmin(points5030*)
drop		points*

* check kids have not done multiple gcses:
// yes these are all either 0 or 1 so only 1 exam recorded per subject across all years
egen		nr_2210 = rownonmiss(grade2210*), strok
egen		nr_5030 = rownonmiss(grade5030*), strok
tab 		nr_2210
tab 		nr_5030
drop		nr_*

* bring together grades all years for same subject
* maths
gen			gcse2210_grade =""
forvalues	j = 2016(-1)2003 {
replace		gcse2210_grade = grade2210_`j' if mi(gcse2210_grade)
}

* english
gen			gcse5030_grade =""
forvalues	j = 2016(-1)2003 {
replace		gcse5030_grade = grade5030_`j' if mi(gcse5030_grade)
}

drop		grade*
dropmiss	_all, force

* make sure that the points reflect the grades:
tab 		gcse2210_points gcse2210_grade
tab 		gcse5030_points gcse5030_grade

* convert grades into points
local 		subject "2210 5030"
foreach		s of local subject {
gen			gcse`s'_score = . 
replace 	gcse`s'_score = 8 if gcse`s'_grade =="*" | gcse`s'_grade =="A*" 
replace 	gcse`s'_score = 7 if gcse`s'_grade =="A" 
replace 	gcse`s'_score = 7 if gcse`s'_grade =="AA" 
replace 	gcse`s'_score = 6.5 if gcse`s'_grade =="AB" 
replace 	gcse`s'_score = 6 if gcse`s'_grade =="B" 
replace 	gcse`s'_score = 5 if gcse`s'_grade =="C" 
replace 	gcse`s'_score = 4 if gcse`s'_grade =="D" 
replace 	gcse`s'_score = 3 if gcse`s'_grade =="E" | gcse`s'_grade =="3" 
replace 	gcse`s'_score = 2 if gcse`s'_grade =="F" | gcse`s'_grade =="2" 
replace 	gcse`s'_score = 1 if gcse`s'_grade =="G" | gcse`s'_grade =="1" 
replace 	gcse`s'_score = 0 if gcse`s'_grade =="U" | gcse`s'_grade =="X"
} 

* how do the scores relate to the points?
tab 		gcse2210_points gcse2210_score
tab 		gcse5030_points gcse5030_score

// the score is definitely more reliable I'd say

/* do I have any duplicates by pupilid? */
sort		pupilreference 
by			pupilreference : gen dup = cond(_N==1,0,_n)
order		pupilref* dup
tab 		dup	// no duplicates!!!! yayayayayyy
drop 		dup	leap* acy*	
count		//  2,486
save		`k4allsubj'
restore

merge		m:1 pupilreference using `k4allsubj'
drop if		_merge==2
drop		_merge


/*

/* translate the qan codes */

replace		qan="Eng AQA L1/2 GCSE" if strpos(qan, "50079189")>0 
replace		qan="Eng AQA L1/2 GCSE (A)" if strpos(qan, "10019777")>0 
replace		qan="Eng AQA L1/2 GCSE (B)" if strpos(qan, "10019789")>0 
replace		qan="Eng AQA L3 adva subsid GCE (A)" if strpos(qan, "50025077")>0 
replace		qan="Eng AQA adva subsid GCE (B)" if strpos(qan, "10001487")>0 
replace		qan="Eng EDEXCEL L1/2 (A)" if strpos(qan, "10020573")>0 
replace		qan="Eng EDEXCEL L1/2 GCSE (B)" if strpos(qan, "10020603")>0 
replace		qan="Eng WJEC L1/2 GCSE" if strpos(qan, "10020020")>0 
replace		qan="Eng OCR L1/2" if strpos(qan, "10019868")>0 
replace		qan="Math AQA L1/2 GCSE (modular)" if strpos(qan, "10064308")>0 
replace		qan="Math AQA L1/2 GCSE (A)" if strpos(qan, "1000855X")>0 
replace		qan="Math AQA L3 adva subsid GCE" if strpos(qan, "10034055")>0 
replace		qan="Math EDEXCEL L1/2 linear (A)" if strpos(qan, "10064333")>0
replace		qan="Math EDEXCEL L1/2 GCSE (A)" if strpos(qan, "1001102X")>0 
replace		qan="Math OCR L1/2 (pilot)" if strpos(qan, "50042348")>0 
replace		qan="Math OCR L1/2 (A)" if strpos(qan, "10059350")>0 
replace		qan="Math OCR L1/2 (C)" if strpos(qan, "10064370")>0 
replace		qan="Math OCR adva subsid GCE" if strpos(qan, "10034341")>0 
replace		qan="Math OCR adva subsid GCE (MEI)" if strpos(qan, "10034171")>0
replace		qan="Math Pearson EDEXCEL L1/2 GCSE (A)" if strpos(qan, "50079165")>0 
replace		qan="Math Pearson EDEXCEL L1/2 GCSE (B)" if strpos(qan, "50078860")>0 
replace		qan="Math Pearson EDEXCEL L3 adva subsid" if strpos(qan, "10034110")>0 
replace		qan="Math Pearson EDEXCEL IGCSE (A)" if strpos(qan, "6018825X")>0 
replace		qan="Eng Pearson EDEXCEL IGCSE (A)" if strpos(qan, "60188194")>0 
replace		qan="Eng OCR L3 adva subsid" if strpos(qan, "60147039")>0 
replace		qan="Eng OCR L1/2 GCSE" if strpos(qan, "60131676")>0 
replace		qan="Eng AQA L1/2 GCSE" if strpos(qan, "60131603")>0 
replace		qan="Eng Pearson EDEXCEL L1/2 GCSE" if strpos(qan, "60131585")>0 
replace		qan="Eng WJEC L1/2 GCSE" if strpos(qan, "60131561")>0 
replace		qan="Numb and Meas Pearson EDEXCEL L1" if strpos(qan, "60022413")>0 
replace		qan="Eng AQA L1/2 Cert" if strpos(qan, "60019992")>0 
replace		qan="Eng NCFE Func Skill Entry L3" if strpos(qan, "6001510X")>0 
replace		qan="Eng WJEC L1/2 Cert" if strpos(qan, "60013588")>0 
replace		qan="Math Pearson EDEXCEL L1/2 Cert" if strpos(qan, "60004757")>0 
replace		qan="Eng Pearson L1/2 Cert" if strpos(qan, "60001380")>0 
replace		qan="Adult numeracy Pearson EDEXCEL L1" if strpos(qan, "10013623")>0 
replace		qan="Adult numeracy NCFE L2" if strpos(qan, "1002136X")>0 
replace		qan="Adult numeracy Pearson EDEXCEL L1 cert" if strpos(qan, "10013611")>0 
replace		qan="Eng WJEC L1/2 GCSE" if strpos(qan, "50079104")>0 
replace		qan="Math EDEXCEL L1/2 GCSE(B)(modular)" if strpos(qan, "10064345")>0 





* clean string outcomes to make them numeric
* creates a local with characters to remove, the loops through the variables that
* need to be stripped of these characters 
tab 		readmark
tab 		testmark
tab 		writemark
local 		remove "A M 0 -"
di			"`remove'"
foreach		x of varlist readmark testmark writemark  {
foreach		y of local remove {
replace		`x' =subinstr(`x', "`y'", "",.)
}	
}
foreach		x of varlist readmark testmark writemark {
cap 		destring `x', replace 
}
tab 		readmark
tab 		testmark
tab 		writemark
*/
