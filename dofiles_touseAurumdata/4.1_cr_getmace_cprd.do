/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					05/10/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify CPRD recorded outcomes objective 1-3 (part 1)

DATASETS USED:			Raw Observational data extracts 

NEXT STEPS:				4.2_cr_getmace_hes

==============================================================================*/

*****************************************
***MAJOR ADVERSE CARDIOVASCULAR EVENTS***
*****************************************

***OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\MACE_Aurum_Jan20.dta", keep(match) nogen
	
	drop if obsdate>d(31aug2018)

	keep patid obsdate mace mi angina acs hf stroke tia
	duplicates drop

	tempfile observation_MACE_`x'_`y'
	save `observation_MACE_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_MACE_`x'_1', clear
	forvalues y=2/10 {
	capture noisily append using `observation_MACE_`x'_`y''
	}
	if _rc==111{
	continue
	}
	tempfile observation_MACE_`x'
	save `observation_MACE_`x'', replace
	}

use `observation_MACE_1', clear	
forvalues x=2/9 {
	append using `observation_MACE_`x''
	}
	
gen macesevere_cprd=1 if mi==1 | hf==1 | stroke==1

foreach var of varlist mace mi angina acs hf stroke tia {
	rename `var' `var'_cprd
	}

gen stroketia_cprd=1 if stroke_cprd==1 | tia_cprd==1 // to have same variables as Gold
	
foreach var of varlist mace_cprd mi_cprd angina_cprd acs_cprd hf_cprd stroke_cprd tia_cprd stroketia_cprd macesevere_cprd {	
	sort patid obsdate
	by patid: egen `var'date=min(obsdate) if `var'==1
	sort patid `var'date
	by patid: replace `var'date=`var'date[1]
	format `var'date %td
	} 

foreach var of varlist mace_cprd mi_cprd angina_cprd acs_cprd hf_cprd stroke_cprd tia_cprd stroketia_cprd macesevere_cprd {
	sort patid `var'
	by patid: replace `var'=`var'[1]
	}
	
drop obsdate
duplicates drop
	
save "$datadir\mace_cprd.dta", replace

