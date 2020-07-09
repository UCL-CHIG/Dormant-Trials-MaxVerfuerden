/*******************************************************************************
purpose: 			selects sample of matches above weight 15 and then deduplicates.
					// 15 is now out of date but to not confuse file paths I'll stay with the file name
date 
created: 			18/06/2019
last updated: 		28/06/2019 - now includes the breastfed ones
					07/07/2020 - made code more readable
author: 			maximiliane verfuerden
					// also excludes those that died and have no link
*******************************************************************************/


*	HOUSEKEEPING	*
clear
cd 				"S:\Head_or_Heart\max\post-trial-extension"
qui do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
cap qui			do "S:\Head_or_Heart\max\attributes\7-ado\dropmiss.ado"
cap	qui			do "S:\Head_or_Heart\max\attributes\7-ado\renvars.ado"
cap qui 		do	"S:\Head_or_Heart\max\post-trial-extension\00-ado\groups.ado"
capture 		log close
log 			using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\04.4-cr_matches15andabove$S_DATE.log", replace
use				"${datadir}\weightsandcharacteristics.dta",clear
count		


********************************************************************************
** drop unmatched participants:
********************************************************************************
tab 			twotrials, m
drop if			unmatched==1
drop			unmatched
drop if			W<9					
count							
tab 			twotrials, m
order			trial studyid1 pupilreference W oth* d_dob mult* group 
sort			d_dob W oth* mult* pupilreference group

********************************************************************************
** generate an ID for participants with multiple possible matches:
********************************************************************************
duplicates 		tag studyid1, gen(multiplematch)
tab				multiplematch 							

********************************************************************************
** order the matches by weights (descending)
********************************************************************************
gsort			studyid1 -W
by				studyid1, sort: gen multi_id = _n

********************************************************************************
*				CLEAN: CHECK PUPILREFERENCE DUPLICATES								   *
********************************************************************************
tab 			trial
duplicates 		tag pupilreference, g(check)
tab 			check 
count			if check==1 & twotrials!=1
order			trial RCTsex NPDsex pupilreference W studyid1 othid*
sort			pupilreference	
/* some have other ids but are not recorded as having participated in multiple trials
below I list the pupilreferences for which this is the case */
replace			twotrials =1 if inlist(pupilreference, 83, 115,146,524, 465, 639,1126, 1269, 1567,1754,2936,3194,3263,3487,3541, 3676, 3762, 4279,4622, 5013, 5936, 6082, 3817, 6436,6895, 7260, 7905, 8785, 8849, 9781, 9895, 10070, 12032, 12375, 12588, 13027, 13239, 13699, 6151, 11290, 9718, 7518)  // UN007 definitely I checked
count			if check==1 & twotrials!=1 
drop			if pupilreference ==10677 & studyid1 =="PUF032"
drop if			studyid1== "PTF162" & pupilreference ==12290
drop if			studyid1== "SUN012" & pupilreference ==11382
* twin issues
drop if			studyid1== "SUF011" & pupilreference ==11358 // wrong twin matched also
drop if			studyid1== "T067" & pupilreference ==13368 // wrong twin matched also
* these ones share a pupil record but are less likely to be the same person *
replace			RCTsex = 2 if studyid1 =="PTF200"
replace			RCTsex = 2 if studyid1 =="UN007"
drop			check
duplicates 		tag pupilreference, g(check)
count			if check==1 & twotrials!=1 // 0

********************************************************************************
* copy missing clinical information over for those who (legit) share the same pupilID *
********************************************************************************
count			if check==1  

foreach v of varlist bwt gestage smokdur iq_score died alcdur teen matedu {
generate		`v'_new = `v'
by pupilreference, sort : replace `v'_new = `v'[_n-1] if missing(`v') & check==1
by pupilreference, sort : replace `v'_new = `v'[_n+1] if missing(`v'_new) & check==1
}

foreach v of varlist smokdur iq_score died alcdur teen matedu {
replace		`v' = `v'_new if !missing(`v'_new)
}


********************************************************************************
** what is the weight difference between the potential matches?
********************************************************************************
bysort			studyid1: gen diff = W[1] -W[_N]
order			multi_id studyid1  W  diff
sort			multiplematch studyid1 
sort			W
********************************************************************************
** which duplicates have the same match weight?
********************************************************************************
count if		diff ==0 & multiplematch >0  						// 2 participants, need to manually reviewed (5 with bf)

********************************************************************************
** there are a couple of tough close decisions too:
********************************************************************************
count			if diff <2 & diff >0 								// 4 participants, need to be manually reviewed

********************************************************************************
** mark those that I want to manually review:
********************************************************************************
gen				manreview = 1 if diff ==0 & multiplematch >0
replace			manreview = 1 if diff <2 & diff >0
label var		manreview "manually reviewed best match"

********************************************************************************
** keep only the matches with the highest weight:
********************************************************************************
tab 			trial group if manreview ==1, m 
tab				multi_id, m
tab				manreview, m
keep 			if multi_id==1 | manreview ==1 							

********************************************************************************
** manually review duplicates with same match weight:
********************************************************************************
drop 			if 	diff ==0 & multiplematch >0 & falsematch==1 		
drop 			if 	diff ==0 & multiplematch >0 & multi_id==2 			// deletes those with multi_id==2 (works bc records ordered by weight)
drop 			if 	diff <2 & multiplematch >0 & multi_id==2 	 


********************************************************************************
** drop those with a match weight of <9:
********************************************************************************
count if		W<9		
tab 			trial group if W<9
drop if			W<9 	
count 			// 1,859 ( 2,502 with breastfed)



/*******************************************************************************
** manually review duplicates with super similar match weight:
********************************************************************************
 remove those where dob was weighted lower than authority
drop 		if 	diff <2 & diff >0 & dbscore==200 | dbscore==61 	// 21 removed 
*/

********************************************************************************
** are there still duplicates?
********************************************************************************
drop 			multiplematch
duplicates 		tag studyid1, gen(multiplematch)
tab				multiplematch 				// no, no more duplicates :)		
tab 			died		
count										

/*******************************************************************************
save
*******************************************************************************/
drop			diff dup truematch falsematch *prob* w_* r_* manrev* *_sgaterm *_nuc *lcpre *match
order			studyid1 pupilreference W trial twotrials oth* group birthyear sex firstagelink
count if		pupilreference==. 								
count if		studyid1 ==""										
descr, s														

save			"S:\Head_or_Heart\max\post-trial-extension\1-data\matches15andup_non_dup.dta", replace
cap				log close
