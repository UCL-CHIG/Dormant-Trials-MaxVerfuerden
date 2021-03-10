/*==============================================================================
purpose: 		calculate m and u proabilites
date 
created: 		14/05/2019
last updated: 	18/12/2019
				05/05/2021 (cleaned file)
author: 		maximiliane verfuerden
LAST RUN:		20/04/2020 (adjusted probabilities so they add up to 100% within each ID)
          		05/05/2020 (added sibling and alternative ids)
				18/12/2020 (exchanged not expected for matchprobability)
this uses appended versions of deduplicated evaluation files (true and false
matches folder)
===============================================================================*/
clear
cd 				"S:\Head_or_Heart\max\post-trial-extension"
qui do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
capture 		log close
log 			using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\04.2-m_and_u_probs$S_DATE.log", replace
use				"S:\Head_or_Heart\max\post-trial-extension\1-data\04.1-ev_linkage_alltrials.dta"
merge 			m:1 pupilreference using "${datadir}\whichdatasets.dta" 
drop			_merge		
*Add NPD Gender*
preserve
use 			"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", clear
tempfile		gender
count
keep if			npdfieldreference=="GENDER"
drop			tableid dataset acyear laestab unique
by         	 	pupilreference, sort: gen jvar = _n
tab				jvar 																
reshape			wide npdfieldreference indicatorvalue, i(pupilreference) j(jvar)  
dropmiss		_all, force 														
gen				NPDsex =.
replace			NPDsex=1 if indicatorvalue1=="M"
replace			NPDsex=2 if indicatorvalue1=="F"
lab def			NPDsex 1 "male" 2"female"
lab var			NPDsex sex
save			`gender'
restore
cap drop   	 	_merge
merge			m:1 pupilreference using `gender', keepusing(NPDsex)
drop			if _merge==2  //  
drop			_merge
cap drop        dup_*                            
sort            studyid1
drop if			unmatched ==1
********************************************************************************
*               Keep only variables that I need  *
********************************************************************************
keep            studyid1 pupilreference matchprob* birthyear *trial* died two* centre oth* *multi* firstagelink fnscore snscore dbscore locationscore commonnamescore *sex* group centre  true* false* fup* unmatched KS* census multiple birthyear bwt gestage bayley_MDI bayley_PDI iq_score address_tot  smokdur matedu died alcdur *exp*
drop			fupbone*
list 			fup* in 1/1, abb(20)
gen				before5y_fup =0
replace			before5y_fup =1 if fup3w ==1 | fup6w ==1 |fup12w ==1 | fup16w ==1 | fup20w==1 | fup26w ==1
replace			before5y_fup =1 if fup9m ==1 | fup12m ==1 | fup15m==1 | fup12m ==1 | fup18m ==1
gen				after5y_fup =0
replace			after5y_fup =1 if fup5y ==1 | fup6to8y ==1 |fup11to20y ==1 | fup25y ==1 
*Create sex score  *
gen				sexscore = .
replace			sexscore = 1 if NPDsex==1 & RCTsex==1 | NPDsex==2 & RCTsex==2 
replace			sexscore = 2 if NPDsex==1 & RCTsex==2 | NPDsex==2 & RCTsex==1
replace			sexscore = 3 if NPDsex==. | RCTsex==.
*Variable lables  *
lab def firstname 1"both fns match" 2"fn matches other and vv" 3"fn matches" 4"fn matches other" 6"others match" 100"fn truncated matches" 110"fn matches alias" 130"pattern match1" 160"pattern match2" 181"fn matches sn and vv" 200"no link"
lab def surname 3"surname(s) match" 100"sn matches at hyphen" 130"pattern match1" 160"pattern match2" 181"sn matches fn and vv" 100"fn truncated matches" 110"sn matches alias" 130"pattern match1" 160"pattern match2" 181"fn matches sn and vv" 200"no link"
lab def dob 1"dob matches" 10"transposed date" 50"wrong year" 60"wrong month" 61"wrong day" 80"01jan and year matches" 110"01sept year matches" 200"no link"
lab def location 1"postcode exact match" 2"local authority match" 6"neighbouring authority match" 200"no link"
lab def sexscore 1"sex exact match" 2"sex no match" 3"sex missing in at least 1 record" 
lab def	trialnew 1"OA"  2"OB" 3"PDP" 4"LP" 5"LT" 6"Nuc" 7"Iron" 8"SGA" 9"PAL"
lab val	trial trialnew
lab val	fnscore firstname
lab val	snscore surname
lab val	dbscore dob
lab val	locationscore location
lab val	sexscore sexscore
********************************************************************************************
**       					PLAUSIBILITY CHECK:
********************************************************************************************
********************************************************************************************
** implausible link ages and missing link age (these are mostly trial 1/2s)
********************************************************************************************
* how many kids should not link?
sort			studyid1
by				studyid1:	gen dup = cond(_N==1,0,_n)
// spread relatively evenly across trials and years and groups
generate		manualreviewflag = 0
replace			manualreviewflag = 1 if died ==1 
replace			manualreviewflag = 1 if multiple_birth ==1
********************************************************************************
*               m probabilities                          						*
********************************************************************************
// what is the probability of belonging to a certain category given that its a true match?
// true match can only be approximated - that is by falling into best category of all identifiers and blocked by age at link.
*************************
* m-prob for sex *
*************************
gen             true0 = 0
replace         true0 = 1 if (firstagelink >3 & firstagelink <20)  & (fnscore <4) & (snscore <100) & (dbscore ==1) & (locationscore==1) & (snscore <100) 
tab             sexscore if true0 ==1 , matcell(mat_fn) m 
replace         m_prob_sex = 95.96 if sexscore == 1 
replace         m_prob_sex = 2.49 if sexscore == 2 
replace         m_prob_sex = 1.55 if sexscore == 3 
format          %9.2f m_prob_sex 
label list		sexscore
*************************
* m-prob for first name *
*************************
// true1 = matches all but first name
// I manually redjusted these weights that they better reflect the actual probabilities (using prior data on probabilities from published Harron PhD thesis)
gen             true1 = 0
replace         true1 = 1 if (firstagelink >3 & firstagelink <20) & (snscore <100) & (dbscore ==1) & (locationscore==1) & (sexscore ==1)
tab             fnscore if true1 ==1 , matcell(mat_fn) m // take note of the categories (they are applied further down)
mata:           st_matrix("mat_fn", (st_matrix("mat_fn") :/ colsum(st_matrix("mat_fn")))) // to save the %es not the frequencies
matrix          list mat_fn
gen             m_prob_fn = .
replace         m_prob_fn = 6.57 if fnscore == 1 
replace         m_prob_fn = 87.06 if fnscore == 3
replace         m_prob_fn = 1.30 if fnscore == 6
replace         m_prob_fn = 0.40 if fnscore == 100
replace         m_prob_fn = 2.33 if fnscore == 110
replace         m_prob_fn = 0.91 if fnscore == 130
replace         m_prob_fn = 0.41 if fnscore == 160
replace         m_prob_fn = 0.1 if fnscore == 181
replace         m_prob_fn = 0.92 if fnscore == 200
format          %9.2f m_prob_fn 
label list		firstname
*************************
* m-prob for surname *
*************************
// true2 = matches all but surname
gen             true2 = 0
replace         true2 = 1 if (firstagelink >3 & firstagelink <20) & (fnscore <4) & (dbscore ==1) & (locationscore==1) & (sexscore ==1)
tab             snscore if true2 ==1 , matcell(mat_sn) m // take note of the categories (they are applied further down)
mata:           st_matrix("mat_sn", (st_matrix("mat_sn") :/ colsum(st_matrix("mat_sn")))) // to save the %es not the frequencies
matrix          list mat_sn
gen             m_prob_sn = .
replace         m_prob_sn = 93.87 if snscore == 3
replace         m_prob_sn = 1.25 if snscore == 100
replace         m_prob_sn = 1.9 if snscore == 130
replace         m_prob_sn = 1.7 if snscore == 160
replace         m_prob_sn = 1 if snscore == 181
replace         m_prob_sn = 0.28 if snscore == 200
format          %9.2f m_prob_sn 
label list		surname
****************************
* m-prob for date of birth *
****************************
// true3 = matches all but date of birth
gen             true3 = 0
replace         true3 = 1 if (firstagelink >3 & firstagelink <20) & (snscore <100) & (fnscore <4) & (locationscore==1) & (sexscore ==1)
tab             dbscore if true3 ==1 , matcell(mat_db) m // take note of the categories (they are applied further down)
mata:           st_matrix("mat_db", (st_matrix("mat_db") :/ colsum(st_matrix("mat_db")))) // to save the %es not the frequencies
matrix          list mat_db
gen             m_prob_db = .
replace         m_prob_db = 98.30 if dbscore == 1
replace         m_prob_db = 0.45 if dbscore == 10
replace         m_prob_db = 0.01 if dbscore == 50
replace         m_prob_db = 0.38 if dbscore == 60
replace         m_prob_db = 0.85 if dbscore == 61
replace         m_prob_db = 0.01 if dbscore == 200
format          %9.2f m_prob_db 
label list		dob
****************************
* m-prob for location *
****************************
// true4 = matches all but location
gen             true4 = 0
replace         true4 = 1 if (firstagelink >3 & firstagelink <20) & (snscore <100) & (fnscore <4) & (dbscore ==1) & (sexscore ==1)
tab             locationscore if true4 ==1 , matcell(mat_lo) m // take note of the categories (they are applied further down)
mata:           st_matrix("mat_lo", (st_matrix("mat_lo") :/ colsum(st_matrix("mat_lo")))) // to save the %es not the frequencies
matrix          list mat_lo
tab				true4
gen             m_prob_lo = .
replace         m_prob_lo = 52 if locationscore == 1
replace         m_prob_lo = 29 if locationscore == 2
replace         m_prob_lo = 14 if locationscore == 6
replace         m_prob_lo = 5 if locationscore == 200
format          %9.2f m_prob_lo 
label list		location
/*
replace         m_prob_lo = (mat_lo[4,1])*100 if locationscore == 200
*/
drop            true1 true2 true3 true4
********************************************************************************
*               u probability                            						*
********************************************************************************
// what is the probability of belonging to a certain category by chance given that its a false match?
// false match can only be approximated - that is by falling into worst category of all identifiers except the one I'm testing for
*************************
* u-prob for sex *
*************************
gen             false0 = 0
replace         false0 = 1 if (snscore >100) & (dbscore >100) & (locationscore >100) & (fnscore >100) 
gen             u_prob_sex = .
replace         u_prob_sex = 52 if sexscore == 1 
replace         u_prob_sex = 47 if sexscore == 2 
replace         u_prob_sex = 1 if sexscore == 3 
format          %9.2f m_prob_sex 
label list		sexscore
*************************
* u-prob for first name *
*************************
// false1 = matches none but first name
gen             false1 = 0
replace         false1 = 1 if (snscore >100) & (dbscore >100) & (locationscore >100) & (sexscore >1)
tab             fnscore if false1 ==1 , matcell(umat_fn) m // take note of the categories (they are applied further down)
/*
mata:           st_matrix("umat_fn", (st_matrix("umat_fn") :/ colsum(st_matrix("umat_fn")))) // to save the %es not the frequencies
matrix          list umat_fn
*/
gen             u_prob_fn = .
replace         u_prob_fn = 0.36 if fnscore == 1
replace         u_prob_fn = 0.99 if fnscore == 3
replace         u_prob_fn = 0.2  if fnscore == 6
replace         u_prob_fn = 0.95 if fnscore == 100
replace         u_prob_fn = 0.7 if fnscore == 110
replace         u_prob_fn = 1.8 if fnscore == 130
replace         u_prob_fn = 1.8 if fnscore == 160
replace         u_prob_fn = 0.2 if fnscore == 181
replace         u_prob_fn = 93 if fnscore == 200
format          %9.2f u_prob_fn 
label list		firstname
*************************
* u-prob for surname *
*************************
// false2 = matches none but surname
gen             false2 = 0
replace         false2 = 1 if (fnscore >100) & (dbscore >100) & (locationscore >100)  & (sexscore >1)
tab             snscore if false2 ==1 , matcell(umat_sn) m // take note of the categories (they are applied further down)
/* no obs
mata:           st_matrix("umat_sn", (st_matrix("umat_sn") :/ colsum(st_matrix("umat_sn")))) // to save the %es not the frequencies
matrix          list umat_sn
*/ 
tab 			false2 // in false matches == 0.82%
gen             u_prob_sn = .
replace         u_prob_sn = 2 if snscore == 3
replace         u_prob_sn = 0.5 if snscore == 100
replace         u_prob_sn = 2 if snscore == 130
replace         u_prob_sn = 2 if snscore == 160
replace         u_prob_sn = 0.1 if snscore == 181
replace         u_prob_sn = 93.4 if snscore == 200
format          %9.2f u_prob_sn 
label list		surname
****************************
* u-prob for date of birth *
****************************
// false3 = matches none but date of birth
gen             false3 = 0
replace         false3 = 1 if (fnscore >100) & (snscore >100) & (locationscore >100)  & (sexscore >1)
tab             dbscore if false3 ==1 , matcell(umat_db) m // take note of the categories (they are applied further down)
// all in category 1! 
mata:           st_matrix("umat_db", (st_matrix("umat_db") :/ colsum(st_matrix("umat_db")))) // to save the %es not the frequencies
matrix          list umat_db
tab 		      false3
gen               u_prob_db = .
replace           u_prob_db = 2 if dbscore == 1
replace           u_prob_db = 5 if dbscore == 50
replace           u_prob_db = 5 if dbscore == 50
replace           u_prob_db = 9 if dbscore == 60
replace           u_prob_db = 10 if dbscore == 61
replace           u_prob_db = 69 if dbscore == 200
format            %9.2f u_prob_db 
****************************
* u-prob for location	   
****************************
// false3 = matches none but date of birth
gen               false4 = 0
replace           false4 = 1 if (fnscore >100) & (snscore >100) & (dbscore >100)  & (sexscore >1)
tab               locationscore if false4 ==1 , matcell(umat_lo) m 
tab 			  false4
gen               u_prob_lo = .
replace           u_prob_lo = 15 if locationscore == 1
replace           u_prob_lo = 10 if locationscore == 2
replace           u_prob_lo = 5 if locationscore == 6
replace           u_prob_lo = 70 if locationscore == 200
format            %9.2f u_prob_lo 
************************
drop			  false1 false2 false3 false4
********************************************************************************
*               log likelihood ratios / weights for variables		   
********************************************************************************
// r = m/u if identifiers agree (for each category)
// r = (1-m)/(1-u) if identifiers disagree (for each category)
**************
* sex	 
**************
// sex has the following categories:
tab				sex  
** r **
gen				r_sex = m_prob_sex / u_prob_sex
** w(r) **
gen				w_r_sex = ln(r_sex)/ln(2)
**************
* firstname	 
**************
// first name has the following categories:
tab				fnscore 
** r **
gen				r_fn = m_prob_fn / u_prob_fn
** w(r) **
gen				w_r_fn = ln(r_fn)/ln(2)

**************
* surname	 
**************
// surname has the following categories:
tab				snscore
** r **
gen				r_sn = m_prob_sn / u_prob_sn
** w(r) **
gen				w_r_sn = ln(r_sn)/ln(2)
*******************
* date of birth	  
*******************
// date of birth has the following categories:
tab				dbscore  
** r **
gen				r_db = m_prob_db / u_prob_db
** w(r) **
gen				w_r_db = ln(r_db)/ln(2)
****************
* location	   
****************
// location has the following categories:
tab				locationscore 
** r **
gen				r_lo = m_prob_lo / u_prob_lo
** w(r) **
gen				w_r_lo= ln(r_lo)/ln(2)
********************************************************************************
*           Weight      		                     					   
********************************************************************************
egen		W= rowtotal(w_*)
lab var		W "overall match weight"
********************************************************************************
*           Check      		                     					   
********************************************************************************
* what are the most common score patterns?		
egen		agreementpattern = concat(fnscore snscore dbscore locationscore sexscore), decode p(" ")
/* list pattern by frequency */
groups		agreementpattern, order(high)
groups		agreementpattern if trial==1, order(high) 
groups		agreementpattern if trial==2, order(high) 
groups		agreementpattern if trial==3, order(high) 
groups		agreementpattern if trial==4, order(high) 
groups		agreementpattern if trial==5, order(high) 
groups		agreementpattern if trial==6, order(high) 
groups		agreementpattern if trial==7, order(high) 
groups		agreementpattern if trial==8, order(high) 
groups		agreementpattern if trial==9, order(high) 
*******************************************************************************	
* 		    Show the distribution of weights by trial:
********************************************************************************	
twoway 		histogram W if trial==1, discrete frequency recast(line) color("ltblue%50") ///
 	    ||	histogram W if trial==2, discrete frequency recast(line) color("navy%50") ///
 	    ||	histogram W if trial==3, discrete frequency recast(line) color("green%50") ///
	    ||	histogram W if trial==4, discrete frequency recast(line) color("purple%50") ///
		||	histogram W if trial==5, discrete frequency recast(line) color("yellow%50") ///
		||	histogram W if trial==6, discrete frequency recast(line) color("navy%50") ///
		||	histogram W if trial==7, discrete frequency recast(line) color("blue%50") ///
		||	histogram W if trial==8, discrete frequency recast(line) color("orange%50") ///
		||	histogram W if trial==9, discrete frequency recast(line) color("red%50") ///
		legend(ring(0) pos(-1) col(1) order(1 "Trial 1" 2 "Trial 2"  3 "Trial 3" 4 "Trial 4" 5 "Trial 5" 6 "Trial 6" 7 "Trial 7" 8 "Trial 8" 9 "Trial 9" ))  ///
		xline(8 15, lcolor(gray)) 		
*===============================================================================*/
compress
descr, 			full	
save			"${datadir}\m_and_u_probs_weights.dta", replace
log 			close		