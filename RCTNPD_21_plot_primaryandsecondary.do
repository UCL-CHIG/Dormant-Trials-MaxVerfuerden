capture 			log close
log 				using  "S:\Head_or_Heart\max\post-trial-extension\4-logs\plotprimaryandsecondary$S_DATE.log", replace
/*==============================================================================
purpose:			Put primary analyses and secondary analyses in a plot 
date created:		11/11/2020
last updated: 		18/11/2020
last run:	 		18/11/2020
					23/11/2020
					04/02/2021
author: 			maximiliane verfuerden
using:				MI data and CC data
===============================================================================*/
clear	
cd 					"S:\Head_or_Heart\max\post-trial-extension"
qui do 				"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
timer      	 		clear
timer       		on 1
use					"S:\Head_or_Heart\max\post-trial-extension\1-data\mi_mainoutcomes2.dta", clear
drop if				trial==7
tab 				trial group 
tab 				died
*PRIMARY OUTCOME z-score of GCSE Maths exam at age 16 years (P)
*******************************************************************************
levelsof			trial, local(levels)  
foreach				l of local levels {
cap qui 			mi estimate: regress z_gcsemat_t`l' ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', vce(robust)
estimates 			store P`l'
}
cap qui 			mi estimate: regress z_gcsemat_t`l' ib2.group i.sex bwt gestage i.smokdur i.matedu if trial==9, vce(robust)
estimates 			store P9
* SECONDARY OUTCOME z-score of GCSE English exam at age 16 years (Sec1)
*******************************************************************************
levelsof			trial, local(levels)  
foreach				l of local levels {
cap qui 			mi estimate: regress z_gcseeng_t`l' ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', vce(robust)
estimates 			store Sec1`l'
}
cap qui 			mi estimate: regress z_gcseeng_t`l' ib2.group i.sex bwt gestage i.smokdur i.matedu if trial==9, vce(robust) 
estimates 			store Sec19
* SECONDARY OUTCOME z-score of Key Stage 2 Maths exam at age 11 years (Sec2)
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
cap qui 			mi estimate: regress z_ks2mat_t`l' ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l', vce(robust)
estimates 			store Sec2`l'
}
cap qui 			mi estimate: regress z_ks2mat_t`l' ib2.group i.sex bwt gestage i.smokdur i.matedu if trial==9,  vce(robust) 
estimates 			store Sec29
* SECONDARY OUTCOME z-score of Key Stage 2 English exam at age 11 years (Sec3)
*******************************************************************************
levelsof			trial, local(levels) 
foreach				l of local levels {
cap qui 			mi estimate: regress z_ks2eng_t`l' ib2.group i.sex bwt gestage i.centre i.smokdur i.matedu if trial==`l',  vce (robust)	
estimates 			store Sec3`l'
}
cap qui 			mi estimate: regress z_ks2eng_t`l' ib2.group i.sex bwt gestage i.smokdur i.matedu if trial==9,  vce(robust) 	
estimates 			store Sec39
*plots
*******************************************************************************
#delimit ;
coefplot 
(P3, label(Maths age 16)mcolor(edkblue) msymbol(D) ciopts(lcolor(edkblue))) (Sec13, label(English age 16)mcolor(edkblue) msymbol(O) ciopts(lcolor(edkblue))) (Sec23, label(Maths age 11) mcolor(edkblue) msymbol(Dh)  ciopts(lcolor(edkblue))) (Sec33, label(English age 11) mcolor(edkblue) msymbol(oh)  ciopts(lcolor(edkblue))) 
(P4, label(Maths age 16)mcolor(gray) msymbol(D) ciopts(lcolor(gray))) (Sec14, label(English age 16)mcolor(gray) msymbol(O) ciopts(lcolor(gray))) (Sec24, label(Maths age 11) mcolor(gray) msymbol(Dh) ciopts(lcolor(gray))) (Sec34, label(English age 11)mcolor(gray) msymbol(oh) ciopts(lcolor(gray))) 
(P5, label(Maths age 16) mcolor(dknavy) msymbol(D) ciopts(lcolor(dknavy))) (Sec15, label(English age 16) mcolor(dknavy) msymbol(O) ciopts(lcolor(dknavy))) (Sec25, label(Maths age 11) msymbol(Dh) mcolor(dknavy) ciopts(lcolor(dknavy))) (Sec35, label(English age 11) mcolor(dknavy) msymbol(oh) ciopts(lcolor(dknavy))) 
(P6, label(Maths age 16) mcolor(ebblue) msymbol(D) ciopts(lcolor(ebblue))) (Sec16, label(English age 16) mcolor(ebblue) msymbol(O) ciopts(lcolor(ebblue)))  (Sec26, label(Maths age 11) mcolor(ebblue) msymbol(Dh) ciopts(lcolor(ebblue))) (Sec36, label(English age 11) mcolor(ebblue) msymbol(oh) ciopts(lcolor(ebblue))) 
(P8, label(Maths age 16)mcolor(black) msymbol(D) ciopts(lcolor(black))) (Sec18, label(English age 16)mcolor(black) msymbol(O) ciopts(lcolor(black)))  (Sec28, label(Maths age 11) mcolor(black) msymbol(Dh) ciopts(lcolor(black))) (Sec38, label(English age 11) mcolor(black) msymbol(oh) ciopts(lcolor(black))) 
(P9, label(Maths age 16) mcolor(dknavy) msymbol(D) ciopts(lcolor(dknavy))) (Sec19, label(English age 16)mcolor(dknavy) msymbol(O) ciopts(lcolor(dknavy))) (Sec29, label(Maths age 11) mcolor(dknavy) msymbol(Dh) ciopts(lcolor(dknavy))) (Sec39, label(English age 11)mcolor(dknavy) msymbol(oh) ciopts(lcolor(dknavy)))    
,  coeflabels(1.group=" ", notick labgap(2)) keep(1.group) vertical yline(0, lcolor(gray) lwidth(thin) lpattern(dash)) scheme(s1mono) legend(off) ylab(-0.7(0.1)0.4,grid angle(horizontal) format(%03.2f)) ytitle("SD score difference modified vs standard (lower=poorer grades in modifed)")
;
*===============================================================================
timer				off 1
timer 				list 1
display as input	"time of do-file in minutes:" r(t1) / 60
timer 				clear 
log 				close