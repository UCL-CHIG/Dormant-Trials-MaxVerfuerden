/*******************************************************************************
purpose:		Code for extreme case analyses (sensitivity analysis CH6)
date 
created: 		01/06/2020
last updated: 	25/06/2020 - 1 SD lower/higher instead of highest/lowest grade (half doesnt include MI estimate!)
last run:	 	25/06/2020
author: 		maximiliane verfuerden

*******************************************************************************/


*HOUSEKEEPING*
clear
cd 				"S:\Head_or_Heart\max\post-trial-extension"
qui do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
cap qui			do "S:\Head_or_Heart\max\attributes\7-ado\dropmiss.ado"
cap	qui			do "S:\Head_or_Heart\max\attributes\7-ado\renvars.ado"
cap qui 		do "S:\Head_or_Heart\max\post-trial-extension\00-ado\groups.ado"
cap qui 		do "S:\Head_or_Heart\max\post-trial-extension\00-ado\regsave.ado"
capture 		log close
log 			using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\ch6_extremecase$S_DATE.log", replace
timer      	 	clear
timer       	on 1

*LOAD DATASET*
use 			"S:\Head_or_Heart\max\post-trial-extension\1-data\samplingframe.dta", clear

*PREPRE DATASET*
drop 			if group==4 // to not skew the z-scores from breastfed groups
drop 			if group==3 // to not skew the z-scores from cowsmilk group
drop 			if trial ==1
drop			if trial ==2
tab 			trial group, nolab		
tabstat			gcse2210_score, by(trial) s(mean sd min max)



********************************************************************************
*	EXTREME: 	SCENARIO 1
*				all missing in intervention have half an SD lower 			
*				all missing in control have half an SD higher								 	       
********************************************************************************

*** overall z-score
tabstat			gcse2210_score, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
capture noisily egen			z_gcsemat_t`l' = std(gcse2210_score) if trial == `l' 
tabstat			z_gcsemat_t`l',  s(mean sd min max)
}
egen			z_gcsemat_1 = rowmean(z_gcsemat_t*)

* z-scores by group without replacing with extreme values
bysort trial: 	tabstat	z_gcsemat_1, by(group) s(mean sd min max)

*** replace missing in intervention with half an SD lower than the average 
bysort trial: 	count if z_gcsemat_1==. & group==1
replace			z_gcsemat_1 =  -1  if z_gcsemat_1==. & group==1

*** impute missing in control = half an SD higher than the average 
bysort trial:	count if z_gcsemat_1==. & group==2
replace			z_gcsemat_1 =  1  if z_gcsemat_1==. & group==2

* are they as expected? (compare with results of same command a couple of lines above)
bysort trial: 	tabstat	z_gcsemat_1, by(group) s(mean sd min max)


*** adjusted analysis
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
capture noisily eststo: 		regress		z_gcsemat_1 i.sex ib2.group bwt gestage i.centre i.smokdur i.matedu if trial==`l' 	
capture noisily esttab 			using 5-documents\ch6extremecase.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers mtitles("GCSE Maths Z-score" "CI") nobase title("{\b Trial `l' extreme case 1: missing I. have 1 SD lower missing C. have 1 SD higher }") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}


capture			drop z_gcsemat_t*

********************************************************************************
*	EXTREME: 	SCENARIO 2
*				all missing in intervention have half an SD higher			
*				all missing in control have half an SD lower
********************************************************************************


*** overall z-score
tabstat			gcse2210_score, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
capture noisily egen			z_gcsemat_t`l' = std(gcse2210_score) if trial == `l' 
tabstat			z_gcsemat_t`l',  s(mean sd min max)
}
egen			z_gcsemat_2 = rowmean(z_gcsemat_t*)

* z-scores by group without replacing with extreme values
bysort trial: 	tabstat	z_gcsemat_2, by(group) s(mean sd min max)

*** replace missing in intervention with half an SD lower than the average 
bysort trial: 	count if z_gcsemat_2==. & group==1
replace			z_gcsemat_2 =  1  if z_gcsemat_2==. & group==1

*** impute missing in control = half an SD higher than the average 
bysort trial:	count if z_gcsemat_2==. & group==2
replace			z_gcsemat_2 =  -1  if z_gcsemat_2==. & group==2

* are they as expected? (compare with results of same command a couple of lines above)
bysort trial: 	tabstat	z_gcsemat_2, by(group) s(mean sd min max)



*** adjusted analysis
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
capture noisily eststo: 		regress		z_gcsemat_2 i.sex ib2.group bwt gestage i.centre i.smokdur i.matedu if trial==`l' 	
capture noisily esttab 			using 5-documents\ch6extremecase.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers mtitles("GCSE Maths Z-score" "CI") nobase title("{\b Trial `l' extreme case 2: missing I. have 1 SD higher missing C. 1 SD lower}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}


capture			drop z_gcsemat_t*




/*


********************************************************************************
*				CRUDE: available cases								 	       
********************************************************************************

*** create z-score for available cases:
tabstat			gcse2210_score, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
capture noisily egen			z_gcsemat_t`l' = std(gcse2210_score) if trial == `l' 
tabstat			z_gcsemat_t`l',  s(mean sd min max)
}
egen			z_gcsemat = rowmean(z_gcsemat_t*)

tabstat			z_gcsemat,  s(mean sd min max) by(trial)


*** adjusted analysis
levelsof		trial, local(levels) 
foreach			l of local levels {
capture noisily regress		z_gcsemat ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu if trial==`l', base	
}
/*
// here I tested assumption for all trials:
capture		drop r
regress		z_gcsemat ib2.group bwt gestage i.centre i.smokdur i.matedu if trial==4 & !missing(matedu, smokdur, bwt, gestage, centre, z_gcsemat), base	
predict r, resid
kdensity r, normal
pnorm r			
qnorm r
*/

capture			drop z_gcsemat_t*



**** INTERVENTION ***
*** impute missing = best score
generate		gcse2210_score_high = gcse2210_score
replace			gcse2210_score_high = 8 if gcse2210_score==. & group==1
replace			gcse2210_score_high = 1 if gcse2210_score==. & group==2


*** create z-score
tabstat			gcse2210_score_high, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
capture noisily egen			z_gcsemat_t`l' = std(gcse2210_score_high) if trial == `l' 
tabstat			z_gcsemat_t`l',  s(mean sd min max)
}
egen			z_gcsemat_high = rowmin(z_gcsemat_t*)


*** adjusted analysis
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
capture noisily eststo: 		regress		z_gcsemat_high ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l'
capture noisily esttab 			using 5-documents\ch6extremecase.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers mtitles("GCSE Maths Z-score" "CI") nobase title("{\b Trial `l' extreme case: missing I. have highest score missing C. have lowest score}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}



********************************************************************************
*	EXTREME: all missing in intervention have the lowest score			
*			 all missing in control have the highest score								 	       
********************************************************************************

*** impute missing in intervention = lowest score
generate		gcse2210_score_low = gcse2210_score
replace			gcse2210_score_low = 1 if gcse2210_score==. & group==1
replace			gcse2210_score_low = 8 if gcse2210_score==. & group==2

*** create z-score
tabstat			gcse2210_score_low, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
capture noisily egen			z_gcsemat_t`l' = std(gcse2210_score_low) if trial == `l' 
tabstat			z_gcsemat_t`l',  s(mean sd min max)
}
egen			z_gcsemat_low = rowmin(z_gcsemat_t*)


*** adjusted analysis
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
capture noisily eststo: 		regress		z_gcsemat_low i.sex ib2.group bwt gestage i.centre i.smokdur i.matedu if trial==`l' 	
capture noisily esttab 			using 5-documents\ch6extremecase.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers mtitles("GCSE Maths Z-score" "CI") nobase title("{\b Trial `l' extreme case: missing I. have lowest score missing C. have highest score}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}


capture			drop z_gcsemat_t*

********************************************************************************
*	EXTREME: all missing in intervention have the highest score			
*			 all missing in control have the lowest score
********************************************************************************


**** INTERVENTION ***
*** impute missing = best score
generate		gcse2210_score_high = gcse2210_score
replace			gcse2210_score_high = 8 if gcse2210_score==. & group==1
replace			gcse2210_score_high = 1 if gcse2210_score==. & group==2


*** create z-score
tabstat			gcse2210_score_high, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
capture noisily egen			z_gcsemat_t`l' = std(gcse2210_score_high) if trial == `l' 
tabstat			z_gcsemat_t`l',  s(mean sd min max)
}
egen			z_gcsemat_high = rowmin(z_gcsemat_t*)


*** adjusted analysis
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
capture noisily eststo: 		regress		z_gcsemat_high ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l'
capture noisily esttab 			using 5-documents\ch6extremecase.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers mtitles("GCSE Maths Z-score" "CI") nobase title("{\b Trial `l' extreme case: missing I. have highest score missing C. have lowest score}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}




* SGA PDP
graph box 		z_gcsemat_high z_gcsemat z_gcsemat_low if group!=3 & inlist(trial, 3,4), over(group, label(labsize(vsmall)))  by(trial)  nofill box(1,bfcolor(dknavy) blcolor(black)) marker(1, mcolor(dknavy)) box(2,bfcolor(green) blcolor(black)) marker(2, mcolor(green)) box(3,bfcolor(ebblue) blcolor(black)) marker(3, mcolor(ebblue))

* LCPUFA trials
graph box 		z_gcsemat_high z_gcsemat z_gcsemat_low if group!=3 & inlist(trial, 5,6), over(group, label(labsize(vsmall)))  by(trial)  nofill box(1,bfcolor(dknavy) blcolor(black)) marker(1, mcolor(dknavy)) box(2,bfcolor(green) blcolor(black)) marker(2, mcolor(green)) box(3,bfcolor(ebblue) blcolor(black)) marker(3, mcolor(ebblue))

* Nucleotides
graph box 		z_gcsemat_high z_gcsemat z_gcsemat_low if group!=3 & inlist(trial, 7), over(group, label(labsize(vsmall)))  by(trial)  nofill box(1,bfcolor(dknavy) blcolor(black)) marker(1, mcolor(dknavy)) box(2,bfcolor(green) blcolor(black)) marker(2, mcolor(green)) box(3,bfcolor(ebblue) blcolor(black)) marker(3, mcolor(ebblue))

* Iron Palmitate
graph box 		z_gcsemat_high z_gcsemat z_gcsemat_low if group!=3 & inlist(trial, 8,9), over(group, label(labsize(vsmall)))  by(trial)  nofill box(1,bfcolor(dknavy) blcolor(black)) marker(1, mcolor(dknavy)) box(2,bfcolor(green) blcolor(black)) marker(2, mcolor(green)) box(3,bfcolor(ebblue) blcolor(black)) marker(3, mcolor(ebblue))

*/

*CLOSE ANALYSIS*
timer 	list 1
timer 	clear 
log 	close
