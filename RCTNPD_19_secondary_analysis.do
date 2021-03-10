capture 			log close
log 				using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\secondaryoutcomes$S_DATE.log", replace
/*==============================================================================
purpose:			Secondary analyses for my PhD
date created:		01/02/2020
last updated: 		21/05/2020 - unblinded
					06/11/2020 - excluded nucleotide and palmitate trial and cleaned the code so its easier to follow
last run:	 		06/11/2020
					14/11/2020 - mi has changed
					20/11/2020 - z-scores have changed 
					25/11/2020
					19/11/2020 - the plausibility check contained a variable that wrongly flagged some children as dead or implausible to link and not others. This lead to the incorrect exclusion and inclusion of a handful of children (<5 per trial). This was discovered when cross-checking the death records. The variable is now corrected and extra checks were put in place. I also standardised iron only using low iron and high iron not cows milk because we decided that this would not be comparable and although randomised, cow's milk group was presumably not blinded.
author: 			maximiliane verfuerden
My secondary outcomes are:
- Mean GCSE English Exam scores (z-scores standardised to trial sample)
- Mean KS2 Maths Exam scores (z-scores standardised to trial sample)
- Mean KS2 English Exam scores (z-scores standardised to trial sample)
- Probability of receiving 5+ GCSE Grades A* to C
- Probability of receiving special educational needs support
===============================================================================*/
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
*******************************************************************************
* 					using MI data
*******************************************************************************
use					"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_mainoutcomes2.dta", clear
* recode iron trial so that cow's milk is in second group and other formula in third group
recode				group (1=1) (2=3) (3=2) if trial==8
tab 				trial group 
* verify that the z-scores have a mean of 0 and an SD of 1
levelsof			trial, local(levels) 
foreach				l of local levels {
tabstat				z_gcseeng_t`l' if trial == `l', s(mean sd) by(group) format(%5.4f)
}
levelsof			trial, local(levels)  
foreach				l of local levels {
tabstat				z_ks2mat_t`l' if trial == `l', s(mean sd) by(group) format(%5.4f)
}
levelsof			trial, local(levels) 
foreach				l of local levels {
tabstat				z_ks2eng_t`l' if trial == `l', s(mean sd) by(group) format(%5.4f)
}
* SECONDARY OUTCOME z-score of GCSE English exam at age 16 years:
*******************************************************************************
levelsof			trial, local(levels)  
foreach				l of local levels {
display as input	"*** GCSE English, MI adjusted (trial `l')"
cap noisily 		mi estimate: regress z_gcseeng_t`l' ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l' & trial !=9, vce(robust)
mimrgns				i.group	
}
display as input	"*** GCSE English, MI adjusted (trial 9)"
mi estimate: 		regress z_gcseeng_t9 ib2.group i.sex bwt gestage i.smokdur i.matedu if trial==9, vce(robust) 
mimrgns				i.group	
* SECONDARY OUTCOME z-score of Key Stage 2 Maths exam at age 11 years:
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"*** age 11 Maths exam, MI adjusted (trial `l')" 
cap noisily 		mi estimate: regress z_ks2mat_t`l' ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', vce(robust)
mimrgns				i.group	
}
display as input	"*** age 11 Maths exam, MI adjusted (trial 9)"
mi estimate: 		regress z_ks2mat_t9 ib2.group i.sex bwt gestage i.smokdur i.matedu if trial==9, vce(robust) 
mimrgns				i.group	
* SECONDARY OUTCOME z-score of Key Stage 2 English exam at age 11 years:
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"*** age 11 English exam, MI adjusted (trial `l')"
cap noisily 		mi estimate: regress z_ks2eng_t`l' ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', vce (robust)	
mimrgns				i.group	
}
display as input	"*** age 11 English exam, MI adjusted (trial 9)"
mi estimate: 		regress z_ks2eng_t9 ib2.group i.sex bwt gestage i.smokdur i.matedu if trial==9, vce(robust) 
mimrgns				i.group		
* SECONDARY OUTCOME Probability of receiving 5+ GCSE Grades A* to C:
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"*** min 5 GCSEs A*-C, MI adjusted (trial `l')"
mi estimate, or: 	logit passac5 ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', vce(robust) 
}
display as input	"*** min 5 GCSEs A*-C, MI adjusted (trial 9)"
mi estimate, or: 	logit passac5 ib2.group i.sex bwt gestage i.smokdur i.matedu if trial==9, base vce(robust) 
* SECONDARY OUTCOME Probability of ever receiving SEN support: 
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"*** SEN, MI adjusted (trial `l')"
mi estimate, or: 	logit sen_ever ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', vce(robust) 
}
display as input	"*** SEN, MI adjusted (trial 9)"
mi estimate, or: 	logit sen_ever ib2.group i.sex bwt gestage i.smokdur i.matedu if trial==9, vce(robust) 
* Export the results into tables in a word document called "secondaryoutomes":
*******************************************************************************
* for all trials but the iron trial:
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"GCSE English, MI adjusted (trial `l')"
cap noisily			eststo: mi estimate, post: regress	z_gcseeng_t`l' ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', base vce(robust)
cap noisily			esttab using 5-documents\secondaryoutcomes`time_string'.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': GCSE English z-score, MI adjusted robust SEs}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 				clear
display as input	"KS2 Maths, MI adjusted (trial `l')"
cap noisily			eststo: mi estimate, post: regress z_ks2mat_t`l' ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu  if trial==`l' , base vce(robust)
cap noisily			esttab 	using 5-documents\secondaryoutcomes`time_string'.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': KS2 Maths score, MI adjusted robust SEs}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 				clear
display as input	"KS2 English, MI adjusted (trial `l')"
cap noisily			eststo: mi estimate, post: regress z_ks2eng_t`l' ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', base vce(robust)	
cap noisily			esttab 	using 5-documents\secondaryoutcomes`time_string'.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': KS2 English, MI adjusted robust SEs}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 				clear
display as input	"GCSE A*-C, MI adjusted (trial `l')"
eststo: 			mi estimate, post : logistic passac5 ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l' , base vce(robust) 
esttab 				using 5-documents\secondaryoutcomes`time_string'.rtf, noconstant append label r2 wide eform b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': Odds Ratio 5+ GCSE grades A* to C, MI adjusted robust SEs}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 				clear
display as input	"SEN ever, MI adjusted (trial `l')"
cap noisily			eststo: mi estimate, post: logistic sen_ever ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l' , base vce(robust)
cap noisily			esttab using 5-documents\secondaryoutcomes`time_string'.rtf, noconstant append label r2 wide eform b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': Odds Ratio receiving SEN support, MI adjusted robust SEs}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME") 
eststo 			clear
}			 
*===============================================================================
timer					off 1
timer 					list 1
display as input		"time of do-file in minutes:" r(t1) / 60
timer 					clear 
log 					close