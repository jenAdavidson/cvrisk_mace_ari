/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					05/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Therapy data extracts from CPRDFast

CODELISTS:				Immunosuppressants_Aurum_Mar20.dta

NEXT STEPS:				2.14_cr_getimmexclusion_oralsteroids.do

==============================================================================*/

************************
***IMMUNOSUPPRESSANTS***
************************

***DRUG ISSUE

forvalues x=1/9 {
forvalues y=1/6 {
	capture noisily use "$rawdatadir\ari_cvd_extract_drugissue_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 prodcodeid using "$codelistdir\Immunosuppressants_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid issuedate immunosuppressant
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid issuedate
	duplicates drop
	drop if issuedate>d(31aug2018)
	rename issuedate immunosuppressantdate

	tempfile drugissue_Immuno_`x'_`y'
	save `drugissue_Immuno_`x'_`y'', replace
	}
	}

forvalues x=1/9 {	
use `drugissue_Immuno_`x'_1', clear
forvalues y=2/6 {
	capture noisily append using `drugissue_Immuno_`x'_`y''
}
	if _rc==111{
	continue
	}

sort patid immunosuppressantdate
duplicates drop
by patid: gen immunosuppressant_n=_n

tempfile drugissue_immuno_`x'
save `drugissue_immuno_`x'', replace
}

use `drugissue_immuno_1', clear	
forvalues x=2/9 {
	append using `drugissue_immuno_`x''
	}	

save "$intermediatedatadir\drugissue_Immunosuppressants.dta"