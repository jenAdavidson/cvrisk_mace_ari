/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Therapy data extracts from CPRDFast

CODELISTS:				OralSteroids_Aurum_Mar20.dta

NEXT STEPS:				2.15_cr_getckdexclusion.do

==============================================================================*/

*******************
***ORAL STEROIDS***
*******************

***DRUG ISSUE

forvalues x=1/9 {
forvalues y=1/6 {
	capture noisily use "$rawdatadir\ari_cvd_extract_drugissue_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 prodcodeid using "$codelistdir\OralSteroids_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid issuedate steroid
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid issuedate
	duplicates drop
	drop if issuedate>d(31aug2018)
	rename issuedate steroiddate

	tempfile drugissue_Steroid_`x'_`y'
	save `drugissue_Steroid_`x'_`y'', replace
	}
	}

forvalues x=1/9 {	
use `drugissue_Steroid_`x'_1', clear
forvalues y=2/6 {
	capture noisily append using `drugissue_Steroid_`x'_`y''
	}
	if _rc==111{
	continue
	}
tempfile drugissue_steroid_`x'
save `drugissue_steroid_`x'', replace
}

use `drugissue_steroid_1', clear	
forvalues x=2/9 {
	append using `drugissue_steroid_`x''
	}	

sort patid steroiddate
duplicates drop
by patid: gen oralsteroid_n=_n
by patid: gen oralsteroid_N=_N
drop if oralsteroid_N==1	
	
save "$intermediatedatadir\drugissue_OralSteroids.dta", replace