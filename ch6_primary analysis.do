/*******************************************************************************
purpose:		Code to run primary analysis for PhD Chapter 6
date 
created: 		31/01/2020
last updated: 	01/02/2020
				21/05/2020 - unblinded
				23/05/2020 - replaced birthyear with birthmonth because byr collinear with trial
				21/07/2020 - I realised I forgot to include gestational age in the imputation model
last run:	 	01/02/2020
				27/04/2020
				21/05/2020
				22/06/2020
				25/06/2020
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
log 			using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\ch6_primary analysis$S_DATE.log", replace

*LOAD DATASET*
use 			"S:\Head_or_Heart\max\post-trial-extension\1-data\samplingframe.dta", clear

*DESCRIBE DATASET*
tab 			trial group, nolab		

* exclude those that were only necessary for the imputation
tab 			trial group  if died==1	
drop			if died==1
drop 			if group==4 // to not skew the z-scores
drop			if group==3

********************************************************************************
*				CREATE Z-SCORES	 (for complete case analysis)									 	       
********************************************************************************
replace 		bayley_MDI=. if  bayley_MDI==-99
replace 		bayley_PDI=. if  bayley_PDI==-99
replace 		iq_score=. if  bayley_PDI==-99

* z-score Bayley MDI (only in trials 3-6 and 8) :		
tabstat			bayley_MDI, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
egen			z_bayleyMDI_t`l' = std(bayley_MDI) if trial == `l'  & !inlist(trial,7,9)
tabstat			z_bayleyMDI_t`l',  s(mean sd min max)
}

* z-score Bayley PDI :		
tabstat			bayley_PDI, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
egen			z_bayleyPDI_t`l' = std(bayley_PDI) if trial == `l' & !inlist(trial,7,9)
tabstat			z_bayleyPDI_t`l',  s(mean sd min max)
}

* z-score IQ score :		
tabstat			iq_score, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
egen			z_iq_score_t`l' = std(iq_score) if trial == `l' & !inlist(trial,7,8,9)
tabstat			z_iq_score_t`l',  s(mean sd min max)
}

* z-score GCSE Mathematics:		
tabstat			gcse2210_score, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
egen			z_gcsemat_t`l' = std(gcse2210_score) if trial == `l' 
tabstat			z_gcsemat_t`l',  s(mean sd min max)
}

* z-score GCSE English lang:		
tabstat			gcse5030_score, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
egen			z_gcseeng_t`l' = std(gcse5030_score) if trial == `l' 
tabstat			z_gcseeng_t`l',  s(mean sd min max)
}

* z-score KS2 Mathematics:		
tabstat			ks2_mat_raw, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
egen			z_ks2mat_t`l' = std(ks2_mat_raw) if trial == `l' 
tabstat			z_ks2mat_t`l',  s(mean sd min max)
}

* z-score KS2 English lang:		
tabstat			ks2_engread_raw, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
egen			z_ks2eng_t`l' = std(ks2_engread_raw) if trial == `l' 
tabstat			z_ks2eng_t`l',  s(mean sd min max)
}

* copy to all records:	
levelsof		trial, local(levels) 
foreach			l of local levels {
bysort 			pupilreference: egen min_z_gcsemat_t`l' = min(z_gcsemat_t`l')
bysort 			pupilreference: egen min_z_gcseeng_t`l' = min(z_gcseeng_t`l')
bysort 			pupilreference: egen min_z_ks2mat_t`l' = min(z_ks2mat_t`l')
bysort 			pupilreference: egen min_z_ks2eng_t`l' = min(z_ks2eng_t`l')
drop			z_gcsemat_t`l' z_gcseeng_t`l' z_ks2mat_t`l' z_ks2eng_t`l'
}
rename			min_* * 


egen			z_gcsemat = rowmean(z_gcsemat_t*)
egen			z_gcseeng = rowmean(z_gcseeng_t*)
egen			z_ks2mat = rowmean(z_ks2mat_t*)
egen			z_ks2eng = rowmean(z_ks2eng_t*)
egen			z_bayleyMDI = rowmean(z_bayleyMDI_t*)
egen			z_bayleyPDI = rowmean(z_bayleyPDI_t*)
egen			z_iq_score = rowmean(z_iq_score_t*)



* drop participants that were too young for GCSE in the NPD
drop if			((age_ks4 <15 & age_ks4 >16) | age_ks4==. ) & trial==7
drop if			died==1




********************************************************************************
*				- COMPLETE CASE	- 
********************************************************************************

*
* crude analysis for all trials, save in word document:
*
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
cap noisily 	eststo: 	regress		z_gcsemat ib2.group if trial==`l', base	
cap noisily 	esttab 		using 5-documents\ch6primaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers mtitles("GCSE Maths Z-score" "CI") nobase title("{\b Trial `l' primary analysis crude complete case}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}

// save results into stata dataset to graph later on:
parmby  "regress z_gcsemat ib2.group", by(trial) saving(1-data\crude_completecase, replace)

*
* adjusted analysis for all trials, save in word document:
*
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
cap noisily 	eststo: 		regress		z_gcsemat ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu if trial==`l', base	
cap noisily 	esttab 			using 5-documents\ch6primaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers mtitles("GCSE Maths Z-score" "CI") nobase title("{\b Trial `l' primary analysis adjusted complete case}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 			clear
}

* save into stata dataset to graph later on:
parmby  "regress z_gcsemat ib2.group bwt gestage i.centre i.smokdur i.matedu if !missing(matedu, smokdur, bwt, gestage, centre, z_gcsemat)", by(trial) saving(1-data\adjusted_completecase, replace)

********************************************************************************
*				- MULTIPLE IMPUTATION -							 			   
********************************************************************************
*LOAD DATASET*
use				"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_mainoutcomes.dta", clear
egen			z_gcsemat = rowmean(z_gcsemat_t*)


*DESCRIBE DATASET*
tab 			trial group if _mi_m==0, m  // no breastfed ones
* drop participants that were too young for GCSE in the NPD
drop if			((age_ks4 <15 & age_ks4 >16) | age_ks4==. ) & trial==7
tab 			trial group if _mi_m==0, m  //  1,727 kids (09 May 2020)
drop if			died==1


* crude analysis for all trials, save in word document:
levelsof		trial, local(levels) 
foreach			l of local levels {
eststo 			clear
eststo: 		mi estimate, post: regress	z_gcsemat ib2.group if trial==`l', base	
esttab 			using 5-documents\ch6primaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers mtitles("GCSE Maths Z-score" "CI") nobase title("{\b Trial `l' primary analysis crude MI}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo clear
}
* save into stata dataset to graph later on:
parmby  "mi estimate, post: regress z_gcsemat ib2.group", by(trial) saving(1-data\crude_MI, replace)

* adjusted analysis for all trials, save in word document:
levelsof		trial, local(levels) 
foreach			l of local levels {
				eststo 	clear
eststo: mi estimate, post: regress		z_gcsemat ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu if trial==`l', base	
				esttab 	using 5-documents\ch6primaryanalyses.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers mtitles("GCSE Maths Z-score" "CI") nobase title("{\b Trial `l' primary analysis adjusted MI}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo clear
}

* show mean z-scores by group - this is unadjusted (but accounts for MI using Rubins rules)
levelsof		trial, local(levels) 
foreach			l of local levels {
				display as input _dup(59) "_"
				display as input	"mean score in intervention group trial `l': "
				display as input _dup(59) "_"
mi estimate:	mean	z_gcsemat	if group ==1 & trial==`l'
				display as input _dup(59) "_"
				display as input	"mean score in control group trial `l': "
				display as input _dup(59) "_"
mi estimate:	mean	z_gcsemat	if group ==2 & trial==`l'
}

* in order to get adjusted means (for the covariates used in my model) I use the  mimrgns command (accounts for MI using Rubins rules)
mi estimate		: regress z_gcsemat ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu if trial==3
mimrgns			i.group


levelsof		trial, local(levels) 
foreach			l of local levels {
				display as input _dup(59) "_"
				display as input	"mean score in trial `l': "
				display as input _dup(59) "_"
mi estimate		: regress z_gcsemat ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu if trial==`l'
mimrgns			i.group
}

* save into stata dataset to graph later on:
parmby  "mi estimate, post: regress z_gcsemat ib2.group bwt i.sex gestage i.centre i.smokdur i.matedu", by(trial) saving(1-data\adjusted_MI, replace)


********************************************************************************
*				- CREATE SINGLE DATASET OF RESULTS -							 			   
********************************************************************************
use 			"S:\Head_or_Heart\max\post-trial-extension\1-data\crude_completecase.dta",clear
generate		temp_crude_cc = 1
append 			using "S:\Head_or_Heart\max\post-trial-extension\1-data\adjusted_completecase.dta", gen(temp_adj_cc)
append 			using "S:\Head_or_Heart\max\post-trial-extension\1-data\crude_MI.dta", gen(temp_crude_MI)
append 			using "S:\Head_or_Heart\max\post-trial-extension\1-data\adjusted_MI.dta", gen(temp_adj_MI)

generate		model = .
replace 		model =1 if temp_crude_cc == 1
replace 		model =2 if temp_adj_cc == 1
replace 		model =3 if temp_crude_MI == 1
replace 		model =4 if temp_adj_MI == 1

label 			define	model 1"crude cc" 2"adj cc" 3"crude MI" 4"adj MI"
label			values	model model

drop			temp_*

sort			trial model parmseq

save "S:\Head_or_Heart\max\post-trial-extension\1-data\ch6estimates.dta", replace
tab				trial, m
/*
recode			trial 3=1 4=2 5=3 6=4 8=5 9=6 
label def		trial 1"PD formula" 2"SGA formula" 3"DHA preterm formula" 4"DHA term formula" 5"High iron formula" 6"SN-2 Palmitate formula" 
label val		trial trial
*/

* Trial 3 *
graph			tw  scatter estimate model if parmseq==1 & trial==3 , lcolor(eltblue)  yline(0, lc(gs10)) xlab(1/4) ylab(,valuelabel angle(0)) plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) ///
				|| rspike min95 max95 model if parmseq==1 & trial==3 , lcolor(eltblue)  xlab(1/4) vertical xlab(,valuelabel angle(45)) ///
				 ytitle("Mean diff in GCSE Maths z-score") plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) title("Trial 3") ///
				 legend(off)

* Trial 4 *
graph			tw  scatter estimate model if parmseq==1 & trial==4 , lcolor(eltblue)  yline(0, lc(gs10)) xlab(1/4) ylab(,valuelabel angle(0)) plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) ///
				|| rspike min95 max95 model if parmseq==1 & trial==4 , lcolor(eltblue)  xlab(1/4) vertical xlab(,valuelabel angle(45)) ///
				 ytitle("Mean diff in GCSE Maths z-score") plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) title("Trial 4") ///
				 legend(off)				 
				 
* Trial 5 *
graph			tw  scatter estimate model if parmseq==1 & trial==5 , lcolor(eltblue)  yline(0, lc(gs10)) xlab(1/4) ylab(,valuelabel angle(0)) plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) ///
				|| rspike min95 max95 model if parmseq==1 & trial==5 , lcolor(eltblue)  xlab(1/4) vertical xlab(,valuelabel angle(45)) ///
				 ytitle("Mean diff in GCSE Maths z-score") plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) title("Trial 5") ///
				 legend(off)	
				 
* Trial 6 *
graph			tw  scatter estimate model if parmseq==1 & trial==6 , lcolor(eltblue)  yline(0, lc(gs10)) xlab(1/4) ylab(,valuelabel angle(0)) plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) ///
				|| rspike min95 max95 model if parmseq==1 & trial==6 , lcolor(eltblue)  xlab(1/4) vertical xlab(,valuelabel angle(45)) ///
				 ytitle("Mean diff in GCSE Maths z-score") plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) title("Trial 6") ///
				 legend(off)			
				 
* Trial 7 *
graph			tw  scatter estimate model if parmseq==1 & trial==7 , lcolor(eltblue)  yline(0, lc(gs10)) xlab(1/4) ylab(,valuelabel angle(0)) plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) ///
				|| rspike min95 max95 model if parmseq==1 & trial==7 , lcolor(eltblue)  xlab(1/4) vertical xlab(,valuelabel angle(45)) ///
				 ytitle("Mean diff in GCSE Maths z-score") plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) title("Trial 7") ///
				 legend(off)	
				 
* Trial 8 *
graph			tw  scatter estimate model if parmseq==1 & trial==8 , lcolor(eltblue)  yline(0, lc(gs10)) xlab(1/4) ylab(,valuelabel angle(0)) plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) ///
				|| rspike min95 max95 model if parmseq==1 & trial==8 , lcolor(eltblue)  xlab(1/4) vertical xlab(,valuelabel angle(45)) ///
				 ytitle("Mean diff in GCSE Maths z-score") plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) title("Trial 8") ///
				 legend(off)	

* Trial 9 *
graph			tw  scatter estimate model if parmseq==1 & trial==9 , lcolor(eltblue)  yline(0, lc(gs10)) xlab(1/4) ylab(,valuelabel angle(0)) plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) ///
				|| rspike min95 max95 model if parmseq==1 & trial==9 , lcolor(eltblue)  xlab(1/4) vertical xlab(,valuelabel angle(45)) ///
				 ytitle("Mean diff in GCSE Maths z-score") plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) title("Trial 9") ///
				 legend(off)					 
				 				 
				 
* crude complete case *
graph			tw  scatter estimate trial if parmseq==1 & model==1 , lcolor(eltblue)  yline(1, lc(gs10)) xlab(1/4) ylab(,valuelabel angle(0)) plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) ///
				|| rspike min95 max95 trial if parmseq==1 & model==1 , lcolor(eltblue)  xlab(1/4) vertical xlab(,valuelabel angle(45)) ///
				 ytitle("Mean diff in GCSE Maths z-score") plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) title("Crude Complete Case Analysis") ///
				 legend(off)

* adjusted complete case *
graph			tw  scatter estimate trial if parmseq==1 & model==2 , lcolor(eltblue)  yline(1, lc(gs10)) xlab(1/4) ylab(,valuelabel angle(0)) plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) ///
				|| rspike min95 max95 trial if parmseq==1 & model==2 , lcolor(eltblue)  xlab(1/4) vertical xlab(,valuelabel angle(45)) ///
				 ytitle("Mean diff in GCSE Maths z-score") plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) title("Adjusted Complete Case Analysis") ///
				 legend(off)

* crude MI *
graph			tw  scatter estimate trial if parmseq==1 & model==3 , lcolor(eltblue)  yline(1, lc(gs10)) xlab(1/4) ylab(,valuelabel angle(0)) plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) ///
				|| rspike min95 max95 trial if parmseq==1 & model==3 , lcolor(eltblue)  xlab(1/4) vertical xlab(,valuelabel angle(45)) ///
				 ytitle("Mean diff in GCSE Maths z-score") plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) title("Crude Multiple Imputation Analysis") ///
				 legend(off)
				 
* Adjusted MI *
graph			tw  scatter estimate trial if parmseq==1 & model==4 , lcolor(eltblue)  yline(1, lc(gs10)) xlab(1/4) ylab(,valuelabel angle(0)) plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) ///
				|| rspike min95 max95 trial if parmseq==1 & model==4 , lcolor(eltblue)  xlab(1/4) vertical xlab(,valuelabel angle(45)) ///
				 ytitle("Mean diff in GCSE Maths z-score") plotregion(fcolor(white)) graphregion(fcolor(white) lcolor(white)) title("Adjusted Multiple Imputation Analysis") ///
				 legend(off)
				 
				 
*CLOSE ANALYSIS*
log 	close


