/*==============================================================================
purpose load in the data from csv files
date created: 19/12/2018
author: maximiliane verfuerden
*==============================================================================*/
clear
cd 			"S:\Head_or_Heart\max\post-trial-extension"
qui do 		"S:\Head_or_Heart\max\post-trial-extension\2-do\00-global.do"
capture 	log close
log 		using "${logdir}\01-cl_loaddata $S_DATE.log", replace 
*** "all data" ***
import      delimited S:\Head_or_Heart\max\post-trial-extension\1-data\GtOrmondStOutputs2\GtOrmondStAllData.csv, clear
by          pupilreference, sort: gen unique = _n==1
save 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldata.dta", replace
clear
*** "all data subj" ***
import 		delimited S:\Head_or_Heart\max\post-trial-extension\1-data\GtOrmondStOutputs2\GtOrmondStAllDataSubj.csv, clear
by          pupilreference, sort: gen unique = _n==1
save 		"S:\Head_or_Heart\max\post-trial-extension\1-data\alldatasubj.dta", replace
clear
*** "link table" ***
import 		delimited S:\Head_or_Heart\max\post-trial-extension\1-data\GtOrmondStOutputs2\GtOrmondStLinkTable.csv, clear 
by          pupilreference, sort: gen unique_pref = _n==1
by       	studyid1, sort: gen unique_studyid1 = _n==1
save 		"S:\Head_or_Heart\max\post-trial-extension\1-data\linktable.dta", replace
clear
*** "score lookup" ***
import 		delimited S:\Head_or_Heart\max\post-trial-extension\1-data\GtOrmondStOutputs2\GtOrmondStScoreLookup.csv, clear
//			3 vars, 29 obs
//			this seems to be just a reference table - better opened in excel as the fields contain long descriptions
save 		"S:\Head_or_Heart\max\post-trial-extension\1-data\scorelookup.dta", replace
clear
*** "specification" ***
import delimited S:\Head_or_Heart\max\post-trial-extension\1-data\GtOrmondStOutputs2\GtOrmondStSpecification.csv, varnames(1) clear 
//			this seems to be just a reference table - also better opened in excel as the fields contain long descriptions
*==============================================================================*/
save 		"S:\Head_or_Heart\max\post-trial-extension\1-data\specification.dta", replace
clear
cap log 	close