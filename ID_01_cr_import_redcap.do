/*******************************************************************************
Project: 	head or heart
Purpose: 	tracks progress of archiving
Author: 	Max Verfuerden
Created:	08.03.2017
*******************************************************************************/
*step 1: set filepaths, start log
********************************************************************************
qui do 		"S:\Head_or_Heart\max\attributes\2-Cleaning\00-global.do"
cd 			"S:\Head_or_Heart\max\archive"
cap log 	close
log using 	"${logdir}\cr_import_redcap_$S_DATE.log", replace 
local				c_date = c(current_date)
display				"`c_date'"
local				time_string = subinstr("`c_date'",":","_",.)
local				time_string = subinstr("`time_string'"," ","_",.)
display				"`time_string'"
*step 2: import redcap data 
********************************************************************************
// a) export the "stata" file from redcap which consists of a csv file and a do-file. 
// b) download them to to "S:\Head_or_Heart\max\redcap"
// c) run the stata do file by opening it in this stata project (as opposed to a separate stata window)
*step 3: come back to this do-file (cr_import_redcap), and run commands below to format the imported data
********************************************************************************
* create one trial variable from the redcap data
gen trial =.
replace trial =1 	if trialcam==1 | trialips==1 | trialkin==1 // OA
replace trial =2 	if trialshe==9 | trialnor==9 | trialcam==12 | trialoab==12 // OB
replace trial =3 	if trialcam==2 | trialnot==2 | trialhinch==2 | trialnor==2 |  triallei==2 | trialips==2 // PDP
replace trial =4 	if trialnot==5 | triallei==5 // LCPUFA preterm
replace trial =5 	if trialnot==6 | triallei==6 // LCPUFA term
replace trial =6 	if trialnot==8 | triallei==8 // Nuc
replace trial =7 	if trialnot==7 | trialnor==7 | triallei==7 // Iron
replace trial =8 	if trialcam==3 | trialnot==3 | triallei==3 // SGA term
replace trial =9 	if trialcam==4  // Palmitate term
replace trial =10 	if trialglas==10 // LCPUFA Preterm (Glasgow)
replace trial =11 	if trialglas==11 // SGA term(Glasgow)
lab def	trial 1"OA" 2"OB" 3"PDP" 4"LCPUFA pret" 5"LCPUFA term" 6"NUC" 7"Iron" 8"SGA" 9"PAL" 10"LCPUFA Glas" 11"SGA Glas" 
lab	val	trial trial
tab trial
* generate a label for follow-up
lab def	fup1 1"recr." 0"."
lab val	fup___1 fup1
lab def	fup2 1"12w" 0"."
lab val	fup___2 fup2
lab def	fup3 1"20w" 0"."
lab val	fup___3 fup3
lab def	fup4 1"9m" 0"."
lab val	fup___4 fup4
lab def	fup5 1"18m" 0"."
lab val	fup___5 fup5
lab def	fup6 1"5-6y" 0"."
lab val	fup___6 fup6
lab def	fup7 1"7-9y" 0"."
lab val	fup___7 fup7
lab def	fup8 1"10-14y" 0"."
lab val	fup___8 fup8
lab def	fup9 1"15y" 0"."
lab val	fup___9 fup9
lab def	fup10 1"16-19y" 0"."
lab val	fup___10 fup10
lab def	fup11 1"20-24y" 0"."
lab val	fup___11 fup11
lab def	fup12 1"25+y" 0"."
lab val	fup___12 fup12
lab def	fup13 1"6w" 0"."
lab val	fup___13 fup13
lab def	fup14 1"15m" 0"."
lab val	fup___14 fup14
lab def	fup15 1"6m" 0"."
lab val	fup___15 fup15
lab def	fup16 1"rand." 0"."
lab val	fup___16 fup16
lab def	fup17 1"12m" 0"."
lab val	fup___17 fup17
lab def	fup18 1"26w" 0"."
lab val	fup___18 fup18
lab def	fup19 1"3w" 0"."
lab val	fup___19 fup19
lab def	fup20 1"8w" 0"."
lab val	fup___20 fup20
lab def	fup21 1"16w" 0"."
lab val	fup___21 fup21
lab def	fup22 1"18w" 0"."
lab val	fup___22 fup22
* just saw that fup___15 and fup___18 both measure around 6 months, will put them into one
replace fup___15=1 if fup___18==1
drop	fup___18**************************************************************************** 
******************************************************************************** 
save "S:\Head_or_Heart\max\archive\1-data\ID_database`time_string'", replace 
******************************************************************************** 
******************************************************************************** 
* export trial fup tabulation:
* set up spreadsheet
putexcel set "S:\Head_or_Heart\max\identifiers\5-reports\progress $S_DATE", replace
putexcel A1=("Progress report $S_DATE") 
putexcel A2=("trial") B2=("recruitment") C2=("randomisation") D2=("3 weeks") ///
E2=("6 weeks") F2=("8 weeks") G2=("12 weeks") H2=("16 weeks") I2=("18w") ///
J2=("20w") K2=("26w/6m") L2=("9m") M2=("12m") N2=("15m") O2=("18m") P2=("5-6y") ///
Q2=("7-9y") R2=("10-14y") S2=("15y") T2=("16-19y") U2=("20-24y") V2=("25+y")
* first tabulation -recruitment:
tab 	trial fup___1,matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		local val=nam1[`i',1]
		local val_lab:label(trial)`val'
		putexcel A`row'=("`val_lab'") B`row'=(freq1[`i',2])
		local row=`row'+1
		}				
* next column rand :
tab 	trial fup___16, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel C`row'=(freq1[`i',2])
		local row=`row'+1
		}		
* next column 3w:
tab 	trial fup___19, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel D`row'=(freq1[`i',2])
		local row=`row'+1
		}			
* next column 6w:
tab 	trial fup___13, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel E`row'=(freq1[`i',2])
		local row=`row'+1
		}			
* next column 8w:
tab 	trial fup___20, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel F`row'=(freq1[`i',2])
		local row=`row'+1
		}		
* next column 12w:
tab 	trial fup___2, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel G`row'=(freq1[`i',2])
		local row=`row'+1
		}		
* next column 16w:
tab 	trial fup___21, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel H`row'=(freq1[`i',2])
		local row=`row'+1
		}		
* next column 18w:
tab 	trial fup___22,  matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel I`row'=(freq1[`i',2])
		local row=`row'+1
		}				
		
* next column 20w:
tab 	trial fup___3, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel J`row'=(freq1[`i',2])
		local row=`row'+1
		}		
		
* next column 26w/ 6m:
tab 	trial fup___15, matcell(freq1) matrow(nam1) // only use fup___15 here
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel K`row'=(freq1[`i',2])
		local row=`row'+1
		}		
* next column 9m:
tab 	trial fup___4, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel L`row'=(freq1[`i',2])
		local row=`row'+1
		}				
* next column 12m:
tab 	trial fup___17, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel M`row'=(freq1[`i',2])
		local row=`row'+1
		}				
* next column 15m:
tab 	trial fup___14, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel N`row'=(freq1[`i',2])
		local row=`row'+1
		}		
* next column 18m:
tab 	trial fup___5, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel O`row'=(freq1[`i',2])
		local row=`row'+1
		}		
* next column 5-6y:
tab 	trial fup___6, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel P`row'=(freq1[`i',2])
		local row=`row'+1
		}			
* next column 7-9y:
tab 	trial fup___7, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel Q`row'=(freq1[`i',2])
		local row=`row'+1
		}		
		
* next column 10-14y:
tab 	trial fup___8, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel R`row'=(freq1[`i',2])
		local row=`row'+1
		}		

* next column 15y:
tab 	trial fup___9, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel S`row'=(freq1[`i',2])
		local row=`row'+1
		}			
* next column 16-19y:
tab 	trial fup___10, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel T`row'=(freq1[`i',2])
		local row=`row'+1
		}				
* next column 20-24y:
tab 	trial fup___11, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel U`row'=(freq1[`i',2])
		local row=`row'+1
		}		
* next column 25+y:
tab 	trial fup___12, matcell(freq1) matrow(nam1)
local	rows = rowsof(nam1)
local	row = 3 
forvalues i=1/`rows'{
		putexcel V`row'=(freq1[`i',2])
		local row=`row'+1
		}				
cap log 	close				