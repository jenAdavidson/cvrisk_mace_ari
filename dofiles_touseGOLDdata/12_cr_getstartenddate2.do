/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					30/11/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population for objective 4

DATASETS USED:			ari_episodes etc

NEXT STEPS:				20_cr_getcvrisk2

==============================================================================*/


**CALCULATE START DATE


local file ari ari_pneumo ari_flu
local denom StudyPop SensStudyPop
foreach pop of local denom {
foreach cond of local file {

use $datadir/`pop'_`cond'episodes, clear
keep patid aridate `cond' 

gen indexdate=.
format indexdate %td
gen aricount=.

sort patid aridate
forvalues i=1/10 {
by patid: egen indexdate`i'=min(aridate) if indexdate==.
format indexdate`i' %td
gen indexari`i'=1 if (aridate-indexdate`i')<366
by patid: egen aricount`i'=sum(indexari`i') if indexari`i'==1
drop if aridate!=indexdate`i' & indexari`i'==1
replace indexdate=indexdate`i' if indexari`i'==1
replace aricount=aricount`i' if aricount`i'!=.
}

assert indexdate!=.
drop aridate

forvalues i=1/10 {
drop indexdate`i' indexari`i' aricount`i'
}

by patid: gen `cond'_n=_n
by patid: gen `cond'_N=_N

unique patid


merge m:1 patid using $datadir/`pop', keep(match master) keepusing(gender dob bmipriorstatus enddate) nogen 

merge m:1 patid using $datadir/`pop'_mace, keep(match master) nogen 
merge m:1 patid using $datadir\ons_deaths, nogen keep(match master) keepusing(dod)

foreach var of varlist mace macesevere mi angina acs hf ali stroke tia stroketia cvddeath { 
replace `var'=. if `var'date<indexdate
replace `var'=. if (`var'date-indexdate)>366
replace `var'date=. if `var'==.
gen endfudate_`var'=min(`var'date, enddate, dod, indexdate+365.25, d(31/08/2018))
format endfudate_`var' %td
}

unique patid

save $datadir/`pop'_`cond'_mace, replace

}
}


