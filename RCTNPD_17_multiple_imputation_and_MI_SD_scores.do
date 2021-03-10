capture 		log close
log 			using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\mi_edu_outcomes2$S_DATE.log", replace
*==============================================================================
*For:			PhD Thesis - Chapter 8
*Purpose: 		- Creates analysis dataset (samplingframe)		
*				- corrects some mistakes 
*				- Performs multiple imputation for school outcomes 
*date created: 	02/07/2019
*last updated: 	04/05/2020 - add allocation variable
*				05/05/2020 - use "mi passive:" to generate z-scores
*				21/05/2020 - replaced birthyear with birthmonth because byr collinear with trial also made bayley scores conditional on trials that measured bayley score
*				21/07/2020 - I realised I forgot to include gestational age and those who died in imputation model.
*				12/10/2020 - I realised I forgot to include total nr of follow-ups in imputation model
*				17/11/2020 - cleaned up code to have no empty lines and moved flow diagram to separate do-file
*				18/11/2020 - ommitted the step where I copy over and average the z-score for each pupilreference as that biased results (for those who participate in multiple trials!)
*				17/12/2020 - some deaths were wrong (copied over from twins) this is corrected now
*				19/12/2020 - exclude cows milk group from Iron standardisation
*				28/01/2020 - annotate who I excluded / included and why
*				05/03/2021 - make more readable
*author: 		maximiliane verfuerden
*==============================================================================
clear
cd 				"S:\Head_or_Heart\max\post-trial-extension"
qui do 			"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
timer      	 	clear
timer       	on 1
use 			"S:\Head_or_Heart\max\archive\1-data\populationforfft_deidentified 2.dta", clear
drop			fup_* fupb*
foreach 		var of varlist fup*{
replace			`var' =. if `var'==0
}
egen			fup_tot =rownonmiss(fup*)
* merge in birthcharacteristics 
********************************************************************************
merge 1:1 		studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\all\attributedataset_randomised.dta", keepusing(d_rand* sex died bwt gestage trial centre smokdur matage matedu byr *iq* iq_score)
drop			_merge
replace			group=4 if group==. & (trial==3 | trial==4)
keep			studyid1 group iq* sex exp* died bwt gestage trial centre smokdur matage matedu byr
* change order of trials so it matches with order in thesis 
********************************************************************************	
recode 			trial (8=4) (7=8) (6=7) (5=6) (4=5), gen(trialdis) 
lab def			trialdis 1"OA" 2"OB" 3"PDP" 4"SGA" 5"DHA preterm" 6"DHA Term" 7"Nucleotides" 8"Iron" 9"Palmitate"
lab var			trialdis trialname
lab val			trialdis trialdis
drop			trial
rename			trialdis trial
* merge in information on who was linked:
********************************************************************************
merge 1:1 		studyid1 using "S:\Head_or_Heart\max\post-trial-extension\1-data\finalsampleandmainoutcomes.dta"
replace			died=0 if died==1 & matchprobability>94 & matchprobability!=.
replace			died=0 if studyid1=="T070"
* flag those that linked:
********************************************************************************
generate		nolink=0
replace			nolink=1 if _merge==1
generate		linked=1 if _merge==3
replace			linked=0 if linked==.			
drop			_merge
merge 1:1 		studyid1 using	"S:\Head_or_Heart\max\archive\1-data\populationforfft_deidentified 2.dta", keepusing(fup* add*) 
drop			_merge
foreach 		var of varlist fup__*{
replace			`var' =. if `var'==0
}
egen			fup_tot2 =rownonmiss(fup__*)
replace			fup_tot = fup_tot2 if fup_tot==.
* save this dataset for the trajectory analysis
********************************************************************************
keep			studyid1 W *score* matchprob* *match* *first* *dob* *id* exp* pupilref linked group* sex bwt iq bayley bwt trial fup_tot centre smokdur matage matedu W gestage multiple agreementpattern iq_score gcse*score ks2_* passac5 year_* bayley_MDI bayley_PDI sen_ever apgar5m byr bmth check died age_* d_randomisation  later_iq_score byr
compress
descr, 			full	
save			"S:\Head_or_Heart\max\post-trial-extension\1-data\trajectory.dta", replace
* this also added an IQ score to a record of a child who participated in 2 trials one of which is iron (which didn't measure IQ within the trial) mark this iq score as missing (otherwise I get problems with the imputation)
replace			iq_score=-99 if !inlist(trial,3,4,5,6)
replace 		later_iq_score=-99 if !inlist(trial,5,6)
replace			bayley_PDI=-99 if !inlist(trial, 3,4,5,6,8)
replace			bayley_MDI=-99 if !inlist(trial, 3,4,5,6,8)
* tidy up
sort			trial byr studyid1 group linked iq_score bayley* centre sex bwt gestage
order			trial byr studyid1 group linked iq_score bayley* centre sex bwt gestage
keep			studyid1 W *score* *id* *match* *first* exp* pupilref linked group* sex bwt iq bayley bwt trial fup_tot centre smokdur matage matedu W gestage multiple agreementpattern *iq_score gcse*score ks2_* passac5 year_* bayley_MDI bayley_PDI sen_ever apgar5m byr bmth check died age_* 
* drop unnecessary variables:
drop			group_* agreementpattern 
generate		teen = 0
replace teen    =1 if matage <20
replace teen    =. if matage ==.
* save this dataset which is the analysis sample
********************************************************************************
compress
descr, 			full
save			"S:\Head_or_Heart\max\post-trial-extension\1-data\samplingframe.dta", replace
* do not keep trial 1&2 but keep breastfeds (delete breastfeds afterwards)
* keep those who did not link/ were implausible as they have no school outcomes (either never or purpusefully excluded from school link dofile) and their outcomes will be imputed and used in main analysis
drop			if trial==1 | trial==2
replace			died =0 if died !=1
********************************************************************************
* MULTIPLE IMPUTATION
********************************************************************************
/* which variables are missing? */
mdesc			_all
/* of the ones I want to impute whats the % missing? */	
mdesc 			matedu matage smokdur ks2*raw passac5 bwt gcse5030_score gcse2210_score iq_score bayley_MDI bayley_PDI gestage sen_ever multiple 
bysort 			trial: mdesc 			matedu matage smokdur ks2*raw passac5 bwt gcse5030_score gcse2210_score iq_score bayley_MDI bayley_PDI gestage sen_ever multiple 
/* store imputed data in marginal long format*/ 											
mi set 			mlong 															
/* describe patterns of missingness and check how auxiliary variables perform (correlations)  */
mi misstable	summarize matedu matage smokdur ks2*raw passac5 bwt gcse5030_score gcse2210_score iq_score bayley_MDI bayley_PDI gestage sen_ever multiple		
mi misstable	patterns matedu matage smokdur ks2*raw passac5 bwt gcse5030_score gcse2210_score iq_score bayley_MDI bayley_PDI gestage sen_ever multiple		
pwcorr			matedu matage smokdur bwt gcse2210_score gcse5030_score iq_score bayley_MDI bayley_PDI gestage sen_ever multiple bmth sex group trial centre 				
/* register variables that need imputation */	
mi 				register imputed matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple
/* register variables that are complete */	
mi 				register regular bmth sex group trial centre fup_tot 
* imputation
mi impute 		chained (logit) multiple smokdur passac5 sen_ever (ologit) matedu (pmm, knn(8)) bwt gestage matage ks2_mat_raw ks2_engread_raw ks2_engtot_raw gcse2210_score gcse5030_score  ///
				(regress, cond(trial==3 | trial==4 | trial==5 | trial==6)) iq_score ///
				(regress, cond(trial==3 | trial==4 | trial==5 | trial==6 | trial==8)) bayley_MDI bayley_PDI  ///
				= i.trial i.centre i.bmth i.sex i.group i.fup_tot, ///
				add(15) augment rseed(300) burnin(30) chaindots		
/* 				cond= conditional: only impute iq in those trials that measured it 
				(need to be non missing in all other trials for this to work so replaced it with -99) 
				pmm= predictive mean matching using 8 nearest neighbours (knn(8))*/				
********************************************************************************				
* drop observations that were only needed for the imputation: 
********************************************************************************	
save	"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_fresh.dta", replace
mi 					describe
use		"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_fresh.dta", clear
mi 					describe
mi convert			wide
mi 					describe
tab 				trial group
replace				iq_score=. if !inlist(trial,3,4,5,6)
replace 			later_iq_score=. if !inlist(trial,5,6)
replace				bayley_PDI=. if !inlist(trial, 3,4,5,6,8)
replace				bayley_MDI=. if !inlist(trial, 3,4,5,6,8)
* drop those who died
drop				if died==1
* drop breastfeds and cow's milk ones to not skew z-scores
drop 				if group==4 | group==3				
********************************************************************************
* check how imputation went: 
********************************************************************************
mi 					describe
graph				box gcse5030_score if trial !=7, over(_mi_m)
graph				box gcse2210_score if trial !=7, over(_mi_m)
graph				box ks2_mat_raw, over(_mi_m) 
graph				box ks2_engtot_raw, over(_mi_m) 			
graph				box iq_score if trial==3 |  trial==5 | trial==6, over(_mi_m)
graph				box bayley_MDI if trial==3 | trial==4 | trial==5 | trial==6 | trial==8, over(_mi_m)				
********************************************************************************
* compute z-scores:
********************************************************************************
* z-score GCSE Mathematics:		
mi passive: 		egen	meanmaths16raw = rowmean(*gcse2210_score) 
tabstat				meanmaths16raw, by(trial) s(mean sd min max)
levelsof			trial, local(levels) 
foreach				l of local levels {
mi passive: 		egen		z_gcsemat_t`l' = std(meanmaths16raw)  if trial == `l' 
tabstat				z_gcsemat_t`l' if trial == `l', s(mean sd) by(group) format(%5.2f)
}
* z-score GCSE Maths compared to the national sample
mi passive:	 		gen	z_gcsemat_nat = (gcse2210_score - 4.913)/ 1.8138
tabstat				z_gcsemat_nat, by(trial) s(mean sd min max) format(%5.4f)
* z-score GCSE English lang:	
mi passive: 		egen	meanenglish16raw = rowmean(*gcse5030_score) 
levelsof			trial, local(levels) 
foreach				l of local levels {
mi passive: 		egen z_gcseeng_t`l' = std(meanenglish16raw) if trial == `l' 
tabstat				meanenglish16raw if trial == `l', s(mean sd) by(group) format(%5.2f)
tabstat				z_gcseeng_t`l' if trial == `l', s(mean sd) by(group) format(%5.2f)
}
* z-score KS2 Mathematics:	
mi passive: 		egen	meanmaths11raw = rowmean(*ks2_mat_raw) 	
levelsof			trial, local(levels) 
foreach				l of local levels {
mi passive: 		egen		z_ks2mat_t`l' = std(meanmaths11raw) if trial == `l' 
tabstat				meanmaths11raw if trial == `l', s(mean sd) by(group) format(%5.2f)
tabstat				z_ks2mat_t`l' if trial == `l', s(mean sd) by(group) format(%5.2f)
}
* z-score KS2 English lang:		
mi passive: 		egen	meanenglish11raw = rowmean(*ks2_engread_raw) 	
levelsof			trial, local(levels) 
foreach				l of local levels {
mi passive: 		egen		z_ks2eng_t`l' = std(meanenglish11raw) if trial == `l' 
tabstat				meanenglish11raw if trial == `l', s(mean sd) by(group) format(%5.2f)
tabstat				z_ks2eng_t`l' if trial == `l', s(mean sd) by(group) format(%5.2f)
}
* z-score Bayley_MDI	
mi passive: 		egen	meanbmdiraw = rowmean(*bayley_MDI) 	
levelsof			trial, local(levels) 
foreach				l of local levels {
mi passive: 		egen	z_bmdi_t`l' = std(meanbmdiraw) if trial == `l' 
tabstat				meanbmdiraw if trial == `l', s(mean sd) by(group) format(%5.2f)
tabstat				z_bmdi_t`l' if trial == `l', s(mean sd) by(group) format(%5.2f)
}
* z-score IQ
mi passive: 		egen	meaniqraw = rowmean(*iq_score) 	
levelsof			trial, local(levels) 
foreach				l of local levels {
mi passive: 		egen	z_iq_t`l' = std(meaniqraw) if trial == `l' 
tabstat				meaniqraw if trial == `l', s(mean sd) by(group) format(%5.2f)
tabstat				z_iq_t`l' if trial == `l', s(mean sd) by(group) format(%5.2f)
}	
* z-score 2nd IQ
mi passive: 		egen	mean2ndiqraw = rowmean(*later_iq_score) 	
levelsof			trial, local(levels) 
foreach				l of local levels {
mi passive: 		egen	z_2ndiq_t`l' = std(mean2ndiqraw) if trial == `l' 
tabstat				mean2ndiqraw if trial == `l', s(mean sd) by(group) format(%5.2f)
tabstat				z_2ndiq_t`l' if trial == `l', s(mean sd) by(group) format(%5.2f)
}				
*===============================================================================		
compress
descr, 			    full	
save			    "S:\Head_or_Heart\max\post-trial-extension\1-data\mi_mainoutcomes2.dta", replace
*===============================================================================
timer				off 1
timer 				list 1
display as input	"time of do-file in minutes:" r(t1) / 60
timer 				clear 
log 				close
