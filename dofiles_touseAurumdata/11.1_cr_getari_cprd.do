/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					13/10/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify CPRD recorded outcomes objective 1-3 (part 1)

DATASETS USED:			Observation files

NEXT STEPS:				11.2_cr_getari_hes

==============================================================================*/

**********************************
***ACUTE RESPIRATORY INFECTIONS***
**********************************

///
***IDENTIFY EVENTS IN OBSERVATION FILE

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
		if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\ARI_Aurum_Mar20.dta", keep(match) nogen

*DROP DUPLCATES & RECORDS BEYOND STUDY PERIOD END
drop if obsdate>d(31aug2018)

keep patid obsdate ari ari_flu ari_pneumo
duplicates drop

	tempfile observation_ari_`x'_`y'
	save `observation_ari_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_ari_`x'_1', clear
forvalues y=2/10 {
	capture noisily append using `observation_ari_`x'_`y''
	}
	if _rc==111{
	continue
	}
	duplicates drop
	tempfile observation_ari_`x'
	save `observation_ari_`x'', replace
	}

use `observation_ari_1', clear	
forvalues x=2/9 {
	append using `observation_ari_`x''
	}

sort patid obsdate
rename obsdate aridate_cprd
rename ari ari_cprd
rename ari_flu ari_flu_cprd
rename ari_pneumo ari_pneumo_cprd

///
***SAVE MASTER COPY OF ALL MATCHES
save "$datadir\ari_cprd.dta", replace
