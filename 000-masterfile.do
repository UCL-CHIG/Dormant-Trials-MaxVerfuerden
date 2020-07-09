/*******************************************************************************
purpose: 		calls all do-files that, together, create the final analysis dataset
				
date created: 	28/05/2019
last updated: 	14/08/2019
				07/07/2020 : added more explanation
				
author: 		maximiliane verfuerden
*******************************************************************************/

*HOUSEKEEPING*
clear
*	change working directory
cd 			"S:\Head_or_Heart\max\post-trial-extension"
*	set up folder pathways (i.e. where datasets / do-files are stored)
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
*	make sure all downloaded commands can run:
cap qui		do "S:\Head_or_Heart\max\attributes\7-ado\dropmiss.ado"
cap	qui		do "S:\Head_or_Heart\max\attributes\7-ado\renvars.ado"
cap qui 	do	"S:\Head_or_Heart\max\post-trial-extension\00-ado\groups.ado"

* 	how long does this all take?
timer       clear
timer       on 1

********************************************************************************
* STEP 1:	MERGE ALL PUPIL CANDIDATES TO TRIAL PARTICIPANTS (BY TRIAL)		   
********************************************************************************
// for each trial: merge together info about the participant with the possible pupils they linked to (from FFT "linktable" dataset)
// here I also check how many pupils each participant links to. 	
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ev_linkage_trial_1.do" // Nutrient enriched formula preterm 1982-85 (Trial 1&2)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ev_linkage_trial_3.do" // Nutrient enriched formula preterm post discharge 1993-96 (Trial 3)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ev_linkage_trial_4.do" // Nutrient enriched formula SGA 1993-96 (Trial 4)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ev_linkage_trial_5.do" // LCPUFA formula preterm  1993-96 (Trial 5)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ev_linkage_trial_6.do" // LCPUFA formula term  1993-95 (Trial 6)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ev_linkage_trial_7.do" // Nucleotides formula term  2000-01 (Trial 7)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ev_linkage_trial_8.do" // Iron formula term  1993-94 (Trial 8)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ev_linkage_trial_9.do" // Sn-2 palmitate formula term  1995-96 (Trial 9)
* 	COMBINE FILES:   
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ev_linkage_alltrials.do" 
// creates: "S:\Head_or_Heart\max\post-trial-extension\1-data\04.1-ev_linkage_alltrials.dta"

********************************************************************************
* STEP 2: 	PLAUSIBILITY CHECK 1 & CALCULATE M AND U PROBABILITIES	AND MATCH WEIGHTS	   			  
********************************************************************************
// uses:	"S:\Head_or_Heart\max\post-trial-extension\1-data\04.1-ev_linkage_alltrials.dta" (from step 1)
//			"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta" // (NPD dataset)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\m_and_u_probs.do"
// creates: "S:\Head_or_Heart\max\post-trial-extension\1-data\m_and_u_probs_weights.dta"

********************************************************************************
* STEP 3: 	CHARACTERISTICS BY MATCHWEIGHT THRESHOLD
********************************************************************************
// uses:	"S:\Head_or_Heart\max\post-trial-extension\1-data\m_and_u_probs_weights.dta" (from step 2)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ev_charsbythreshold.do"
// creates: "S:\Head_or_Heart\max\post-trial-extension\1-data\weightsandcharacteristics.dta"

********************************************************************************
* STEP 4: 	PLAUSIBILITY CHECK 2 & SELECT THE ANALYSIS SAMPLE (2,982 unique particiants)	 		   
********************************************************************************
// uses:	"S:\Head_or_Heart\max\post-trial-extension\1-data\weightsandcharacteristics.dta" (from step 3)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\cr_matches15andabove.do"
// creates: "S:\Head_or_Heart\max\post-trial-extension\1-data\matches15andup_non_dup.dta"
 
********************************************************************************
* STEP 5:	ADD EDUCATIONAL OUTCOMES (2,589 unique participants) 				   
********************************************************************************
// uses:	"S:\Head_or_Heart\max\post-trial-extension\1-data\matches15andup_non_dup.dta" (from step 4)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\cr_addoutcomes.do"
// creates: "S:\Head_or_Heart\max\post-trial-extension\1-data\finalsampleandmainoutcomes.dta"

********************************************************************************
* STEP 6:	PERFORM MULTIPLE IMPUTATION 				   
********************************************************************************
// uses: 	"S:\Head_or_Heart\max\post-trial-extension\1-data\finalsampleandmainoutcomes.dta" (from step 5)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\mi_edu_outcomes.do"
// creates: "S:\Head_or_Heart\max\post-trial-extension\1-data\mi_mainoutcomes.dta"

********************************************************************************
* PRIMARY ANALYSIS				   
********************************************************************************
// uses: 	"S:\Head_or_Heart\max\post-trial-extension\1-data\samplingframe.dta" (from step 6)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ch6_primary analysis.do"

********************************************************************************
* SECONDARY ANALYSIS				   
********************************************************************************
// uses: 	"S:\Head_or_Heart\max\post-trial-extension\1-data\samplingframe.dta" (from step 6)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ch6_secondary analysis.do"

********************************************************************************
* EXTREME CASE ANALYSIS				   
********************************************************************************
// uses: 	"S:\Head_or_Heart\max\post-trial-extension\1-data\samplingframe.dta" (from step 6)
do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\ch6_extremecase.do"

* 	how long did it take?
timer 		list 1