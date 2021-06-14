/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					02/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Patient_Denom_InclusionApplied.dta
						Raw Observation data extracts from CPRDFast
							
CODELISTS:				HIV_Aurum_Mar20.dta

NEXT STEPS:				2.6_cr_getimmexclusion_organtransplant.do

==============================================================================*/


****************************
***APPLY EXCLUSIONS - HIV***
****************************

***OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\HIV_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid obsdate
	by patid: egen hivdate=min(obsdate) 
	format hivdate %td
	drop if hivdate>d(31aug2018)

	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid hivdate hiv

	*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
	duplicates drop
	
	tempfile observation_HIV_`x'_`y'
	save `observation_HIV_`x'_`y'', replace
	}
	}

forvalues x=1/9 {	
use `observation_HIV_`x'_1', clear
forvalues y=2/10 {
	capture noisily append using `observation_HIV_`x'_`y''
}	
	if _rc==111{
	continue
	}
	sort patid hivdate
	duplicates drop patid, force
	tempfile observation_hiv_`x'
	save `observation_hiv_`x'', replace
	}
	
	use `observation_hiv_1', clear	
	forvalues x=2/9 {
	append using `observation_hiv_`x''
	}	
	
save "$intermediatedatadir\observation_HIV.dta"