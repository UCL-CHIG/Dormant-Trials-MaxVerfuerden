/*******************************************************************************
Project: 	head or heart
Purpose: 	cleans merged redcap-trial database
Author: 	Max Verfuerden
Created:	08.08.2017
*******************************************************************************/
* basics - set up filepaths, start log and load dataset
********************************************************************************
qui do 		"S:\Head_or_Heart\max\archive\2-do\00-global.do"
cd 			"$projectdir"
cap log 	close
log using 	"${logdir}\clean_and_validate_redcaptrial_$S_DATE.log", replace 
use			"${datadir}\ID_merged_database.dta", clear
* lowercase:
********************************************************************************
foreach 	var of varlist city* county* *name* street* *firstna* *lastna* patnot* {
replace		`var' = lower(`var')
replace		`var' = trim(`var')
}
* clean streets:
********************************************************************************
foreach 	street of varlist street* {
replace 	`street' = subinstr(`street', "st ", "street",.) 
} 
foreach 	street of varlist street* {
replace 	`street' = subinstr(`street', "st.", "street",.) 
}  
foreach 	street of varlist street* {
replace 	`street' = subinstr(`street', "ave ", "avenue",.) 
}  
foreach 	street of varlist street* {
replace 	`street' = subinstr(`street', "ave.", "avenue",.) 
}  
foreach 	street of varlist street* {
replace 	`street' = subinstr(`street', "cl ", "close",.) 
}  
foreach 	street of varlist street* {
replace 	`street' = subinstr(`street', "cl.", "close",.) 
}  
foreach 	street of varlist street* {
replace		`street' = substr(`street', 1, strpos(`street', ", off") - 1) if strpos(`street', ", off")
} 
* clean counties:
********************************************************************************
//the problem here is that there is no space at the end of the county - to avoid
//replacing only word section I add a space at the end of the county
tab 		county1, m 
** Leicestershire
foreach 	county of varlist county* {
replace 	`county' = `county'+" "
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "leics ", "leicestershire",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "leic ", "leicestershire",.) 
} 
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "leica ", "leicestershire",.) 
} 
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "leicester ", "leicestershire",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "leicesthershire ", "leicestershire",.) 
}  
replace 	county1 = "leicestershire" if strpos(city1, "leicester") & county1==" "
replace 	county2 = "leicestershire" if strpos(city2, "leicester") & county2==" "
replace 	county3 = "leicestershire" if strpos(city3, "leicester") & county3==" "
replace 	county4 = "leicestershire" if strpos(city4, "leicester") & county4==" " 
** Cambridgeshire
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "cambs ", "cambridgeshire",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "cambs", "cambridgeshire",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "cambridgehshire ", "cambridgeshire",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "cambrdiegshire ", "cambridgeshire",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "cambrdigeshire ", "cambridgeshire",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "cambrigdehshire ", "cambridgeshire",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "cambridgshire ", "cambridgeshire",.) 
}  
replace 	county1 = "cambridgeshire" if strpos(city1, "cambridge") & county1==" " 
replace 	county2 = "cambridgeshire" if strpos(city2, "cambridge") & county2==" " 
replace 	county3 = "cambridgeshire" if strpos(city3, "cambridge") & county3==" " 
replace 	county4 = "cambridgeshire" if strpos(city4, "cambridge") & county4==" " 
** Nottinghamshire
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "notts ", "nottinghamshire",.) 
} 
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "nottighamshire ", "nottinghamshire",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "nottinghamsgire ", "nottinghamshire",.) 
} 
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "notthinghamshire ", "nottinghamshire",.) 
}  
replace 	county1 = "nottinghamshire" if strpos(city1, "nottingham") & county1==" " 
replace 	county2 = "nottinghamshire" if strpos(city2, "nottingham") & county2==" " 
replace 	county3 = "nottinghamshire" if strpos(city3, "nottingham") & county3==" " 
replace 	county4 = "nottinghamshire" if strpos(city4, "nottingham") & county4==" " 
** Hertfordshire
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "herts ", "hertfordshire",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "herfordshire ", "hertfordshire",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "herttfordshire ", "hertfordshire",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "royston", "hertfordshire",.) 
}
** Others
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "saffron walden, essex", "essex",.)  
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "ware", "hertfordshire",.)  
} 
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "renfreshire", "renfrewshire",.)  
} 
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "lancashire", "lanarkshire",.)  
} 
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "linconshire ", "lincolnshire",.) 
} 
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "bedforshire ", "bedfordshire",.) 
} 
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "sugffolk ", "suffolk",.) 
}  
foreach 	county of varlist county* {
replace 	`county' = subinstr(`county', "dunbartons hire", "dunbartonshire",.) 
}
f varlist county* {
replace 	`county' = subinstr(`county', "`", "",.) 
}  
* clean cities:
********************************************************************************
foreach 	city of varlist city* {
replace 	`city' = subinstr(`city', "cambs ", "cambridge",.) 
}  
* clean dobs
********************************************************************************
replace		d_dob = d_dob_clin if d_dob ==. & d_dob_clin !=.
* clean sex
********************************************************************************
replace		sex=sex_clin if sex==. & sex_clin !=.
** consistency checks
********************************************************************************
* drop improbable dates
/* remove dates prior to 01.01.1930 */
foreach 	var of varlist d_* {
replace		`var' =. if `var' < mdy(01,01,1930) 
}
drop		add1 add2 add3 add4
** clean address dates
********************************************************************************
local 		i=1
foreach 	var of varlist d_maxadd*  {
			rename `var' d_maxadd_`i'
			local i = `i' + 1 
}	
local 		i=1
foreach 	var of varlist d_minadd*  {
			rename `var' d_minadd_`i'
			local i = `i' + 1 
}
** clean some labels
********************************************************************************
label		var d_minadd_1 "earliest recorded date for address 1"
label		var d_minadd_2 "earliest recorded date for address 2"
label		var d_minadd_3 "earliest recorded date for address 3"
label		var d_minadd_4 "earliest recorded date for address 4"
label		var d_maxadd_1 "last recorded date for address 1"
label		var d_maxadd_2 "last recorded date for address 2"
label		var d_maxadd_3 "last recorded date for address 3"
label		var d_maxadd_4 "last recorded date for address 4"
compress
save		"${datadir}\clean ID database $S_DATE.dta", replace
** which group are they in?
********************************************************************************
merge 1:1 	studyid1 using "S:\Head_or_Heart\max\attributes\1-Data\all\cog_missingess_dataset.dta", keepusing(multiple)