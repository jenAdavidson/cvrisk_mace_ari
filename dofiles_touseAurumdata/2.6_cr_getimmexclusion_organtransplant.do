/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					02/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Patient_Denom_InclusionApplied.dta
						Raw Observation data extracts from CPRDFast
							
CODELISTS:				Transplant_Aurum_Mar20.dta

NEXT STEPS:				2.7_cr_getimmexclusion_permcmi.do

==============================================================================*/


*****************************************
***APPLY EXCLUSIONS - ORGAN TRANSPLANT***
*****************************************

***OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\Transplant_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid obsdate
	by patid: egen transplantdate=min(obsdate) 
	format transplantdate %td
	drop if transplantdate>d(31aug2018)

	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid transplantdate transplant

	*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
	duplicates drop
	
	tempfile observation_Transplant_`x'_`y'
	save `observation_Transplant_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_Transplant_`x'_1', clear
forvalues y=2/10 {
	capture noisily append using `observation_Transplant_`x'_`y''
}	
	if _rc==111{
	continue
	}
	sort patid transplantdate
	duplicates drop patid, force
	tempfile observation_transplant_`x'
	save `observation_transplant_`x'', replace
	}
	
	use `observation_transplant_1', clear	
	forvalues x=2/9 {
	append using `observation_transplant_`x''
	}	

save "$intermediatedatadir\observation_Transplant.dta"