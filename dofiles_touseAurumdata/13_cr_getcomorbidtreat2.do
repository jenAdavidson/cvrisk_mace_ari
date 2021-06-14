/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					07/12/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population for objective 4

DATASETS USED:			ari_episodes etc

NEXT STEPS:				21_cr_getcvrisk2
==============================================================================*/

**TREATMENT IN THE YEAR BEFORE INDEX DATE

local explanatory antihypertens statins antiplatelet
local file ari ari_pneumo ari_flu
local denom StudyPop SensStudyPop
foreach pop of local denom {
foreach cond of local file {
foreach covariate of local explanatory {
	use $datadir/`pop'_`cond'_mace, clear
	keep patid indexdate `cond'_n
	reshape wide indexdate, i(patid) j(`cond'_n)
	merge 1:m patid using $intermediatedatadir/drugissue_`covariate', keep(master match) keepusing(`covariate'date `covariate') nogen
	
	forvalues i = 1/9 {
	capture noisily gen days_`covariate'`i'=`covariate'date-indexdate`i'
	capture noisily gen `covariate'in365days`i'=1 if days_`covariate'`i'>-366 & days_`covariate'`i'<=0
	capture noisily sort patid `covariate'in365days`i'
	capture noisily by patid: replace `covariate'in365days`i'=`covariate'in365days`i'[1]
	}
	
	keep patid indexdate* `covariate' `covariate'in365days*
	duplicates drop
	
	reshape long indexdate `covariate'in365days, i(patid) j(`cond'_n)
	drop if indexdate==.
	
	replace `covariate'=. if `covariate'in365days!=1
	drop `covariate'in365days
	save $datadir/`pop'_`cond'_mace_`covariate', replace
	}
	}
	}


**ANTIVIRAL ON THE SAME DAY ARE ARI

local file ari ari_pneumo ari_flu
local denom StudyPop SensStudyPop	
foreach pop of local denom {
foreach cond of local file {
	use $datadir/`pop'_`cond'_mace, clear
	keep patid indexdate `cond'_n
	reshape wide indexdate, i(patid) j(`cond'_n)
	merge 1:m patid using $datadir/`pop'_antivirals, keep(master match) keepusing(antiviraldate antiviral) nogen
	
	forvalues i = 1/9 {
	capture noisily gen sameday`i'=1 if antiviraldate==indexdate`i'
	capture noisily sort patid sameday`i'
	capture noisily by patid: replace sameday`i'=sameday`i'[1]
	}
	
	keep patid indexdate* antiviral sameday*
	duplicates drop
	
	reshape long indexdate sameday, i(patid) j(`cond'_n)
	drop if indexdate==.
	
	replace antiviral=. if sameday!=1
	drop sameday
	save $datadir/`pop'_`cond'_mace_antiviral, replace
	
	}
	}
	

**VACCINATION DURING FOLLOWUP
local vaccination fluvacc ppvvacc
local outcome mace macesevere mi angina acs hf ali stroke tia stroketia cvddeath
local explanatory antihypertens statins antiplatelet
local file ari ari_pneumo ari_flu
local denom StudyPop SensStudyPop	
foreach pop of local denom {
foreach cond of local file {
foreach vacc of local vaccination {
	use $datadir/`pop'_`cond'_mace, clear
	keep patid indexdate endfudate* `cond'_n
	reshape wide indexdate endfudate*, i(patid) j(`cond'_n)
	merge 1:m patid using $intermediatedatadir/observationdrugissue_`vacc', keep(master match) keepusing(`vacc'date) nogen
	
	foreach var of local outcome {
	forvalues i = 1/9 {
	capture noisily gen `vacc'_`var'`i'=1 if `vacc'date>=indexdate`i' & `vacc'date<endfudate_`var'`i'
	capture noisily sort patid `vacc'_`var'`i'
	capture noisily by patid: replace `vacc'_`var'`i'=`vacc'_`var'`i'[1]
	}
	}
	
	keep patid indexdate* endfudate* `vacc'_*
	duplicates drop
	reshape long indexdate endfudate_mace endfudate_macesevere endfudate_mi endfudate_angina endfudate_acs endfudate_hf endfudate_ali endfudate_stroke endfudate_tia endfudate_stroketia endfudate_cvddeath `vacc'_mace `vacc'_macesevere `vacc'_mi `vacc'_angina `vacc'_acs `vacc'_hf `vacc'_ali `vacc'_stroke `vacc'_tia `vacc'_stroketia `vacc'_cvddeath, i(patid) j(`cond'_n)

	drop if indexdate==.
	
	save $datadir/`pop'_`cond'_mace_`vacc', replace
	
	}
	}
	}
	