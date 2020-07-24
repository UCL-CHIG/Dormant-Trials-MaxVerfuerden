/*******************************************************************************
purpose: 		Creates analysis dataset
				Creates figure 1 of protocol
				Performs multiple imputation for school outcomes 
date created: 	02/07/2019
last updated: 	04/05/2020 - add allocation variable
				05/05/2020 - use "mi passive:" to generate z-scores
				21/05/2020 - replaced birthyear with birthmonth because byr collinear with trial also made bayley scores conditional on trials that measured bayley score
				21/07/2020 - I realised I forgot to include gestational age and those who died in imputation model.
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

*LOAD DATASET*
// this is all randomised participants
use 			"S:\Head_or_Heart\max\archive\1-data\populationforfft_deidentified 2.dta", clear 

count if		d_dob==. // only 1 breastfed nucleotides and some from trial 1/2

* merge in birthcharacteristics 
merge 1:1 		studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\all\attributedataset_randomised.dta", keepusing(d_rand* sex bwt died gestage trial centre smokdur matage matedu byr *iq* iq_score)
drop			_merge
tab				trial group, m
replace			group=4 if group==. & (trial==3 | trial==4)
tab				trial group, m
tab				iq_score trial 
keep			studyid1 group iq* sex exp* bwt died gestage trial centre smokdur matage matedu byr d_dob 
tab 			byr trial, m
count if		d_dob==. // only 1 breastfed nucleotides 1 PDP and some from trial 1/2

* change order of trials so it matches with order in Thesis 	
tab 			trial 
recode 			trial (8=4) (7=8) (6=7) (5=6) (4=5), gen(trialdis) 
lab def			trialdis 1"OA" 2"OB" 3"PDP" 4"SGA" 5"DHA preterm" 6"DHA Term" 7"Nucleotides" 8"Iron" 9"Palmitate"
lab var			trialdis trialname
lab val			trialdis trialdis
tab 			trial trialdis
drop			trial
rename			trialdis trial
tab				died, nolab // 33
replace			died=0 if died !=1

********************************************************************************
*		 Merge in information on who was linked:							   *
********************************************************************************
merge 1:1 		studyid1 using "S:\Head_or_Heart\max\post-trial-extension\1-data\finalsampleandmainoutcomes.dta"

* flag those that linked:
generate		nolink=0
replace			nolink=1 if _merge==1
generate		linked=1 if _merge==3
replace			linked=0 if linked==.
tab				linked nolink, m
count			
drop			_merge

*** correct some wrong variables ***********************************************
rename 			centre temp
merge 			1:1 studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\importantvars.dta", keepusing(centre*) 
drop			if _merge==2
drop			_merge
replace			centre = 7 if studyid1=="PUF091"
replace			centre = 2 if studyid1 =="395"
replace			centre = 3 if studyid1 =="OI101"

replace			multiple = 0 if inlist(trial, 6,7,8,9) & multiple ==.
********************************************************************************

merge 			1:1 studyid1 using "S:\Head_or_Heart\max\old\GLOBAL7 (2).dta", keepusing(med)

********************************************************************************
* copy missing clinical information over for those who (legit) share the same pupilID *
********************************************************************************
count			if check==1  

foreach v of varlist bayley* d_dob bwt gestage matage smokdur iq_score died teen matedu {
generate		`v'_new = `v'
by pupilreference, sort : replace `v'_new = `v'[_n-1] if missing(`v') & check==1
by pupilreference, sort : replace `v'_new = `v'[_n+1] if missing(`v'_new) & check==1
}

foreach t of varlist bayley_MDI bayley_PDI bayley bwt gestage matage smokdur iq_score died teen matedu {
replace		`t' = `t'_new if !missing(`t'_new)
}

drop		*_new

* this also added an IQ score to a record of a child who participated in 2 trials one of which is iron (which didn't measure IQ within the trial) mark this iq score as missing (otherwise I get problems with the imputation)
replace			iq_score=-99 if !inlist(trial, 3,4,5,6)
replace			bayley_PDI=-99 if !inlist(trial, 3,4,5,6,8)
replace			bayley_MDI=-99 if !inlist(trial, 3,4,5,6,8)

cap drop		temp
rename			byr temp
generate		byr = year(d_dob)
tab				byr temp, m
drop			temp

*** generate a birthmonth variable
gen				bmth = month(d_dob)

********************************************************************************
*       Drop those outside the analysis sample (not needed for imputation) + tidy up
********************************************************************************
drop if			trial==10 | trial ==11
drop if 		trial==.
drop if			group==. 
drop 			if centre==.
drop 			if byr==. | byr==2003
drop 			if sex ==.
tab 			byr trial, m

* tidy up
sort			trial byr studyid1 group linked iq_score bayley* centre sex bwt gestage
order			trial byr studyid1 group linked iq_score bayley* centre sex bwt gestage
tab				iq_score trial, nolab
replace 		iq_score = later_iq_score if later_iq_score!=. & iq_score==.
replace 		iq_score=-99 if iq_score==. & trial !=3 & trial !=4 & trial !=5  & trial !=6


* does everything look as expected?
replace			d_randomisation = d_rand if d_rand !=. 
generate		year_randomised = year(d_randomisation)
replace 		year_randomised= byr if year_randomised==. & trial !=8
tab				year_randomised trial, m

keep			studyid1 exp* pupilref linked group* sex bwt year_randomised iq bayley gestage trial centre smokdur matage matedu W multiple agreementpattern iq_score gcse*score ks2_* passac5 year_* bayley_MDI bayley_PDI sen_ever apgar5m byr bmth check died age_* 

count			

********************************************************************************
* Flow diagram 
********************************************************************************
* All participants trial 3-9
tab				trial group, m // total=2613
tab				trial group if group!=4 & group !=3 & trial !=1 & trial !=2, m // total=2613
*** how many had a cognitive follow-up? (bayley score) ***
tab				trial group if bayley==1 & group!=4 & group !=3 & trial !=1 & trial !=2, m 
* how many were not planned to have bayley score measured?
tab				trial bayley if group!=4 , m // nucleotides 196 and palmitate 203
tab				trial group if (trial==7 | trial==9) & group!=4 // intervention: 202 control: 197
* who had a cognitive follow-up? (IQ score)
tab				iq_score trial if group!=4 & iq_score !=-99 // 236 in total
tab				trial group if iq_score!=. & iq_score!=-99 & group!=4 , m  // 118 int 118 contr
* how many were not planned to have IQ score measured?
tab				trial group if (trial!=4 & trial!=5 & trial !=6) & group!=4 // 476 int 643 contr
* how many were linked to the NPD?
tab				trial group2 if linked ==1 & group!=4 & group !=3 & trial !=1 & trial !=2, m // total= 1,742 
tab				trial linked  if group!=4, row
* how many were linked to Maths at age 16?
tab				trial group2 if gcse2210_score!=. & group!=4 & group !=3 & trial !=1 & trial !=2, m  // total= 1,742 
generate	 	linkedks4mat = 0
replace			linkedks4mat = 1 if gcse2210_score!=.
tab				trial linkedks4mat if group!=4 , row  
* how many were linked to Maths at age 11?
tab				trial group2 if ks2_mat_raw!=. & group!=4 , m // total= 1,742 
generate	 	linkedks2mat = 0
replace			linkedks2mat = 1 if ks2_mat_raw!=.
tab				trial linkedks2mat if group!=4 , row 

* drop unnecessary variables
drop			group_* W agreementpattern 


********************************************************************************
* save this dataset which is the analysis sample
********************************************************************************
compress
descr, 			full	// 3,379 observations and 46 variables
save			"S:\Head_or_Heart\max\post-trial-extension\1-data\samplingframe.dta", replace

* keep trial 1&2 and breasfeds and those who died in for the imputation (but delete afterwards)
tab				died
tab				trial
tab				group

********************************************************************************
* MULTIPLE IMPUTATION
********************************************************************************

/* which variables are missing? */
mdesc			_all

/* of the ones I want to impute whats the % missing? */	
mdesc 			matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple	
	
/* store imputed data in marginal long format*/ 											
mi set 			mlong 															

/* describe patterns of missingness and check how auxiliary variables perform (correlations)  */
mi misstable	summarize matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple		
mi misstable	patterns matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple		
pwcorr			matedu matage smokdur bwt gcse5* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple bmth sex group trial centre 	
												

/* register variables that need imputation */	
mi 				register imputed matedu matage smokdur ks2*raw passac5 bwt gcse5* gcse2* iq_score bayley_MDI bayley_PDI gestage sen_ever multiple
/* register variables that are complete */	
mi 				register regular bmth sex group trial centre 

* imputation

mi impute 		chained (logit) multiple smokdur passac5 sen_ever (ologit) matedu (pmm, knn(8)) bwt gestage matage ks2_mat_raw ks2_engread_raw ///
				ks2_engtot_raw gcse2210_score gcse5030_score  ///
				(regress, cond(trial==3 | trial==4 | trial==5 | trial==6)) iq_score ///
				(regress, cond(trial==3 | trial==4 | trial==5 | trial==6 | trial==8)) bayley_MDI bayley_PDI  ///
				= i.trial i.centre i.bmth i.sex i.group , ///
				add(15) augment rseed(300) burnin(30) chaindots 
				
				
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
mi 				describe

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
tabstat		gcse2210_score, by(trial) s(mean sd min max)
levelsof	trial, local(levels) 
foreach		l of local levels {
mi passive: egen		z_gcsemat_t`l' = std(gcse2210_score)  if trial == `l' 
tabstat		z_gcsemat_t`l',  s(mean p50 sd min max)
}


********************************
* z-score GCSE English lang:		
********************************
tabstat		gcse5030_score, by(trial) s(mean sd min max)
levelsof	trial, local(levels) 
foreach		l of local levels {
mi passive: egen z_gcseeng_t`l' = std(gcse5030_score) if trial == `l' 
tabstat		z_gcseeng_t`l',  s(mean sd min max)
}

*******************************
* z-score KS2 Mathematics:		
*******************************	
tabstat		ks2_mat_raw, by(trial) s(mean sd min max)
levelsof	trial, local(levels) 
foreach		l of local levels {
mi passive: egen		z_ks2mat_t`l' = std(ks2_mat_raw) if trial == `l' 
tabstat		z_ks2mat_t`l',  s(mean sd min max)
}

********************************
* z-score KS2 English lang:		
********************************
tabstat		ks2_engread_raw, by(trial) s(mean sd min max)
levelsof	trial, local(levels) 
foreach		l of local levels {
mi passive: egen		z_ks2eng_t`l' = std(ks2_engread_raw) if trial == `l'
tabstat		z_ks2eng_t`l',  s(mean sd min max)
}

* copy over:		
levelsof	trial, local(levels) 
foreach		l of local levels {
bysort 		pupilreference: egen mean_z_gcsemat_t`l' = mean(z_gcsemat_t`l')
bysort 		pupilreference: egen mean_z_gcseeng_t`l' = mean(z_gcseeng_t`l')
bysort 		pupilreference: egen mean_z_ks2mat_t`l' = mean(z_ks2mat_t`l')
bysort 		pupilreference: egen mean_z_ks2eng_t`l' = mean(z_ks2eng_t`l')
drop		z_gcsemat_t`l' z_gcseeng_t`l' z_ks2mat_t`l' z_ks2eng_t`l'
}
rename		mean_* * 


********************************************************************************
* save
********************************************************************************		
compress
descr, 			full	// 77 variables
save			"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_mainoutcomes.dta", replace
log close