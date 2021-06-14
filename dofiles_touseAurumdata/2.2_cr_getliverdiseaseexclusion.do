/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					21/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Patient_Denom_InclusionApplied.dta
						Raw Observation data extracts from CPRDFast
							
CODELISTS:				LiverDisease_Aurum_Mar20.dta

NEXT STEPS:				2.3_cr_getspleendyfunctionexclusion.do

==============================================================================*/


**********************************************
***APPLY EXCLUSIONS - CHRONIC LIVER DISEASE***
**********************************************

***OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
		if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\LiverDisease_Aurum_Mar20.dta", keep(match) nogen
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid obsdate
	by patid: egen liverdate=min(obsdate) 
	format liverdate %td
	drop if liverdate>d(31aug2018)

	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid liverdate liver

	*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
	duplicates drop
	
	tempfile observation_Liver_`x'_`y'
	save `observation_Liver_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_Liver_`x'_1', clear
forvalues y=2/10 {
	capture noisily append using `observation_Liver_`x'_`y''
	}
	if _rc==111{
	continue
	}
	sort patid liverdate
	duplicates drop patid, force
	tempfile observation_liver_`x'
	save `observation_liver_`x'', replace
	}

use `observation_liver_1', clear	
forvalues x=2/9 {
	append using `observation_liver_`x''
	}

save "$intermediatedatadir\observation_Liver.dta", replace