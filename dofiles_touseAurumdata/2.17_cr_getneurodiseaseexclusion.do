/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					02/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Patient_Denom_InclusionApplied.dta
						Raw Observation data extracts from CPRDFast
							
CODELISTS:				ChronicNeuroDiseaseWithDisabilites_Aurum_Mar20.dta

NEXT STEPS:				2.18_cr_getasthmaexclusion.do

==============================================================================*/


********************************************************
***APPLY EXCLUSIONS - CHRONIC NEUROLOGICAL CONDITIONS***
********************************************************

***OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\ChronicNeuroDiseaseWithDisabilites_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid obsdate
	by patid: egen neurodate=min(obsdate) 
	format neurodate %td
	drop if neurodate>d(31aug2018)

	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid neurodate neuro

	*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
	duplicates drop
	
	tempfile observation_Neuro_`x'_`y'
	save `observation_Neuro_`x'_`y'', replace
	}
	}

forvalues x=1/9 {	
use `observation_Neuro_`x'_1', clear
forvalues y=2/10 {
	capture noisily append using `observation_Neuro_`x'_`y''
}	
	if _rc==111{
	continue
	}
	sort patid neurodate
	duplicates drop patid, force
	tempfile observation_neuro_`x'
	save `observation_neuro_`x'', replace
	}
	
	use `observation_neuro_1', clear	
	forvalues x=2/9 {
	append using `observation_neuro_`x''
	}	
	
save "$intermediatedatadir\observation_Neuro.dta"