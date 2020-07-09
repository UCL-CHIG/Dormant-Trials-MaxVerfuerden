/*******************************************************************************
purpose: 		Extract K2 Exam points, grades and years from allsubj dataset
date 
created: 		01/08/2019
last updated: 	02/08/2019
author: 		maximiliane verfuerden

*******************************************************************************/


preserve
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldatasubj.dta", clear
tempfile	k2allsubj
count		// 2,784,513

/* which datasets are there? only keep ks2 */
tab			dataset, sort // ks2Exam and ks4Exam
keep if 	strpos(dataset, "ks2")>0 // (2,315,493 observations deleted)

* which variables in KS2 have the most entries?
tab			npdfieldreference, sort 
	
keep if 	strpos(npdfieldreference, "MRK")>0 | strpos(npdfieldreference, "MARK")>0 | strpos(npdfieldreference, "TEST")>0 // (336,676 observations deleted)
drop		tableid qan laestab unique

replace		leapcode= trim(leapcode) // (0 real changes made)
replace		indicatorvalue= trim(indicatorvalue) // 98,944 real changes made)
drop if		indicatorvalue=="" 	// (114,379 observations deleted)

/* drop all duplicates except for the first observation*/
sort		pupilreference dataset acyear npdfieldreference indicatorvalue
by			pupilreference dataset acyear npdfieldreference indicatorvalue:	gen dup = cond(_N==1,0,_n)
drop		if dup>1 // (3,448 observations deleted)
drop		dup

/* some have conflicting information, keep the lowest score */
sort		pupilreference dataset acyear npdfieldreference 
by			pupilreference dataset acyear npdfieldreference :	gen dup = cond(_N==1,0,_n)
drop		if dup>1 // 4,937 observations deleted
drop		dup 

/* readmark*/
gen			readmark = indicatorvalue if strpos(npdfieldreference, "READMARK")>0  
tab			readmark acyear
// contains non-numeric chars - cannot destring
lab var		readmark "readmark"
gen			yr_readmark = acyear if readmark !=""
lab var		yr_readmark "year readmark"

/* writemark*/
gen			writemark = indicatorvalue if strpos(npdfieldreference, "WRITMARK")>0  
// contains non-numeric chars - cannot destring
lab var		writemark "writemark"
gen			yr_writemark = acyear if writemark !=""
lab var		yr_writemark "year writemark"

/* testmark*/
gen			testmark = indicatorvalue if strpos(npdfieldreference, "TESTMARK")>0 |  strpos(npdfieldreference, "TESTMRK")>0
// contains non-numeric chars - cannot destring
lab var		testmark "testmark"
gen			yr_testmark = acyear if testmark !=""
lab var		yr_testmark "year testmark"

/* teststat*/
gen			teststat = indicatorvalue if strpos(npdfieldreference, "TESTSTAT")>0  
// contains non-numeric chars - cannot destring
lab var		teststat "teststat"
gen			yr_teststat = acyear if teststat !=""
lab var		yr_teststat "year teststat"

/* T1 mark*/
gen			t1mark = indicatorvalue if strpos(npdfieldreference, "T1MARK")>0  
// contains non-numeric chars - cannot destring
lab var		t1mark "t1 mark"


/* T2 mark*/
gen			t2mark = indicatorvalue if strpos(npdfieldreference, "T2MARK")>0  
lab var		t2mark "t2 mark"


/* T3 mark*/
gen			t3mark = indicatorvalue if strpos(npdfieldreference, "T3MARK")>0  
lab var		t3mark "t3 mark"


/* T4 mark*/
gen			t4mark = indicatorvalue if strpos(npdfieldreference, "T4MARK")>0  
lab var		t4mark "t4 mark"


/* get missing string values to the bottom first by sorting then replace with final*/
sort		pupilreference readmark
bysort 		pupilreference: replace  readmark = readmark[_N]

sort		pupilreference writemark
bysort 		pupilreference: replace  writemark = writemark[_N]

sort		pupilreference testmark
bysort 		pupilreference: replace  testmark = testmark[_N]

sort		pupilreference teststat
bysort 		pupilreference: replace  teststat = teststat[_N]

sort		pupilreference t1mark
bysort 		pupilreference: replace  t1mark = t1mark[_N]

sort		pupilreference t2mark
bysort 		pupilreference: replace  t2mark = t2mark[_N]

sort		pupilreference t3mark
bysort 		pupilreference: replace  t3mark = t3mark[_N]

sort		pupilreference t4mark
bysort 		pupilreference: replace  t4mark = t4mark[_N]

sort		pupilreference yr_readmark
bysort 		pupilreference: replace  yr_readmark = yr_readmark[_N]

sort		pupilreference yr_writemark
bysort 		pupilreference: replace  yr_writemark = yr_writemark[_N]

sort		pupilreference yr_testmark
bysort 		pupilreference: replace  yr_testmark = yr_testmark[_N]

sort		pupilreference yr_teststat
bysort 		pupilreference: replace  yr_teststat = yr_teststat[_N]

drop		acyear dataset npdfieldreference indicatorvalue leapcode

sort		readmark writemark testmark  teststat t1mark t2mark t3mark t4mark yr_readmark yr_writemark yr_testmark yr_teststat 
by			readmark writemark testmark  teststat t1mark t2mark t3mark t4mark yr_readmark yr_writemark yr_testmark yr_teststat :	gen dup = cond(_N==1,0,_n)
sort		pupilreference
drop		if dup>1															// (8,207 observations deleted)
duplicates 	tag pupilreference, gen(duppid)
tab			duppid 		
drop		dup*	// no duplicates yay! 
count		// 1,282
save		`k2allsubj'
restore

merge		m:1 pupilreference using `k2allsubj'
drop if		_merge==2
drop		_merge
