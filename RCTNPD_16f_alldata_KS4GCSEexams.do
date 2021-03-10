/*==============================================================================
purpose: 		Extract K4 Exam points, grades and years from allsubj dataset
date 
created: 		01/08/2019
last updated: 	07/08/2019
author: 		maximiliane verfuerden
Notes:			I decided to only focus on 2210 and 5030
===============================================================================*/
preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldatasubj.dta", clear
tempfile	k4allsubj
* clean the subject code and values
replace		leapcode= trim(leapcode)
replace		indicatorvalue= trim(indicatorvalue) 
drop if		indicatorvalue==""
/* which leapcodes are there? only keep Maths and English*/
tab			leapcode, sort  
* keep only rows that relate to mathematics and english subject codes
keep if 	strpos(leapcode, "2210")>0 | strpos(leapcode, "5030")>0 
/* which datasets are there? only keep ks4*/
tab			dataset, sort // ks2Exam and ks4Exam
keep if 	strpos(dataset, "ks4")>0 // (0 observations deleted)
* which academic years does this dataset span?
tab			acyear // 2003/04 to 2015/16
* which variables are available for these subjects?
tab			npdfieldreference, sort // 
* keep only rows that contain info about grade, points and examyear
keep if 	strpos(npdfieldreference, "GRADE")>0 | strpos(npdfieldreference, "POINTS")>0 | strpos(npdfieldreference, "EXAMYEAR")>0 
* delete variables I won't use
drop		tableid laestab unique dataset qan
/* drop all duplicates except for the first observation*/
sort		pupilreference leapcode acyear npdfieldreference indicatorvalue
by			pupilreference leapcode acyear npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 	
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
/* drop all duplicates, now examyear takes priority over acyear */
sort		pupilreference leapcode ks4_examyr* npdfieldreference indicatorvalue
by			pupilreference leapcode ks4_examyr* npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 															
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
/* do I have any duplicates by pupilid? */
sort		pupilreference 
by			pupilreference : gen dup = cond(_N==1,0,_n)
order		pupilref* dup
drop 		dup	leap* acy*	
save		`k4allsubj'
restore
merge		m:1 pupilreference using `k4allsubj'
drop if		_merge==2
drop		_merge