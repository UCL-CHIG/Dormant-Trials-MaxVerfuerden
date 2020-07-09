/*******************************************************************************
purpose: 		evaluate linkage for all RCTs together 
date 
created: 		03/04/2019
last updated: 	10/01/2020
author: 		maximiliane verfuerden

this uses appended versions of deduplicated evaluation files (true and false
matches folder)

*******************************************************************************/

********************************************************************************
* 								SET FILEPATHS 								   *
********************************************************************************
clear
cd 			"S:\Head_or_Heart\max\post-trial-extension"
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
cap qui		do "S:\Head_or_Heart\max\attributes\7-ado\dropmiss.ado"
cap	qui		do "S:\Head_or_Heart\max\attributes\7-ado\renvars.ado"
cap qui 	do	"S:\Head_or_Heart\max\post-trial-extension\00-ado\groups.ado"


********************************************************************************
*								 SET LOG 								 	   *
********************************************************************************
capture 	log close
log 		using "${logdir}\04.1-ev_linkage_alltrials $S_DATE.log", replace 
capture		drop _merge

********************************************************************************
*					APPEND ALL EVALUATION FILES								   *
********************************************************************************
use 		"S:\Head_or_Heart\max\post-trial-extension\1-data\04-ev_linkage_t1.dta", clear 
append 		using "${datadir}\04-ev_linkage_t3" "${datadir}\04-ev_linkage_t4.dta" "${datadir}\04-ev_linkage_t5.dta" "${datadir}\04-ev_linkage_t6.dta" "${datadir}\04-ev_linkage_t7.dta" "${datadir}\04-ev_linkage_t8.dta" "${datadir}\04-ev_linkage_t9.dta"
capture		drop _merge
merge 		m:1 studyid using "S:\Head_or_Heart\max\attributes\1-Data\importantvars.dta"
drop if 	_merge==2 // Scottish trials 
count if	studyid1=="" // 0
tab			_merge // all others match
drop		_merge 

save		"${datadir}\04.1-ev_linkage_alltrials.dta", replace
count		



/* # ungreen this if I want to do the evaluation, I kept this out to make the
	masterfile that creates the goldstandard go faster # 

********************************************************************************
** here I generate a percentage variable for the percentage with exact match by identifier by birthyear
********************************************************************************
cap drop	temp*
by          birthyear, sort: gen temp1= 1 if snscore==3 
egen		sns_percexactall = mean(cond(temp1, 100* (temp1 == 1), . )), by(birthyear)
replace		sns_percexactall = round(sns_percexactall, .1)

by          birthyear, sort: gen temp2= 1 if (fnscore ==1 | fnscore ==2 | fnscore ==3 )
egen		fns_percexactall = mean(cond(temp2, 100* (temp2 == 1), . )), by(birthyear)
replace		fns_percexactall = round(fns_percexactall, .1)

by          birthyear, sort: gen temp3= 1 if dbscore==1 
egen		dbs_percexactall = mean(cond(temp3, 100* (temp3 == 1), . )), by(birthyear)
replace		dbs_percexactall = round(dbs_percexactall, .1)
drop		temp1

by          birthyear, sort: gen temp4= 1 if (locationscore ==1 | locationscore ==2)
egen	    locations_percexactall = mean(cond(temp4, 100* (temp4 == 1), . )), by(birthyear)
replace		locations_percexactall = round(locations_percexactall, .1)

* number of participants born in a given year
by          birthyear, sort: gen temp5= _n 
egen	    births = max(temp5), by(birthyear)
lab var		births "nr babies randomised"

********************************************************************************
** display percentage exact match by birthyear and identifier 				  **
********************************************************************************

graph twoway   (line  fns_percexactall birthyear , cmissing(no) yaxis(1)  color("green%50"))	|| (line  sns_percexactall  birthyear , cmissing(no) yaxis(1) color("blue%50")) || (line  dbs_percexactall birthyear, cmissing(no) yaxis(1) color("red%50")) || (line  locations_percexactall birthyear, cmissing(no) yaxis(1) color("purple%50")) ///	
			|| (area  births birthyear, cmissing(no) yaxis(2)  color("yellow%50")),	///
				ytitle("% exact match by identifier") ///
				ylab(0(10)100) ///
				xtitle("birthyear") ///
				title("match score % distribution by birthyear for all RCTs", size(medium)) ///
				ylabel(, angle(0)) ///
				plotregion(margin(0 0 0 -3)) ///
				graphregion(color(white)) ///
				legend(ring(0) pos(3) col(1) order(1 "firstname" 2 "surname" 3 "date of birth" 4 "location" ))

********************************************************************************
** percentage exact match by trial and identifier 				  			  **
********************************************************************************

by 			trial, sort: gen snsperc= 1 if  snscore==3 
by          trial, sort: gen fnsperc= 1 if (fnscore ==1 | fnscore ==2 | fnscore ==3 )
by          trial, sort: gen dbsperc= 1 if dbscore==1 
by          trial, sort: gen locationsperc= 1 if (locationscore ==1 | locationscore ==2)
by 			trial, sort: gen matchcat =1 if snscore==3 & (fnscore ==1 | fnscore ==2 | fnscore ==3 ) & dbscore==1 & (locationscore ==1 | locationscore ==2)
replace		matchcat = 3 if unmatched==1 
replace		matchcat = 0 if matchcat ==.
replace		matchcat =. if matchcat == 3
tab			matchcat, m

tab  		trial snsperc, m row
tab  		trial fnsperc, m row
tab 		trial dbsperc, m row
tab  		trial locationsperc, m row
tab  		trial matchcat, m row

********************************************************************************
** characteristics by matchstatus (overall)						  			  **
********************************************************************************

** exact match
codebook 	bwt if matchcat==1
codebook    gestage if matchcat==1
tab		    sex if matchcat==1
tab		    matedu if matchcat==1
tab		    smokdur if matchcat==1
codebook    iq_score if matchcat==1
codebook    bayley_MDI if matchcat==1
codebook    bayley_PDI if matchcat==1
tab 		group if matchcat==1


** less than exact match
codebook 	bwt if matchcat==0
codebook    gestage if matchcat==0
tab		    sex if matchcat==0
tab		    matedu if matchcat==0
tab		    smokdur if matchcat==0
codebook    iq_score if matchcat==0
codebook    bayley_MDI if matchcat==0
codebook    bayley_PDI if matchcat==0
tab 		group if matchcat==0

** not matched
codebook 	bwt if matchcat==.
codebook    gestage if matchcat==.
tab		    sex if matchcat==.
tab		    matedu if matchcat==.
tab		    smokdur if matchcat==.
codebook    iq_score if matchcat==.
codebook    bayley_MDI if matchcat==.
codebook    bayley_PDI if matchcat==.
tab 		group if matchcat==.

** overall
codebook 	bwt 
codebook    gestage 
tab		    sex 
tab		    matedu 
tab		    smokdur 
codebook    iq_score 
codebook    bayley_MDI 
codebook    bayley_PDI 
tab 		group

/*
********************************************************************************
* is the difference in characteristics significant?
********************************************************************************

** difference in means (i = immediate form of test)
// follows: #obs1 mean1 sd1 #obs2 mean2 sd2 
ttesti 		1226 2343.5 1020.1 2096 2177.4 1008.7 // birthweight exact vs overall
ttesti 		1229 35.5 4.9 2099 34.8 4.9 // gestage exact vs overall
ttesti 		424 103.6 14.6 582 101.7 15.4 // iqscore exact vs overall
ttesti 		1042 93.5 15.6 1772 94.7 17.3 // Bayley MDI exact vs overall
ttesti 		849 90.7 13.5 1221 89.0 14.6 // Bayley PDI exact vs overall

** difference in proportions (i = immediate form of test)
// follows: #obs1 p1 #obs2 p2 
prtesti 	1104 0.52 1739 0.514 // male exact vs overall
prtesti 	232 0.203 332 0.332 // lowest matedu exact vs overall
prtesti 	100 0.87 214 0.11 // highest matedu exact vs overall
prtesti 	343 0.382 582 0.376 // smok dur pregnancy exact vs overall
prtesti 	675 0.353 1144 0.377 // group exact vs overall

********************************************************************************
** characteristics by matchstatus (Trial 1+2 )						  			  **
********************************************************************************

** exact match
codebook 	bwt if matchcat==1 & trial==1
codebook    gestage if matchcat==1 & trial==1
tab		    sex if matchcat==1 & trial==1
tab		    matedu if matchcat==1 & trial==1
tab		    smokdur if matchcat==1 & trial==1
codebook    iq_score if matchcat==1 & trial==1
codebook    bayley_MDI if matchcat==1 & trial==1
codebook    bayley_PDI if matchcat==1 & trial==1
tab 		group if matchcat==1 & trial==1


** less than exact match
codebook 	bwt if matchcat==0 & trial==1
codebook    gestage if matchcat==0 & trial==1
tab		    sex if matchcat==0 & trial==1
tab		    matedu if matchcat==0 & trial==1
tab		    smokdur if matchcat==0 & trial==1
codebook    iq_score if matchcat==0 & trial==1
codebook    bayley_MDI if matchcat==0 & trial==1
codebook    bayley_PDI if matchcat==0 & trial==1
tab 		group if matchcat==0 & trial==1

** not matched
codebook 	bwt if matchcat==. & trial==1
codebook    gestage if matchcat==. & trial==1
tab		    sex if matchcat==. & trial==1
tab		    matedu if matchcat==. & trial==1
tab		    smokdur if matchcat==. & trial==1
codebook    iq_score if matchcat==. & trial==1
codebook    bayley_MDI if matchcat==. & trial==1
codebook    bayley_PDI if matchcat==. & trial==1
tab 		group if matchcat==. & trial==1

** overall
codebook 	bwt if trial==1
codebook    gestage if trial==1
tab		    sex if trial==1
tab		    matedu if trial==1
tab		    smokdur if trial==1
codebook    iq_score if trial==1
codebook    bayley_MDI if trial==1
codebook    bayley_PDI if trial==1
tab 		group if trial==1

********************************************************************************
* is the difference in characteristics significant?
********************************************************************************

** difference in means (i = immediate form of test)
// follows: #obs1 mean1 sd1 #obs2 mean2 sd2 
ttesti 		1226 2343.5 1020.1 2096 2177.4 1008.7  // birthweight exact vs overall
ttesti 		1229 35.5 4.9 2099 34.8 4.9  // gestage exact vs overall
ttesti 		424 103.6 14.6 582 101.7 15.4  // iqscore exact vs overall
ttesti 		1042 93.5 15.6 1772 94.7 17.3  // Bayley MDI exact vs overall
ttesti 		849 90.7 13.5 1221 89.0 14.6  // Bayley PDI exact vs overall

** difference in proportions (i = immediate form of test)
// follows: #obs1 p1 #obs2 p2 
prtesti 	1104 0.52 1739 0.514// male exact vs overall
prtesti 	232 0.203 332 0.332   // lowest matedu exact vs overall
prtesti 	100 0.87 214 0.11  // highest matedu exact vs overall
prtesti 	343 0.382 582 0.376  // smok dur pregnancy exact vs overall
prtesti 	675 0.353 1144 0.377   // group exact vs overall



********************************************************************************
** characteristics by matchstatus (Trial 3)						  			  **
********************************************************************************

** exact match
codebook 	bwt if matchcat==1 & trial==3
codebook    gestage if matchcat==1 & trial==3
tab		    sex if matchcat==1 & trial==3
tab		    matedu if matchcat==1 & trial==3
tab		    smokdur if matchcat==1 & trial==3
codebook    iq_score if matchcat==1 & trial==3
codebook    bayley_MDI if matchcat==1 & trial==3
codebook    bayley_PDI if matchcat==1 & trial==3
tab 		group if matchcat==1 & trial==3


** less than exact match
codebook 	bwt if matchcat==0 & trial==3
codebook    gestage if matchcat==0 & trial==3
tab		    sex if matchcat==0 & trial==3
tab		    matedu if matchcat==0 & trial==3
tab		    smokdur if matchcat==0 & trial==3
codebook    iq_score if matchcat==0 & trial==3
codebook    bayley_MDI if matchcat==0 & trial==3
codebook    bayley_PDI if matchcat==0 & trial==3
tab 		group if matchcat==0 & trial==3

** not matched
codebook 	bwt if matchcat==. & trial==3
codebook    gestage if matchcat==. & trial==3
tab		    sex if matchcat==. & trial==3
tab		    matedu if matchcat==. & trial==3
tab		    smokdur if matchcat==. & trial==3
codebook    iq_score if matchcat==. & trial==3
codebook    bayley_MDI if matchcat==. & trial==3
codebook    bayley_PDI if matchcat==. & trial==3
tab 		group if matchcat==. & trial==3

** overall
codebook 	bwt if trial==3
codebook    gestage if trial==3
tab		    sex if trial==3
tab		    matedu if trial==3
tab		    smokdur if trial==3
codebook    iq_score if trial==3
codebook    bayley_MDI if trial==3
codebook    bayley_PDI if trial==3
tab 		group if trial==3

********************************************************************************
** characteristics by matchstatus (Trial 4)						  			  **
********************************************************************************

** exact match
codebook 	bwt if matchcat==1 & trial==4
codebook    gestage if matchcat==1 & trial==4
tab		    sex if matchcat==1 & trial==4
tab		    matedu if matchcat==1 & trial==4
tab		    smokdur if matchcat==1 & trial==4
codebook    iq_score if matchcat==1 & trial==4
codebook    bayley_MDI if matchcat==1 & trial==4
codebook    bayley_PDI if matchcat==1 & trial==4
tab 		group if matchcat==1 & trial==4


** less than exact match
codebook 	bwt if matchcat==0 & trial==4
codebook    gestage if matchcat==0 & trial==4
tab		    sex if matchcat==0 & trial==4
tab		    matedu if matchcat==0 & trial==4
tab		    smokdur if matchcat==0 & trial==4
codebook    iq_score if matchcat==0 & trial==4
codebook    bayley_MDI if matchcat==0 & trial==4
codebook    bayley_PDI if matchcat==0 & trial==4
tab 		group if matchcat==0 & trial==4

** not matched
codebook 	bwt if matchcat==. & trial==4
codebook    gestage if matchcat==. & trial==4
tab		    sex if matchcat==. & trial==4
tab		    matedu if matchcat==. & trial==4
tab		    smokdur if matchcat==. & trial==4
codebook    iq_score if matchcat==. & trial==4
codebook    bayley_MDI if matchcat==. & trial==4
codebook    bayley_PDI if matchcat==. & trial==4
tab 		group if matchcat==. & trial==4

** overall
codebook 	bwt if trial==4
codebook    gestage if trial==4
tab		    sex if trial==4
tab		    matedu if trial==4
tab		    smokdur if trial==4
codebook    iq_score if trial==4
codebook    bayley_MDI if trial==4
codebook    bayley_PDI if trial==4
tab 		group if trial==4


********************************************************************************
** characteristics by matchstatus (Trial 5)						  			  **
********************************************************************************

** exact match
codebook 	bwt if matchcat==1 & trial==5
codebook    gestage if matchcat==1 & trial==5
tab		    sex if matchcat==1 & trial==5
tab		    matedu if matchcat==1 & trial==5
tab		    smokdur if matchcat==1 & trial==5
codebook    iq_score if matchcat==1 & trial==5
codebook    bayley_MDI if matchcat==1 & trial==5
codebook    bayley_PDI if matchcat==1 & trial==5
tab 		group if matchcat==1 & trial==5


** less than exact match
codebook 	bwt if matchcat==0 & trial==5
codebook    gestage if matchcat==0 & trial==5
tab		    sex if matchcat==0 & trial==5
tab		    matedu if matchcat==0 & trial==5
tab		    smokdur if matchcat==0 & trial==5
codebook    iq_score if matchcat==0 & trial==5
codebook    bayley_MDI if matchcat==0 & trial==5
codebook    bayley_PDI if matchcat==0 & trial==5
tab 		group if matchcat==0 & trial==5

** not matched
codebook 	bwt if matchcat==. & trial==5
codebook    gestage if matchcat==. & trial==5
tab		    sex if matchcat==. & trial==5
tab		    matedu if matchcat==. & trial==5
tab		    smokdur if matchcat==. & trial==5
codebook    iq_score if matchcat==. & trial==5
codebook    bayley_MDI if matchcat==. & trial==5
codebook    bayley_PDI if matchcat==. & trial==5
tab 		group if matchcat==. & trial==5

** overall
codebook 	bwt if trial==5
codebook    gestage if trial==5
tab		    sex if trial==5
tab		    matedu if trial==5
tab		    smokdur if trial==5
codebook    iq_score if trial==5
codebook    bayley_MDI if trial==5
codebook    bayley_PDI if trial==5
tab 		group if trial==5

********************************************************************************
** characteristics by matchstatus (Trial 7)						  			  **
********************************************************************************

** exact match
codebook 	bwt if matchcat==1 & trial==7
codebook    gestage if matchcat==1 & trial==7
tab		    sex if matchcat==1 & trial==7
tab		    matedu if matchcat==1 & trial==7
tab		    smokdur if matchcat==1 & trial==7
codebook    iq_score if matchcat==1 & trial==7
codebook    bayley_MDI if matchcat==1 & trial==7
codebook    bayley_PDI if matchcat==1 & trial==7
tab 		group if matchcat==1 & trial==7


** less than exact match
codebook 	bwt if matchcat==0 & trial==7
codebook    gestage if matchcat==0 & trial==7
tab		    sex if matchcat==0 & trial==7
tab		    matedu if matchcat==0 & trial==7
tab		    smokdur if matchcat==0 & trial==7
codebook    iq_score if matchcat==0 & trial==7
codebook    bayley_MDI if matchcat==0 & trial==7
codebook    bayley_PDI if matchcat==0 & trial==7
tab 		group if matchcat==0 & trial==7

** not matched
codebook 	bwt if matchcat==. & trial==7
codebook    gestage if matchcat==. & trial==7
tab		    sex if matchcat==. & trial==7
tab		    matedu if matchcat==. & trial==7
tab		    smokdur if matchcat==. & trial==7
codebook    iq_score if matchcat==. & trial==7
codebook    bayley_MDI if matchcat==. & trial==7
codebook    bayley_PDI if matchcat==. & trial==7
tab 		group if matchcat==. & trial==7

** overall
codebook 	bwt if trial==7
codebook    gestage if trial==7
tab		    sex if trial==7
tab		    matedu if trial==7
tab		    smokdur if trial==7
codebook    iq_score if trial==7
codebook    bayley_MDI if trial==7
codebook    bayley_PDI if trial==7
tab 		group if trial==7
*/


********************************************************************************
** characteristics by matchstatus (only randomised)					  			  **
********************************************************************************

** exact match
codebook 	bwt if matchcat==1 & group!=4
codebook    gestage if matchcat==1 & group!=4
tab		    sex if matchcat==1 & group!=4
tab		    matedu if matchcat==1 & group!=4
tab		    smokdur if matchcat==1 & group!=4
codebook    iq_score if matchcat==1 & group!=4
codebook    bayley_MDI if matchcat==1 & group!=4
codebook    bayley_PDI if matchcat==1 & group!=4
tab 		group if matchcat==1 & group!=4


** less than exact match
codebook 	bwt if matchcat==0 & group!=4
codebook    gestage if matchcat==0 & group!=4
tab		    sex if matchcat==0 & group!=4
tab		    matedu if matchcat==0 & group!=4
tab		    smokdur if matchcat==0 & group!=4
codebook    iq_score if matchcat==0 & group!=4
codebook    bayley_MDI if matchcat==0 & group!=4
codebook    bayley_PDI if matchcat==0 & group!=4
tab 		group if matchcat==0 & group!=4

** not matched
codebook 	bwt if matchcat==. & group!=4
codebook    gestage if matchcat==. & group!=4
tab		    sex if matchcat==. & group!=4
tab		    matedu if matchcat==. & group!=4
tab		    smokdur if matchcat==. & group!=4
codebook    iq_score if matchcat==. & group!=4
codebook    bayley_MDI if matchcat==. & group!=4
codebook    bayley_PDI if matchcat==. & group!=4
tab 		group if matchcat==. & group!=4

** overall
codebook 	bwt if group!=4
codebook    gestage if group!=4
tab		    sex if group!=4
tab		    matedu if group!=4
tab		    smokdur if group!=4
codebook    iq_score if group!=4
codebook    bayley_MDI if group!=4
codebook    bayley_PDI if group!=4
tab 		group if group!=4
*/
