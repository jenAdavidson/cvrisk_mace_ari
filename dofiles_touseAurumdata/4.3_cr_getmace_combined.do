/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					05/10/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify CPRD recorded outcomes objective 1-3 (part 1)

DATASETS USED:			MACE CPRD & HES

NEXT STEPS:				4.4_cr_flagmace

==============================================================================*/

*****************************************
***MAJOR ADVERSE CARDIOVASCULAR EVENTS***
*****************************************

///
***COMBINE TWO DATA SOURCES
use $datadir\mace_cprd, clear
merge 1:1 patid using $datadir\mace_hes
sort patid

///
***UPDATE MACE OUTCOMES TO COMBINE RESULTS FROM CPRD & HES 
local outcomes mace mi angina acs hf stroke tia stroketia macesevere
foreach i of local outcomes {
	gen `i'=1 if `i'_cprd==1 | `i'_hes==1
	gen `i'date=`i'_cprddate
	replace `i'date=`i'_hesdate if `i'_hesdate<`i'date
	format `i'date %td
	gen `i'source=0 if `i'_cprd==1
	replace `i'source=1 if `i'_hes==1
	replace `i'source=2 if `i'_cprd==1 & `i'_hes==1
	replace `i'source=3 if `i'_cprd==1 & `i'_hes==1 & `i'_hesdate<`i'_cprddate
	replace `i'source=4 if `i'_cprd==1 & `i'_hes==1 & `i'_cprddate<`i'_hesdate
	label values `i'source source
	drop `i'_cprd `i'_hes `i'_cprddate `i'_hesdate
	}

label define source 0 "CPRD" 1 "HES" 2 "CPRD & HES same date" 3 "CPRD & HES with HES date earlier" 4 "CPRD & HES with CPRD date earlier"

rename ali_hes ali
rename ali_hesdate alidate
drop _merge

***ADD IN ONS DEATHS WHICH ARE CODED AS CVD
preserve
use $datadir\ons_deaths, clear
keep if strmatch(cause, "I*")
rename cause cvddeathcause
rename dod cvddeathdate
drop if cvddeathdate>d(31aug2018)
gen cvddeath=1
keep patid cvddeathcause cvddeathdate cvddeath
save $datadir\cvddeaths, replace
restore

merge 1:1 patid using $datadir\cvddeaths, nogen
***UPDATE MACE DATE IF ONS CVD DEATH DATE WAS EARLIER
replace macedate=cvddeathdate if macedate==. & cvddeathdate!=.
replace mace=1 if cvddeath==1 & mace==.
replace macedate=cvddeathdate if cvddeathdate<macedate
replace macesevere=1 if cvddeath==1 & macesevere==.
replace maceseveredate=cvddeathdate if maceseveredate==.  & cvddeathdate!=.
replace maceseveredate=cvddeathdate if cvddeathdate<maceseveredate

save $datadir\mace_combined, replace

