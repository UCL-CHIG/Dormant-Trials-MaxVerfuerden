/*******************************************************************************
purpose: 		Performs multiple imputation interactions  
date created: 	14/07/2020
last updated: 	21/07/2020
author: 		maximiliane verfuerden
*******************************************************************************/


*HOUSEKEEPING*
clear
*	change working directory
cd 				"S:\Head_or_Heart\max\post-trial-extension"
*	set up folder pathways (i.e. where datasets / do-files are stored)
qui do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
*	set log 
capture 		log close
log 			using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\mi_edu_outcomes$S_DATE.log", replace


	
********************************************************************************
* MULTIPLE IMPUTATION SMOKDUR INTERACTION
********************************************************************************
*LOAD DATASET*
// this is all randomised participants
use 			"S:\Head_or_Heart\max\post-trial-extension\1-data\samplingframe.dta", clear 
count

/* which variables are missing? */
mdesc			_all

/* of the ones I want to impute whats the % missing? */	
mdesc 			matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple	
	
/* store imputed data in long format*/ 											
mi set 			mlong 															

/* describe patterns of missingness */
mi misstable	summarize matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple		
mi misstable	patterns matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple		
pwcorr			matedu matage smokdur bwt gcse5* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple bmth sex group trial centre 	


/* register variables that need imputation */	
mi 				register imputed matedu matage gcse5030_score smokdur ks2*raw passac5 bwt gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple
/* register variables that are complete */	
mi 				register regular bmth sex group trial centre 

* imputation
mi impute 		chained (logit, include((gcse5030_score*group))) smokdur (logit) multiple passac5 sen_ever (ologit) matedu (pmm, knn(8) include((smokdur*group))) gcse5030_score (pmm, knn(8)) bwt gestage matage ks2_mat_raw ks2_engread_raw ks2_engtot_raw gcse2210_score  ///
				(regress, cond(trial==3 | trial==4 | trial==5 | trial==6)) iq_score ///
				(regress, cond(trial==3 | trial==4 | trial==5 | trial==6 | trial==8)) bayley_MDI bayley_PDI  ///
				= i.trial i.centre i.bmth i.sex i.group, add(15) augment rseed(300) burnin(30) chaindots  
				
				
/* 				cond= conditional: only impute iq in those trials that measured it 
				(need to be non missing in all others for this to work so replaced it with -99) 
				will replace it with missing again after the imputation 
				pmm= predictive mean matching using ten nearest neighbours (knn(10))*/

********************************************************************************
* drop observations that were only needed for the imputation: 
********************************************************************************	
replace 		iq_score=. if iq_score== -99

* drop those who died
drop			if died==1
* drop those from trial 1&2
drop if			trial==1 | trial==2 
* drop breastfeds to not skew z-scores
drop 			if group==4



********************************************************************************
* check how imputation went: 
********************************************************************************
misstable		summarize matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple	, gen(no_)

graph			box gcse5030_score, over(_mi_m)
graph			box gcse2210_score, over(_mi_m)
graph			box ks2_mat_raw, over(_mi_m) 
graph			box ks2_engtot_raw, over(_mi_m) 			
graph			box iq_score, over(_mi_m) 
graph			box bayley_MDI, over(_mi_m)
graph			box bayley_PDI, over(_mi_m) 

*******************************
* z-score GCSE Mathematics:		
*******************************
tabstat			gcse2210_score, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
mi passive: 	egen z_gcsemat_t`l' = std(gcse2210_score)  if trial == `l' 
tabstat			z_gcsemat_t`l',  s(mean p50 sd min max)
}


* copy over:		
levelsof	trial, local(levels) 
foreach		l of local levels {
bysort 		pupilreference: egen mean_z_gcsemat_t`l' = mean(z_gcsemat_t`l')
drop		z_gcsemat_t`l' 
}
rename		mean_* * 
egen		z_gcsemat = rowmean(z_gcsemat_t*)
drop		z_gcsemat_t*
mi register	passive z_gcsemat


********************************************************************************
* save SMOKDUR
********************************************************************************		
* don't need these anymore:
drop			no_*

compress
descr, 			full	// 65 variables
save			"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_interaction_smokdur.dta", replace



********************************************************************************
* MULTIPLE IMPUTATION BWT INTERACTION
********************************************************************************
*LOAD DATASET*
// this is all randomised participants
use 			"S:\Head_or_Heart\max\post-trial-extension\1-data\samplingframe.dta", clear 
count

* keep trial 1&2 and breasfeds and those who died in for the imputation (but delete afterwards)
tab				died
tab				trial
tab				group

/* which variables are missing? */
mdesc			_all

/* of the ones I want to impute whats the % missing? */	
mdesc 			matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple		
/* store imputed data in long format*/ 											
mi set 			mlong 															


/* describe patterns of missingness */
mi misstable	summarize matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple		
mi misstable	patterns matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple		
pwcorr			matedu matage smokdur bwt gcse5* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple bmth sex group trial centre 	


/* register variables that need imputation */	
mi 				register imputed matedu matage gcse5030_score smokdur ks2*raw passac5 bwt  gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple
/* register variables that are complete */	
mi 				register regular bmth sex group trial centre 

* imputation
mi impute 		chained (logit) smokdur multiple passac5 sen_ever (ologit) matedu (pmm, knn(8) include((bwt*group))) gcse5030_score (pmm, knn(8) include((gcse5030_score*group))) bwt (pmm, knn(8)) gestage matage ks2_mat_raw ks2_engread_raw ks2_engtot_raw gcse2210_score  ///
				(regress, cond(trial==3 | trial==4 | trial==5 | trial==6)) iq_score ///
				(regress, cond(trial==3 | trial==4 | trial==5 | trial==6 | trial==8)) bayley_MDI bayley_PDI  ///
				= i.trial i.centre i.bmth i.sex i.group, add(15) augment rseed(300) burnin(30) chaindots  
				
				
/* 				cond= conditional: only impute iq in those trials that measured it 
				(need to be non missing in all others for this to work so replaced it with -99) 
				will replace it with missing again after the imputation 
				pmm= predictive mean matching using ten nearest neighbours (knn(10))*/

********************************************************************************
* drop observations that were just needed for the imputation: 
********************************************************************************	
replace 		iq_score=. if iq_score== -99

* drop those who died
drop			if died==1
* drop those from trial 1&2
drop if			trial==1 | trial==2 
* drop breastfeds to not skew z-scores
drop 			if group==4
	

********************************************************************************
* check how imputation went: 
********************************************************************************
misstable		summarize matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple	, gen(no_)

graph			box gcse5030_score, over(_mi_m)
graph			box gcse2210_score, over(_mi_m)
graph			box ks2_mat_raw, over(_mi_m) 
graph			box ks2_engtot_raw, over(_mi_m) 			
graph			box iq_score, over(_mi_m) 
graph			box bayley_MDI, over(_mi_m)
graph			box bayley_PDI, over(_mi_m) 


*******************************
* z-score GCSE Mathematics:		
*******************************
tabstat			gcse2210_score, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
mi passive: 	egen z_gcsemat_t`l' = std(gcse2210_score)  if trial == `l' 
tabstat			z_gcsemat_t`l',  s(mean p50 sd min max)
}


* copy over:		
levelsof	trial, local(levels) 
foreach		l of local levels {
bysort 		pupilreference: egen mean_z_gcsemat_t`l' = mean(z_gcsemat_t`l')
drop		z_gcsemat_t`l' 
}
rename		mean_* * 
egen		z_gcsemat = rowmean(z_gcsemat_t*)
drop		z_gcsemat_t*
mi register	passive z_gcsemat


********************************************************************************
* save BWT
********************************************************************************		
* don't need these anymore:
drop			no_*

compress
descr, 			full	// 65 variables
save			"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_interaction_bwt.dta", replace





********************************************************************************
* MULTIPLE IMPUTATION SEX INTERACTION
********************************************************************************
*LOAD DATASET*
// this is all randomised participants
use 			"S:\Head_or_Heart\max\post-trial-extension\1-data\samplingframe.dta", clear 
count

* keep trial 1&2 and breasfeds and those who died in for the imputation (but delete afterwards)
tab				died
tab				trial
tab				group

/* which variables are missing? */
mdesc			_all

/* of the ones I want to impute whats the % missing? */	
mdesc 			matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple		
/* store imputed data in long format*/ 											
mi set 			mlong 															


/* describe patterns of missingness */
mi misstable	summarize matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple		
mi misstable	patterns matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple		
pwcorr			matedu matage smokdur bwt gcse5* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple bmth sex group trial centre 	


/* register variables that need imputation */	
mi 				register imputed matedu matage gcse5030_score smokdur ks2*raw passac5 bwt  gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple
/* register variables that are complete */	
mi 				register regular bmth sex group trial centre 

* imputation
mi impute 		chained  (logit) smokdur multiple passac5 sen_ever (ologit) matedu (pmm, knn(8) include((sex*group))) gcse5030_score (pmm, knn(8)) bwt gestage matage ks2_mat_raw ks2_engread_raw ks2_engtot_raw gcse2210_score  ///
				(regress, cond(trial==3 | trial==4 | trial==5 | trial==6)) iq_score ///
				(regress, cond(trial==3 | trial==4 | trial==5 | trial==6 | trial==8)) bayley_MDI bayley_PDI  ///
				= i.trial i.centre i.bmth i.sex i.group, add(15) augment rseed(300) burnin(30) chaindots 
				
				
/* 				cond= conditional: only impute iq in those trials that measured it 
				(need to be non missing in all others for this to work so replaced it with -99) 
				will replace it with missing again after the imputation 
				pmm= predictive mean matching using ten nearest neighbours (knn(10))*/

********************************************************************************
* drop observations that were just needed for the imputation: 
********************************************************************************	
replace 		iq_score=. if iq_score== -99

* drop those who died
drop			if died==1
* drop those from trial 1&2
drop if			trial==1 | trial==2 
* drop breastfeds to not skew z-scores
drop 			if group==4
	

********************************************************************************
* check how imputation went: 
********************************************************************************
misstable		summarize matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple	, gen(no_)

graph			box gcse5030_score, over(_mi_m)
graph			box gcse2210_score, over(_mi_m)
graph			box ks2_mat_raw, over(_mi_m) 
graph			box ks2_engtot_raw, over(_mi_m) 			
graph			box iq_score, over(_mi_m) 
graph			box bayley_MDI, over(_mi_m)
graph			box bayley_PDI, over(_mi_m) 


*******************************
* z-score GCSE Mathematics:		
*******************************
tabstat			gcse2210_score, by(trial) s(mean sd min max)
levelsof		trial, local(levels) 
foreach			l of local levels {
mi passive: 	egen z_gcsemat_t`l' = std(gcse2210_score)  if trial == `l' 
tabstat			z_gcsemat_t`l',  s(mean p50 sd min max)
}


* copy over:		
levelsof	trial, local(levels) 
foreach		l of local levels {
bysort 		pupilreference: egen mean_z_gcsemat_t`l' = mean(z_gcsemat_t`l')
drop		z_gcsemat_t`l' 
}
rename		mean_* * 
egen		z_gcsemat = rowmean(z_gcsemat_t*)
drop		z_gcsemat_t*
mi register	passive z_gcsemat


********************************************************************************
* save sex
********************************************************************************		
* don't need these anymore:
drop			no_*

compress
descr, 			full	// 65 variables
save			"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_interaction_sex.dta", replace






log close