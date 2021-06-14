/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					21/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Patient_Denom_InclusionApplied.dta
						Raw Observation data extracts from CPRDFast
							
CODELISTS:				ExistingCVD_Aurum_Jan20.dta

NEXT STEPS:				2.2_cr_getliverdiseaseexclusion.do

==============================================================================*/


*************************************
***APPLY EXCLUSIONS - EXISTING CVD***
*************************************

***OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\ExistingCVD_Aurum_Jan20.dta", keep(match) nogen
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid obsdate
	by patid: egen cvddate=min(obsdate) 
	format cvddate %td
	drop if cvddate>d(31aug2018)

	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid cvddate cvd

	*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
	duplicates drop
	
	tempfile observation_CVD_`x'_`y'
	save `observation_CVD_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_CVD_`x'_1', clear
	forvalues y=2/10 {
	capture noisily append using `observation_CVD_`x'_`y''
	}
	if _rc==111{
	continue
	}
	sort patid cvddate
	duplicates drop patid, force
	tempfile observation_CVD_`x'
	save `observation_CVD_`x'', replace
	}

use `observation_CVD_1', clear	
forvalues x=2/9 {
	append using `observation_CVD_`x''
	}
	
save "$intermediatedatadir\observation_CVD.dta", replace