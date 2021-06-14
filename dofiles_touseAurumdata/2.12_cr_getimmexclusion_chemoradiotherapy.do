/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					02/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Patient_Denom_InclusionApplied.dta
						Raw Observation data extracts from CPRDFast
							
CODELISTS:				ChemoRadioTherapy_Aurum_Mar20.dta

NEXT STEPS:				2.13_cr_getimmexclusion_immunosuppressants.do

==============================================================================*/


****************************************************
***APPLY EXCLUSIONS - CHEMOTHERAPY & RADIOTHERAPY***
****************************************************

***OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\ChemoRadioTherapy_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid obsdate chemoradio
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid obsdate
	duplicates drop
	drop if obsdate>d(31aug2018)
	rename obsdate chemoradiodate

	tempfile observation_Chemo_`x'_`y'
	save `observation_Chemo_`x'_`y'', replace
	}
	}
	
forvalues x=1/9 {
use `observation_Chemo_`x'_1', clear
forvalues y=2/10 {
	capture noisily append using `observation_Chemo_`x'_`y''
}
	if _rc==111{
	continue
	}
	tempfile observation_chemo_`x'
	save `observation_chemo_`x'', replace
	}
	
	use `observation_chemo_1', clear	
	forvalues x=2/9 {
	append using `observation_chemo_`x''
	}		

sort patid chemoradiodate
duplicates drop
by patid: gen chemoradio_n=_n

save "$intermediatedatadir\observation_ChemoRadioTherapy.dta"