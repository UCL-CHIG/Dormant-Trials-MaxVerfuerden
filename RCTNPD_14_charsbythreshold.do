/*==============================================================================
purpose:    characteristics by weight threshold
date 
created: 		17/06/2019
last updated: 	28/08/2019
			28/04/2020 - added missing chars for rand2 in iron
LAST RUN:	27/04/2020
			29/04/2020
			18/12/2020 
author: 	maximiliane verfuerden
===============================================================================*/
clear
cd 			"S:\Head_or_Heart\max\post-trial-extension"
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
cap qui		do "S:\Head_or_Heart\max\attributes\7-ado\dropmiss.ado"
cap	qui		do "S:\Head_or_Heart\max\attributes\7-ado\renvars.ado"
cap qui 	do	"S:\Head_or_Heart\max\post-trial-extension\00-ado\groups.ado"
capture 	log close
log 		using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\04.3-ev_charsbythreshold$S_DATE.log", replace
use			"${datadir}\m_and_u_probs_weights.dta", clear					
********************************************************************************
** first check that the characteristics are recorded properly for each trial 
********************************************************************************
tab			trial multiple, m
tab 		trial matedu, m 
tab 		trial smokdur, m 
tabstat     bwt, s(mean min max count) by(trial)
tabstat     gestage, s(mean min max count) by(trial)
tabstat     birthyear, s(mean min max count) by(trial)
* update twin status 
********************************************************************************
replace		multiple = 0 if multiple==.
* update other variables by trial:
********************************************************************************
foreach 	var of varlist fup*{
replace		`var' =. if `var'==0
}
egen		fup_tot =rownonmiss(fup*)
generate	teen=0
generate	apgargrp5m=.
*** iron
*******************
merge 		m:1 studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\iron\iron_clean.dta", keepusing(mumage_iron mumcig_iron)
drop if		_merge ==2 // don't want to reintroduce already excluded participants
drop		_merge
//teen
replace		teen =1 if trial==7 & mumage_iron <20
replace		teen =0 if trial==7 & mumage_iron >19 & mumage_iron !=.
//maternal smoking
replace		smokdur =0 if mumcig_iron==0
replace		smokdur =1 if mumcig_iron>0 & mumcig_iron !=.
*** sga
*******************
merge 		m:1 studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\sga_term\sga_term all clinical clean.dta", keepusing(mumage_sgaterm apg5*)
drop if		_merge ==2
drop		_merge
//teen
replace		teen =1 if trial==8 & mumage_sgaterm <20
replace		teen =0 if trial==8 & mumage_sgaterm >19 & mumage_sgaterm !=.
//apgar
replace		apgargrp5m =1 if trial==8 & apg5_sgaterm <8
replace		apgargrp5m =2 if trial==8 & apg5_sgaterm >7 & apg5_sgaterm !=.
*** palmitate has quite a few missing, merge them in 
*********************************************************
merge 		m:1 studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\palmitate aka betapol\palmitate clinical_clean.dta", keepusing(dobmum_palm bwt_palm gest_palm mumquals_palm msmk* )
drop if		_merge ==2
drop		_merge
//maternal education
recode		mumquals_palm 5=3 2/4=2 1=1
replace		matedu = mumquals_palm if mumquals_palm !=. 
//maternal smoking
replace		smokdur =0 if msmk3mth_palm==0 & msmk6mth_palm==0
replace		smokdur =1 if (msmk3mth_palm>0 | msmk6mth_palm>0) & !missing(msmk3mth_palm, msmk6mth_palm)
//bwt
replace		bwt =bwt_palm if trial==9 & bwt_palm !=.
//gestage
replace		gestage =gest_palm if trial==9 & gest_palm !=.
*** term lcpufa ***
*******************
merge 		m:1 studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\lcpufa_term\LCPUFA_term clinical vision 6y_clean.dta", keepusing(mumage_lcterm apg5* mumcig*)
drop if		_merge ==2
drop		_merge
//maternal smoking
replace		smokdur =0 if mumcig1_lcterm==0 & mumcig2_lcterm==0
replace		smokdur =1 if (mumcig1_lcterm>0 | mumcig2_lcterm>0) & !missing(mumcig1_lcterm, mumcig2_lcterm) 
//teen
replace		teen =1 if trial==5 & mumage_lcterm <20
replace		teen =0 if trial==5 & mumage_lcterm >19 & mumage_lcterm !=.
//apgar
replace		apgargrp5m =1 if trial==5 & apg5_lcterm<8
replace		apgargrp5m =2 if trial==5 & apg5_lcterm>7 & apg5_lcterm!=.
*** preterm lcpufa 
*******************
merge 		m:1 studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\lcpufa_preterm\LCPUFA_preterm clinical to 18m_clean.dta", keepusing(mumage_lcpre apgar5m_lcpre cigsmum* med*)
drop if		_merge ==2
drop		_merge
//maternal education
tab			matedu
tab			med_lcpre matedu, m
recode		med_lcpre 5=3 2/4=2 1=1
tab			med_lcpre matedu, m
replace		matedu = med_lcpre if med_lcpre !=. 
tab 		trial matedu, m
//teen
replace		teen =1 if trial==4 & mumage_lcpre <20
replace		teen =0 if trial==4 & mumage_lcpre >19 & mumage_lcpre !=.
//apgar
replace		apgargrp5m =1 if trial==4 & apgar5m_lcpre<8
replace		apgargrp5m =2 if trial==4 & apgar5m_lcpre>7 & apgar5m_lcpre!=.
//maternal smoking
replace		teen =1 if trial==9 & mumage_palm <20
replace		teen =0 if trial==9 & mumage_palm >19 & mumage_palm!=.
replace		smokdur =0 if cigsmum_lcpre==1
replace		smokdur =1 if cigsmum_lcpre==2
*** nucleotides
*******************
merge 		m:1 studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\nucleotides\nucleotides clinical_clean.dta", keepusing(motdob* motedu* apgar5* smkl* smk3* alcl* alc6*)
drop if		_merge ==2
drop		_merge
//apgar
replace		apgargrp5m =1 if trial==6 & apgar5_nuc<8
replace		apgargrp5m =2 if trial==6 & apgar5_nuc>7 & apgar5_nuc!=.
//maternal education
replace		matedu =. if  moteduc_nuc<1
replace		matedu =1 if  moteduc_nuc==1 
replace		matedu =2 if (moteduc_nuc>1 & moteduc_nuc<5)
replace		matedu =3 if (moteduc_nuc>4 & moteduc_nuc!=.)
tab			matedu moteduc_nuc, m nolab
//maternal smoking
replace		smokdur =0 if (smk3mth_nuc==0) & (smklast6_nuc==0)
replace		smokdur =1 if (smk3mth_nuc>0 & smk3mth_nuc<.) | (smklast6_nuc>0 & smklast6_nuc<.)
tab			trial smokdur, m
//maternal alcohol
replace		alcdur =0 if (alclast_nuc==0) & (alc6mth_nuc==0)
replace		alcdur =1 if (alclast_nuc>0 & alclast_nuc<.) | (alc6mth_nuc>0 & alc6mth_nuc<.)
*** merge unmatched back in
********************************************************************************
merge 		m:1 studyid1 using  "S:\Head_or_Heart\max\archive\1-data\populationforfft_deidentified 2.dta", update  
drop		_merge 
replace		unmatched =1 if pupilreference==.
*** flag those with low prob
********************************************************************************
generate	total_unmatched_at_step2 = unmatched
replace		total_unmatched_at_step2 =1 if matchprobability<25
replace		total_unmatched_at_step2 =1 if matchprobability==25 & dbscore==200do
generate	total_unmatched_at_step3 = total_unmatched_at_step2
replace		total_unmatched_at_step3 =1 if W<9
generate	total_unmatched_at_step4 = total_unmatched_at_step3
replace		total_unmatched_at_step4 =0 if matchprob >84 & dbscore !=200
*** cross check for completeness and validity 
********************************************************************************
tab			trial multiple, m
tab			trial died, m
tab			trial centre, m
tab			trial teen, m 
tab			trial RCTsex, m 
tab 		trial matedu, m 
tab 		trial apgargrp5m, m 
tab 		trial smokdur, m nolab
tab 		trial alcdur, m nolab
tabstat 	gestage, m s(mean min max sd count) by(trial) format(%9.1g)
tabstat 	bwt, m s(mean min max sd count) by(trial) format(%9.1g)
tabstat 	bayley_MDI, m s(mean min max sd count) by(trial) format(%9.1g)
tabstat 	bayley_PDI, m s(mean min max sd count) by(trial) format(%9.1g)
tabstat 	fup_tot, m s(mean min max sd count) by(trial) format(%9.1g)
tabstat 	address_tot, m s(mean min max sd count) by(trial) format(%9.1g)
********************************************************************************
** generate threshold variables (these are based on histogram but subjective)
********************************************************************************
gen			matchcons =  0
replace		matchcons = 1 if W>15 & W!=. 
lab var		matchcons "conservative threshold (w 15+)"
gen			matchlen =  0
replace		matchlen = 1 if W>8 & W!=. 
lab var		matchlen "lenient threshold (w 9+)"
gen			lowmatch =  0
replace		lowmatch = 1 if W<9 
lab var		lowmatch "match weight below 9"
*===============================================================================
save		"${datadir}\weightsandcharacteristics.dta", replace
log			close 