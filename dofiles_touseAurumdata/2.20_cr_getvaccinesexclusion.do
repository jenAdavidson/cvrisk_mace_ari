/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					02/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Observation & Drug Issue data extracts from CPRDFast
							
CODELISTS:				PPV_medcodes_Aurum_Mar20
						PPV_prodcodes_Aurum_Mar20
						FluVac_medcodes_Aurum_Mar20
						FluVac_prodcodes_Aurum_Mar20

NEXT STEPS:				3_cr_flagexclusions.do

==============================================================================*/


**********************************
***ANY PNEUMOCOCCAL VACCINATION***
**********************************

**OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\PPV_medcodes_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*DROP IF EVENT DATE BEYOND STUDY PERIOD END
	sort patid obsdate
	drop if obsdate>d(31aug2018)

	*REMOVE DUPLICATES
	keep patid obsdate PPV_vac PPV_given PPV_neutral PPV_declined PPV_contraindic PPV_consent PPV_date_unclear
	duplicates drop
	
	tempfile observation_PPV_`x'_`y'
	save `observation_PPV_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_PPV_`x'_1', clear
	forvalues y=2/10 {
	capture noisily append using `observation_PPV_`x'_`y''
	}
	if _rc==111{
	continue
	}

collapse (max) PPV_vac PPV_given PPV_neutral PPV_declined PPV_contraindic PPV_consent PPV_date_unclear, by(patid obsdate)

	tempfile observation_PPV_`x'
	save `observation_PPV_`x'', replace
	}

use `observation_PPV_1', clear
forvalues x=2/9 {
	append using `observation_PPV_`x''
	}

save "$intermediatedatadir\observation_PPV.dta", replace

***DRUG ISSUE

forvalues x=1/9 {
forvalues y=1/6 {
	capture noisily use "$rawdatadir\ari_cvd_extract_drugissue_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 prodcodeid using "$codelistdir\PPV_prodcodes_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*DROP IF BEYOND STUDY PERIOD END
	drop if issuedate>d(31aug2018)

	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid issuedate ppvprod
	duplicates drop
	
	tempfile drugissue_PPV_`x'_`y'
	save `drugissue_PPV_`x'_`y'', replace
	}
	}

forvalues x=1/9 {		
use `drugissue_PPV_`x'_1', clear
forvalues y=2/6 {
	capture noisily append using `drugissue_PPV_`x'_`y''
	}	
	if _rc==111{
	continue
	}

tempfile drugissue_PPV_`x'
save `drugissue_PPV_`x'', replace
}	
	
use `drugissue_PPV_1', clear	
forvalues x=2/9 {
	append using `drugissue_PPV_`x''
	}		
	
save "$intermediatedatadir\drugissue_PPV.dta", replace
rename issuedate obsdate

***COMBINE OBSERVATION & DRUG ISSUE
merge m:m patid obsdate using "$intermediatedatadir\observation_PPV.dta", nogen

*REMOVE RECORDS IF ONLY HAVE DECLINE OR CONTRAINDICATED FLAG 
drop if PPV_declined==1 & ppvprod==. & PPV_given==. & PPV_date_unclear==. 
drop if PPV_contraindic==1 & ppvprod==. & PPV_given==. & PPV_date_unclear==.

*FLAG RECORDS WITH CONFLICTS
gen ppvvaccconflict=1 if PPV_declined==1 & (PPV_given==1 | ppvprod==1)

*KEEP EARLIEST RECORD
sort patid obsdate
duplicates drop patid, force

rename obsdate ppvvaccdate
gen ppvvacc=1
keep patid ppvvaccdate ppvvacc ppvvaccconflict

save "$intermediatedatadir\observationdrugissue_PPV.dta", replace


**********************************************************
***INFLUENZA VACCINATION IN 12 MONTHS PRIOR TO BASELINE***
**********************************************************

**OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\FluVac_medcodes_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*DROP IF EVENT DATE BEYOND STUDY PERIOD END
	sort patid obsdate
	drop if obsdate>d(31aug2018)

	*REMOVE DUPLICATES
	keep patid obsdate flu_vacc flu_given flu_neutral flu_declined flu_contraindic flu_consent
	duplicates drop
	
	tempfile observation_flu_`x'_`y'
	save `observation_flu_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_flu_`x'_1', clear
	forvalues y=2/10 {
	capture noisily append using `observation_flu_`x'_`y''
}	
	if _rc==111{
	continue
	}

collapse (max) flu_vacc flu_given flu_neutral flu_declined flu_contraindic flu_consent, by(patid obsdate)

	tempfile observation_flu_`x'
	save `observation_flu_`x'', replace
	}

use `observation_flu_1', clear
forvalues x=2/9 {
	append using `observation_flu_`x''
	}

save "$intermediatedatadir\observation_FluVac.dta", replace

***DRUG ISSUE

forvalues x=1/9 {
forvalues y=1/6 {
	capture noisily use "$rawdatadir\ari_cvd_extract_drugissue_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 prodcodeid using "$codelistdir\FluVac_prodcodes_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*DROP IF BEYOND STUDY PERIOD END
	drop if issuedate>d(31aug2018)

	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid issuedate fluvacprod
	duplicates drop
	
	tempfile drugissue_flu_`x'_`y'
	save `drugissue_flu_`x'_`y'', replace
	}
	}

forvalues x=1/9 {		
use `drugissue_flu_`x'_1', clear
forvalues y=2/6 {
	capture noisily append using `drugissue_flu_`x'_`y''
	}
	if _rc==111{
	continue
	}

tempfile drugissue_flu_`x'
save `drugissue_flu_`x'', replace
}	
	
use `drugissue_flu_1', clear	
forvalues x=2/9 {
	append using `drugissue_flu_`x''
	}		
	
save "$intermediatedatadir\drugissue_FluVac.dta", replace
rename issuedate obsdate

***COMBINE OBSERVATION & DRUG ISSUE
merge m:m patid obsdate using "$intermediatedatadir\observation_FluVac.dta", nogen

*REMOVE RECORDS IF ONLY HAVE DECLINE OR CONTRAINDICATED FLAG 
drop if flu_declined==1 & fluvacprod==. & flu_given==.
drop if flu_contraindic==1 & fluvacprod==. & flu_given==.

*FLAG RECORDS WITH CONFLICTS
gen fluvaccconflict=1 if flu_declined==1 & (flu_given==1 | fluvacprod==1)

rename obsdate fluvaccdate
gen fluvacc=1
keep patid fluvaccdate fluvacc fluvaccconflict
duplicates drop

sort patid fluvaccdate
by patid: gen fluvacc_n=_n

save "$intermediatedatadir\observationdrugissue_FluVac.dta", replace