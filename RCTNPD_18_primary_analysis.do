capture 			log close
log 				using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\primary analysis$S_DATE.log", replace
/*==============================================================================
purpose:		Code to run primary analysis for my PhD 
date 
created: 		31/01/2020
last updated: 	01/02/2020
				21/05/2020 - unblinded
				23/05/2020 - replaced birthyear with birthmonth because byr collinear with trial
				21/07/2020 - I realised I forgot to include gestational age in the imputation model
				06/11/2020 - excluded nucleotide and palmitate trial and cleaned the code so its easier to follow
				18/11/2020 - I used a command that combined individual z-scores from each mi dataset leading z-scores not having a mean of 0 and sd of 1 							I only realised this when I plotted the margins and they were all asymmetric. The solution was to combine the raw outcomes using rubins rules and then calculate the z-scores on them as if it was 1 dataset. I preserved the uncertainty by using the command mi passive before combining the results.
				19/12/2020 - the plausibility check contained a variable that wrongly flagged some children as dead or implausible to link and not others. This lead to the incorrect exclusion and inclusion of a handful of children (<5 per trial). This was discovered when cross-checking the death records. The variable is now corrected and extra checks were put in place. I also standardised iron only using low iron and high iron not cows milk because we decided that this would not be comparable and although randomised, cow's milk group was presumably not blinded.
				06/03/2021 - made code more readable for upload on github
last run:	 	01/02/2020
				27/04/2020
				21/05/2020
				22/06/2020
				25/06/2020
				20/10/2020
				06/11/2020
				11/11/2020
				14/11/2020
				19/11/2020
				19/12/2020
author: 		maximiliane verfuerden
a note on model assumptions:
heteroskedasticity and normality of residuals as well as model fit were checked on observed data. I ran MI diagnostics to check MI model fit.
Some trials showed heteroskedasticity - this does not bias estimates but can bias standard errors. In the analyses below I use robust standard errors (vce(robust)) to overcome that.
dropping unmatched / implausible matches: 
dropping them is only necessary in the complete case analysis as the unmatched and implausible ones here have imputed outcomes modelled on the relationship observed in confident matches.
The unmatched never matched to school outcomes in the first place and the implausible were excluded from the step where school outcomes were added. So there is no risk that I have accidentally included the wrong outcomes for them.
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
use					"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_mainoutcomes2.dta", clear
* exclude those that were only necessary for the imputation
drop if				died==1
drop if				trial ==1 | trial ==2 
* PRIMARY OUTCOME z-score of GCSE Maths exam at age 16 years:
*******************************************************************************
levelsof			trial, local(levels)  
foreach				l of local levels {
display as input	"GCSE Maths, MI adjusted (trial `l')"
cap noisily 		mi estimate: regress z_gcsemat_t`l' ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', base vce(robust)
cap noisily 		mimrgns	i.group	
}
display as input	"GCSE Maths, MI adjusted (trial 9)" // trial 9 is separate because it doesn't have multiple centres (i.e., not adjusted for i.centre)
cap noisily 		mi estimate: regress z_gcsemat_t9 ib2.group i.sex bwt gestage i.smokdur i.matedu if trial==9, base vce(robust)
cap noisily 		mimrgns	i.group	
* Export the results into tables in a word document called "primaryoutcomes":
* for all trials but the iron trial:
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"GCSE Maths, MI adjusted (trial `l')"
eststo 				clear
cap noisily			eststo: mi estimate, post: regress	z_gcsemat_t`l' ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', base vce(robust)
cap noisily			esttab using 5-documents\primaryoutcomes`time_string'.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': GCSE Maths z-score, MI adjusted robust SEs}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 				clear
}
* PRIMARY OUTCOME z-score of GCSE Maths exam at age 16 years using national SD:
*******************************************************************************
levelsof			trial, local(levels)  
foreach				l of local levels {
display as input	"GCSE Maths, MI adjusted national SD (trial `l')"
cap noisily 		mi estimate: regress z_gcsemat_nat ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', base vce(robust)
cap noisily 		mimrgns	i.group	
}
display as input	"GCSE Maths, MI adjusted national SD (trial 9)"
cap noisily 		mi estimate: regress z_gcsemat_nat ib2.group i.sex bwt gestage i.smokdur i.matedu if trial==9, base vce(robust)
cap noisily 		mimrgns	i.group	
* Export the results into tables in a word document called "primaryoutcomes":
* for all trials but the iron trial:
levelsof			trial, local(levels) 
foreach				l of local levels {
display as input	"GCSE Maths, MI adjusted (trial `l')"
eststo 				clear
cap noisily			eststo: mi estimate, post: regress	z_gcsemat_nat ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', base vce(robust)
cap noisily			esttab using 5-documents\primaryoutcomes`time_string'.rtf, noconstant append label r2 wide b(2) ci(2) alignment(l) nonumbers nobase nomtitles title("{\b Trial `l': GCSE Maths z-score, MI adjusted robust SEs using national SD}") fonttbl(\f0\fnil Times New Roman;\f1\fnil Arial;) addnote("Table produced by Stata on $S_DATE at $S_TIME")
eststo 				clear
}	 
*===============================================================================
timer				off 1
timer 				list 1
display as input	"time of do-file in minutes:" r(t1) / 60
timer 				clear 
log 				close