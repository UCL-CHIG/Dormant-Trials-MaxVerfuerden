/*******************************************************************************
purpose:		Code for exploratory analyses 
date 
created: 		16/06/2020
last updated: 	17/07/2020 - Bianca de Stavola helped and we added mi test (which is a wald test) instead of lrtest
last run:	 	18/07/2020
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
log 			using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\ch6_exploratory$S_DATE.log", replace


********************************************************************************
********************************************************************************
*				- MI DATA -							 			   
********************************************************************************
********************************************************************************


********************************************************************************
*				Smoking status during pregnancy interaction				 	       
********************************************************************************
*LOAD DATASET*
use				"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_interaction_smokdur.dta", clear

*DESCRIBE DATASET*
tab 			trial group if _mi_m==0, m  // no breastfed ones
* drop participants that were too young for GCSE in the NPD
drop if			((age_ks4 <15 & age_ks4 >16) | age_ks4==. ) & trial==7
tab 			trial group if _mi_m==0, m  //  1,727 kids (09 May 2020)

* so the plots display this correctly *
lab dir
cap lab drop	smoking
lab def 		smoking 0"did not smoke" 1"smoked"
lab	val			smokdur smoking


/*I want to know the mean difference between intervention and control group in those children who's mother smoked during pregnancy and those children who's mother did not smoke during pregnancy. This loop gives me the results for each trial and also performs a wald interaction test. Note that the effect in the absence is the same as the coefficient in the model*/
levelsof		trial, local(levels) 
foreach			l of local levels {
preserve		
keep if			trial==`l' 
display 		as input "effect in the absence of maternal smoking in trial `l': "
display 		as input _dup(59) "_"
mi estimate 	(_b[1.group#0.smokdur]), dots: regress z_gcsemat ib2.group#i.smokdur i.sex bwt gestage i.centre i.matedu, allbaselevels 
display 		as input _dup(59) "_"
display 		as input "effect in the presence of maternal smoking in trial `l': "
display 		as input _dup(59) "_"
mi estimate 	(_b[1.group#1.smokdur]), dots: regress z_gcsemat ib2.group#ib1.smokdur i.sex bwt gestage i.centre i.matedu 
mimrgns			ib2.group#ib0.smokdur,  cmdmargins
marginsplot, 	title("Trial `l': Effect of intervention formula on maths at age 16 by smoking status during pregnancy", size(small)) ytitle("maths z-score at age 16",size(small)) legend(rows(1)) xlabel(1 "int" 2"contr")
graph export	"S:\Head_or_Heart\max\post-trial-extension\3-graphs\Trial `l' smoking interaction.png", replace
quietly 		mi estimate: regress	z_gcsemat ib2.group#i.smokdur i.sex bwt gestage i.centre  i.matedu 
display 		as input _dup(59) "_"
display 		as input "wald interaction test (smoking) in trial `l': "
display 		as input _dup(59) "_"
mi test			1.group#1.smokdur 
display 		as input _dup(59) "_"
restore		
}


// for trial 9 (no centre): 
preserve		
keep if			trial==9
display 		as input "effect in the absence of maternal smoking in trial 9: "
display 		as input _dup(59) "_"
mi estimate 	(_b[1.group#0.smokdur]), dots: regress z_gcsemat ib2.group#i.smokdur i.sex bwt gestage i.matedu, allbaselevels 
display 		as input _dup(59) "_"
display 		as input "effect in the presence of maternal smoking in trial 9: "
display 		as input _dup(59) "_"
mi estimate 	(_b[1.group#1.smokdur]), dots: regress z_gcsemat ib2.group#ib1.smokdur i.sex bwt gestage i.matedu 
mimrgns			ib2.group#ib0.smokdur,  cmdmargins
marginsplot, 	title("Trial 9: Effect of intervention formula on maths at age 16 by smoking status during pregnancy", size(small)) ytitle("maths z-score at age 16",size(small)) legend(rows(1)) xlabel(1 "int" 2"contr")
graph export	"S:\Head_or_Heart\max\post-trial-extension\3-graphs\Trial 9 smoking interaction.png", replace
quietly 		mi estimate: regress	z_gcsemat ib2.group#i.smokdur i.sex bwt gestage i.matedu 
display 		as input _dup(59) "_"
display 		as input "wald interaction test (smoking) in trial 9: "
display 		as input _dup(59) "_"
mi test			1.group#1.smokdur 
display 		as input _dup(59) "_"
restore		
	



********************************************************************************
*				Birthweight interaction								 	       
********************************************************************************
*LOAD DATASET*
use				"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_interaction_bwt.dta", clear

*DESCRIBE DATASET*
tab 			trial group if _mi_m==0, m  // no breastfed ones
* drop participants that were too young for GCSE in the NPD
drop if			((age_ks4 <15 & age_ks4 >16) | age_ks4==. ) & trial==7
tab 			trial group if _mi_m==0, m  //  1,727 kids (09 May 2020)


// birthweight goes from 630 to 5400

/*I want to know whether the effect of the intervention formula on the mean difference between intervention and control group differs by birthweight. This loop gives me the results for each trial and also performs a wald interaction test.*/


// for low bwt trials: 
levelsof		trial, local(levels) 
foreach			k in 3 5 {
preserve		
keep if			trial==`k' 
quietly 		mi estimate: regress z_gcsemat ib2.group#c.bwt i.sex i.smokdur gestage i.centre i.matedu 
mimrgns			i.group, at(bwt=(500(500)2000)) cmdmargins
marginsplot, 	recast(line) title("Trial `k': Effect of intervention formula on maths at age 16 by birtweight", size(small)) ytitle("maths z-score at age 16",size(small)) legend(off) addplot(scatter z_gcsemat bwt, mcolor(gs12) below) xlabel(500(500)2000)
graph export	"S:\Head_or_Heart\max\post-trial-extension\3-graphs\Trial `k' bwt interaction.png", replace
quietly 		mi estimate: regress z_gcsemat ib2.group#c.bwt i.sex i.smokdur bwt gestage i.centre i.matedu 
display 		as input _dup(59) "_"
display 		as input "wald interaction test (bwt) in trial `k': "
display 		as input _dup(59) "_"
mi test			1.group#c.bwt 
display 		as input _dup(59) "_"
restore		
}

// for those small for gestational age: 
preserve		
keep if			trial==4
quietly 		mi estimate: regress z_gcsemat ib2.group#c.bwt i.sex i.smokdur gestage i.centre i.matedu 
mimrgns			i.group, at(bwt==(1200(100)3200)) cmdmargins
marginsplot, 	recast(line) title("Trial 4: Effect of intervention formula on maths at age 16 by birtweight", size(small)) ytitle("maths z-score at age 16",size(small)) legend(off)  addplot(scatter z_gcsemat bwt, mcolor(gs12) below) xlabel(1200(100)3200)
graph export	"S:\Head_or_Heart\max\post-trial-extension\3-graphs\Trial 4 bwt interaction.png", replace
quietly 		mi estimate: regress z_gcsemat ib2.group#c.bwt i.sex i.smokdur bwt gestage i.centre i.matedu 
display 		as input _dup(59) "_"
display 		as input "wald interaction test (bwt) in trial 4: "
display 		as input _dup(59) "_"
mi test			1.group#c.bwt 
display 		as input _dup(59) "_"
restore		


// for normal bwt trials: 
levelsof		trial, local(levels) 
foreach			l in 6 7 8  {
preserve		
keep if			trial==`l' 
quietly 		mi estimate: regress z_gcsemat ib2.group#c.bwt i.sex i.smokdur gestage i.centre i.matedu 
mimrgns			i.group, at(bwt==(2000(1000)5000)) cmdmargins
marginsplot, 	recast(line) title("Trial `l': Effect of intervention formula on maths at age 16 by birtweight", size(small)) ytitle("maths z-score at age 16",size(small)) legend(off)  addplot(scatter z_gcsemat bwt, mcolor(gs12) below) xlabel(2000(1000)5000)
graph export	"S:\Head_or_Heart\max\post-trial-extension\3-graphs\Trial `l' bwt interaction.png", replace
quietly 		mi estimate: regress z_gcsemat ib2.group#c.bwt i.sex i.smokdur bwt gestage i.centre i.matedu 
display 		as input _dup(59) "_"
display 		as input "wald interaction test (bwt) in trial `l': "
display 		as input _dup(59) "_"
mi test			1.group#c.bwt 
display 		as input _dup(59) "_"
restore		
}

// for trial 9 (no centre): 
preserve		
keep if			trial==9
quietly 		mi estimate: regress z_gcsemat ib2.group#c.bwt i.sex i.smokdur gestage i.matedu 
mimrgns			i.group, at(bwt==(2000(1000)5000)) cmdmargins
marginsplot, 	recast(line) title("Trial 9: Effect of intervention formula on maths at age 16 by birtweight", size(small)) ytitle("maths z-score at age 16",size(small)) legend(off)  addplot(scatter z_gcsemat bwt, mcolor(gs12) below) xlabel(2000(500)4000)
graph export	"S:\Head_or_Heart\max\post-trial-extension\3-graphs\Trial 9 bwt interaction.png", replace
quietly 		mi estimate: regress z_gcsemat ib2.group#c.bwt i.sex i.smokdur bwt gestage i.centre i.matedu 
display 		as input _dup(59) "_"
display 		as input "wald interaction test (bwt) in trial 9: "
display 		as input _dup(59) "_"
mi test			1.group#c.bwt 
display 		as input _dup(59) "_"
restore		



********************************************************************************
*				Boy or girl interaction								 	       
********************************************************************************
*LOAD DATASET*
use				"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_interaction_sex.dta", clear

*DESCRIBE DATASET*
tab 			trial group if _mi_m==0, m  // no breastfed ones
* drop participants that were too young for GCSE in the NPD
drop if			((age_ks4 <15 & age_ks4 >16) | age_ks4==. ) & trial==7
tab 			trial group if _mi_m==0, m  //  1,727 kids (09 May 2020)


/*I want to know the mean difference between intervention and control group in those children who's mother smoked during pregnancy and those children who's mother did not smoke during pregnancy. This loop gives me the results for each trial and also performs a wald interaction test. Note that the effect in the absence is the same as the coefficient in the model*/
levelsof		trial, local(levels) 
foreach			l of local levels {
preserve		
keep if			trial==`l' 
display 		as input "effect in males in trial `l': "
display 		as input _dup(59) "_"
mi estimate 	(_b[1.group#1.sex]), dots: regress z_gcsemat ib2.group#i.sex i.smokdur bwt gestage i.centre i.matedu, allbaselevels 
display 		as input _dup(59) "_"
display 		as input "effect in females in trial `l': "
display 		as input _dup(59) "_"
mi estimate 	(_b[1.group#2.sex]), dots: regress z_gcsemat ib2.group#ib2.sex i.smokdur  bwt gestage i.centre i.matedu 
mimrgns			ib2.group#ib1.sex,  cmdmargins
marginsplot, 	title("Trial `l': Effect of intervention formula on maths at age 16 by sex", size(small)) ytitle("maths z-score at age 16",size(small)) legend(rows(1)) xlabel(1 "int" 2"contr")
graph export	"S:\Head_or_Heart\max\post-trial-extension\3-graphs\Trial `l' sex interaction.png", replace	
quietly 		mi estimate: regress	z_gcsemat ib2.group#i.sex i.smokdur bwt gestage i.centre  i.matedu if trial==`l'
display 		as input _dup(59) "_"
display 		as input "wald interaction test (sex) trial `l': "
display 		as input _dup(59) "_"
mi test			1.group#1.sex
display 		as input _dup(59) "_"
restore		
}

preserve
keep if trial==9
mi estimate 	(_b[1.group#2.sex]), dots: regress z_gcsemat ib2.group#ib2.sex i.smokdur  bwt gestage  i.matedu 
mimrgns			ib2.group#ib1.sex,  cmdmargins
marginsplot, 	title("Trial 9: Effect of intervention formula on maths at age 16 by sex", size(small)) ytitle("maths z-score at age 16",size(small)) legend(rows(1)) xlabel(1 "int" 2"contr")
graph export	"S:\Head_or_Heart\max\post-trial-extension\3-graphs\Trial 9 sex interaction.png", replace	
restore

*CLOSE ANALYSIS*
log 	close
