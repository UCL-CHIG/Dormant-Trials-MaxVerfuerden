capture 			log close
log 				using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\sensitivityanalysis$S_DATE.log", replace
/*==============================================================================
purpose:			Sensitivity analyses for my PhD 
date created: 		06/11/2020
last updated: 		17/11/2020 - deleted empty lines and cleaned up unnecessary tabs
					17/11/2020 - used this format for z-scores to make sure 
					its only within trial and z-scores are symmetric: z_gcsemat_t`l' 
					(instead of z_gcsemat that was generated using egen rowmean)
last run:	 		06/11/2020
					20/11/2020
author: 			maximiliane verfuerden
*==============================================================================*/
clear
cd 					"S:\Head_or_Heart\max\post-trial-extension"
qui do 				"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
timer      	 		clear
timer       		on 1
local				c_date = c(current_date)
display				"`c_date'"
local				time_string = subinstr("`c_date'",":","_",.)
local				time_string = subinstr("`time_string'"," ","_",.)
display				"`time_string'"
* 					***using complete case data
*******************************************************************************
use 				"S:\Head_or_Heart\max\post-trial-extension\1-data\samplingframe.dta", clear // complete case data
* exclude those that were only necessary for the imputation
drop				if died==1
drop 				if total_unmatched_at_step4 ==1
drop 				if group==4 | group==3
replace				iq_score=. if iq_score==-99
replace				later_iq_score=. if later_iq_score==-99
replace				bayley_MDI=. if bayley_MDI==-99
* crude grade distribution*
*******************************************************************************
bysort group: 		tab	gcse2210_score trial
* create z-scores*
*******************************************************************************
levelsof			trial, local(levels)  // English age 11
foreach				l of local levels {
egen				z_ks2eng_t`l' = std(ks2_engread_raw) if trial == `l' 
tabstat				ks2_engread_raw if trial == `l', s(mean sd) by(group) format(%5.4f)
tabstat				z_ks2eng_t`l' if trial == `l', s(mean sd) by(group) format(%5.4f)
}
levelsof			trial, local(levels) // Maths age 11
foreach				l of local levels {
egen				z_ks2mat_t`l' = std(ks2_mat_raw) if trial == `l' 
tabstat				ks2_mat_raw if trial == `l', s(mean sd) by(group) format(%5.4f)
tabstat				z_ks2mat_t`l' if trial == `l', s(mean sd) by(group) format(%5.4f)
}
levelsof			trial, local(levels)  // English age 16
foreach				l of local levels {
egen				z_gcseeng_t`l' = std(gcse5030_score) if trial == `l' 
tabstat				gcse5030_score if trial == `l', s(mean sd) by(group) format(%5.4f)
tabstat				z_gcseeng_t`l' if trial == `l', s(mean sd) by(group) format(%5.4f)
}
levelsof			trial, local(levels)  // Maths age 16
foreach				l of local levels {
egen				z_gcsemat_t`l' = std(gcse2210_score) if trial == `l' 
tabstat				gcse2210_score if trial == `l', s(mean sd) by(group) format(%5.4f)
tabstat				z_gcsemat_t`l' if trial == `l', s(mean sd) by(group) format(%5.4f)
}
*national z-scores*
gen					z_gcsemat_nat = (gcse2210_score - 4.970)/ 1.8005
tabstat				z_gcsemat_nat, by(trial) s(mean sd min max) format(%5.4f)
* correlation between measures
*******************************************************************************
levelsof			trial, local(levels)  
foreach				l of local levels {
display as input	"***Trial `l': Correlations (complete case data)"
pwcorr				bayley_MDI z_gcsemat_t`l' z_gcseeng_t`l'  z_ks2mat_t`l' z_ks2eng_t`l'
}
pwcorr				bayley_MDI  iq_score ks2_engread_raw ks2_mat_raw gcse5030_score gcse2210_score later_iq_score, obs 
*Does early development predict performance at school?*
*******************************************************************************
egen				z_bmdi = std(bayley_MDI) // BMDI 
tabstat				z_bmdi, s(mean sd) by(group) format(%5.4f)
egen				z_iq = std(iq_score) // iq_score 
tabstat				z_iq, s(mean sd) by(group) format(%5.4f)
egen				z_ks2eng = std(ks2_engread_raw) // English age 11
tabstat				z_ks2eng, s(mean sd) by(group) format(%5.4f)
egen				z_ks2mat = std(ks2_mat_raw) // Maths age 11
egen				z_gcseeng = std(gcse5030_score) // English age 16
egen				z_gcsemat = std(gcse2210_score)  // Maths age 16
egen				z_2ndiq= std(later_iq_score) // later iq_score 
foreach var of varlist  z_iq z_ks2eng z_ks2mat  z_gcseeng z_gcsemat z_2ndiq {
regress 	`var' z_bmdi i.trial i.sex bwt gestage i.matedu i.smokdur, vce(robust)
}
foreach var of varlist   z_ks2eng z_ks2mat  z_gcseeng z_gcsemat z_2ndiq {
regress 	`var' z_iq i.trial i.sex bwt gestage i.matedu i.smokdur, vce(robust)
}
foreach var of varlist  z_ks2mat  z_gcseeng z_gcsemat z_2ndiq {
regress 	`var' z_ks2eng i.trial i.sex bwt gestage i.matedu i.smokdur, vce(robust)
}
foreach var of varlist  z_ks2eng  z_gcseeng z_gcsemat z_2ndiq {
regress 	`var' z_ks2mat i.trial i.sex bwt gestage i.matedu i.smokdur, vce(robust)
}
foreach var of varlist z_gcsemat z_2ndiq {
regress 	`var' z_gcseeng i.trial i.sex bwt gestage i.matedu i.smokdur, vce(robust)
}
foreach var of varlist z_gcseeng  z_2ndiq {
regress 	`var' z_gcsemat i.trial i.sex bwt gestage i.matedu i.smokdur, vce(robust)
}
foreach var of varlist z_ks2eng z_ks2mat  z_gcseeng z_gcsemat z_2ndiq {
regress 	`var' later_iq_score i.sex bwt gestage i.matedu i.smokdur, vce(robust)
}
* unadjusted complete case analysis:
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"***Trial `l': GCSE Maths z-score, unadjusted CC"
cap noisily regress	z_gcsemat_t`l' ib2.group if trial==`l', base vce(robust)
cap noisily margins	i.group
cap noisily tab		group if e(sample) & trial==`l' // gives me the participant numbers in each group
eststo 				clear
cap qui eststo: regress	z_gcsemat`l' ib2.group if trial==`l', base	vce(robust)
cap qui esttab 	using 5-documents\sensitivityanalysis`time_string'.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': GCSE Maths z-score, unadjusted CC}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME") // save results in word document
eststo 				clear
}
* adjusted complete case analysis: 
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"***Trial `l': GCSE Maths z-score, adjusted CC"
cap noisily 		regress	z_gcsemat_t`l' ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu if trial==`l', vce(robust)	
cap noisily 		margins	i.group
cap noisily 		tab		group if e(sample) & trial==`l' // gives me the participant numbers in each group
eststo 				clear
cap qui eststo: 	regress		z_gcsemat`l' ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu if trial==`l', noconstant vce(robust)	
cap qui esttab 		using 5-documents\sensitivityanalysis`time_string'.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': GCSE Maths z-score, adjusted CC}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME") // save results in word document
eststo 				clear
}
display as input	"***Trial 9: GCSE Maths z-score, adjusted CC"
cap noisily 		regress	z_gcsemat_t9 ib2.group bwt i.sex gestage i.smokdur i.matedu if trial==9,  vce(robust)	
cap noisily 		margins	i.group
cap noisily 		tab		group if e(sample) & trial==9 // gives me the participant numbers in each group
eststo 				clear
cap qui eststo: 	regress		z_gcsemat_t9 ib2.group bwt i.sex gestage i.smokdur i.matedu if trial==9, noconstant vce(robust)	
cap qui esttab 		using 5-documents\sensitivityanalysis`time_string'.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': GCSE Maths z-score, adjusted CC}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME") // save results in word document
eststo 				clear
* unadjusted complete case analysis national SD:
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"Trial `l': GCSE Maths z-score national SD, unadjusted CC"
cap noisily 		regress	z_gcsemat_nat' ib2.group if trial==`l', vce(robust)
cap noisily 		margins	i.group
cap noisily 		tab		group if e(sample) & trial==`l' // gives me the participant numbers in each group
eststo 				clear
cap qui eststo: 	regress	z_gcsemat_nat ib2.group if trial==`l', base	vce(robust)
cap qui esttab 		using 5-documents\nationalSDs`time_string'.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': GCSE Maths z-score national SD, unadjusted CC}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME") // save results in word document
eststo 				clear
}
* adjusted complete case analysis national SD: 
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"***Trial `l': GCSE Maths z-score national SD, adjusted CC"
cap noisily 		regress	z_gcsemat_nat ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu if trial==`l', noconstant vce(robust)	
cap noisily 		margins	i.group
cap noisily 		tab		group if e(sample) & trial==`l' // gives me the participant numbers in each group
eststo 				clear
cap qui eststo: 	regress		z_gcsemat_nat ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu if trial==`l', noconstant vce(robust)	
cap qui esttab 		using 5-documents\sensitivityanalysis`time_string'.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': GCSE Maths z-score national SD, adjusted CC}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME") // save results in word document
eststo 				clear
}
display as input	"***Trial 9: GCSE Maths z-score national SD, adjusted CC"
cap noisily 		regress	z_gcsemat_nat ib2.group bwt i.sex gestage i.smokdur i.matedu if trial==9, vce(robust)	
cap noisily 		margins	i.group
cap noisily 		tab		group if e(sample) & trial==9 // gives me the participant numbers in each group
eststo 				clear
cap qui eststo: 	regress		z_gcsemat_nat ib2.group bwt i.sex gestage i.smokdur i.matedu if trial==9, vce(robust)	
cap qui esttab 		using 5-documents\sensitivityanalysis`time_string'.rtf, noconstant  append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': GCSE Maths z-score national SD, adjusted CC}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME") // save results in word document
eststo 				clear
* 					using MI data
*******************************************************************************
use					"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_mainoutcomes2.dta", clear
* exclude those that were only necessary for the imputation
drop				if trial == 1 | trial==2 | trial==7
drop if				died==1
drop if				group ==3 | group==4
tab 				trial group, nolab m	
* verify that the z-scores have a mean of 0 and an SD of 1
levelsof			trial, local(levels)  // Maths age 16
foreach				l of local levels {
tabstat				gcse2210_score if trial == `l', s(mean sd) by(group) format(%5.4f)
tabstat				z_gcsemat_t`l' if trial == `l', s(mean sd) by(group) format(%5.4f)
}
* unadjusted MI analysis:
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"***Trial `l': GCSE Maths z-score, unadjusted MI"
cap noisily 		mi estimate: regress z_gcsemat_t`l' ib2.group if trial==`l', vce(robust)
cap noisily 		mimrgns	i.group	
eststo 				clear
cap qui 			eststo: mi estimate, post: regress z_gcsemat`l' ib2.group if trial==`l', vce(robust)
cap qui 			esttab 	using 5-documents\sensitivityanalysis`time_string'.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': GCSE Maths z-score, unadjusted MI}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME") // save results in word document
eststo 				clear
}
* unadjusted MI analysis using national SD:
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"***Trial `l': GCSE Maths z-score, unadjusted MI"
cap noisily 		mi estimate: regress z_gcsemat_nat ib2.group if trial==`l',  vce(robust)
cap noisily 		mimrgns	i.group	
eststo 				clear
cap qui 			eststo: mi estimate, post: regress z_gcsemat_nat ib2.group if trial==`l', vce(robust)
cap qui 			esttab 	using 5-documents\sensitivityanalysis`time_string'.rtf,  append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': GCSE Maths national z-score, unadjusted MI}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME") // save results in word document
eststo 				clear
}
* adjusted MI analysis using national SD:
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"***Trial `l': GCSE Maths z-score, unadjusted MI"
cap noisily 		mi estimate: regress z_gcsemat_nat ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu if trial==`l',  vce(robust)
cap noisily 		mimrgns	i.group	
display as input	"***Trial 9: GCSE Maths z-score, unadjusted MI"
cap noisily 		mi estimate: regress z_gcsemat_nat ib2.group bwt i.sex gestage i.smokdur i.matedu if trial==9,  vce(robust)
cap noisily 		mimrgns	i.group	
eststo 				clear
cap qui 			eststo: mi estimate, post: regress z_gcsemat_nat ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu  if trial==`l', vce(robust)
cap qui 			esttab 	using 5-documents\nationalSDs`time_string'.rtf,  append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': GCSE Maths national z-score, unadjusted MI}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME") // save results in word document
eststo 				clear
}
* ordinal log reg:
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"***Trial `l': ordinal log reg"
cap noisily 		mi estimate: ologit gcse2210_score ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu if trial==`l  
cap noisily 		mimrgns	i.group	
eststo 				clear
}		 
*===============================================================================
timer				off 1
timer 				list 1
display as input	"time of do-file in minutes:" r(t1) / 60
timer 				clear 
log 				close