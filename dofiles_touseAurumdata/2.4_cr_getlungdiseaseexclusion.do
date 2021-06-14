/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					02/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Patient_Denom_InclusionApplied.dta
						Raw Observation data extracts from CPRDFast
							
CODELISTS:				LungDisease_Aurum_Mar20.dta

NEXT STEPS:				2.5_cr_getimmexclusion_hiv.do

==============================================================================*/


**********************************************
***APPLY EXCLUSIONS - CHRONIC LUNG DISEASE****
**********************************************

***OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\LungDisease_Aurum_Mar20.dta", keep(match) nogen
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid obsdate
	by patid: egen lungdate=min(obsdate) 
	format lungdate %td
	drop if lungdate>d(31aug2018)

	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid lungdate lung

	*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
	duplicates drop
	
	tempfile observation_Lung_`x'_`y'
	save `observation_Lung_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_Lung_`x'_1', clear
forvalues y=2/10 {
	capture noisily append using `observation_Lung_`x'_`y''
}	
	if _rc==111{
	continue
	}
	sort patid lungdate
	duplicates drop patid, force
	tempfile observation_lung_`x'
	save `observation_lung_`x'', replace
	}
	
	use `observation_lung_1', clear	
	forvalues x=2/9 {
	append using `observation_lung_`x''
	}	
	
save "$intermediatedatadir\observation_Lung.dta"