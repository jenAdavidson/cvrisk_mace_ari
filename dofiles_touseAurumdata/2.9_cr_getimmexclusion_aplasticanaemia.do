/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					02/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Patient_Denom_InclusionApplied.dta
						Raw Observation data extracts from CPRDFast
							
CODELISTS:				AplasticAnaemia_Aurum_Mar20.dta

NEXT STEPS:				2.10_cr_getimmexclusion_bonemarrowstemcell.do

==============================================================================*/


*****************************************
***APPLY EXCLUSIONS - APLASTIC ANAEMIC***
*****************************************

***OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\AplasticAnaemia_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid obsdate aplastic
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid obsdate
	duplicates drop
	drop if obsdate>d(31aug2018)
	if _N == 0 continue
	rename obsdate aplasticdate
	
	tempfile observation_Aplastic_`x'_`y'
	save `observation_Aplastic_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_Aplastic_`x'_1', clear
forvalues y=2/10 {
	capture noisily append using `observation_Aplastic_`x'_`y''
}	
	if _rc==111{
	continue
	}
	tempfile observation_aplastic_`x'
	save `observation_aplastic_`x'', replace
	}
	
	use `observation_aplastic_1', clear	
	forvalues x=2/9 {
	append using `observation_aplastic_`x''
	}	
	
sort patid aplasticdate
duplicates drop
by patid: gen aplastic_n=_n

save "$intermediatedatadir\observation_AplasticAnaemia.dta"