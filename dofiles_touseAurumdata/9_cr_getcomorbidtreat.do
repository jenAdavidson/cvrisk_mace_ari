/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					11/10/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				covariate analysis
							
CODELISTS:				AtrialFibrillation_Aurum_Mar20.dta

NEXT STEPS:				10_cr_getcvrisk.do

==============================================================================*/

*******ATRIAL FIBRILLATION*******

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
		if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\AtrialFibrillation_Aurum_Mar20.dta", keep(match) nogen
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid obsdate
	by patid: egen atrialfibdate=min(obsdate) 
	format atrialfibdate %td
	drop if atrialfibdate>d(31aug2018)

	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid atrialfibdate atrialfib

	*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
	duplicates drop
	
	tempfile observation_af_`x'_`y'
	save `observation_af_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_af_`x'_1', clear
forvalues y=2/10 {
	capture noisily append using `observation_af_`x'_`y''
	}
	if _rc==111{
	continue
	}
	sort patid atrialfibdate
	duplicates drop patid, force
	tempfile observation_af_`x'
	save `observation_af_`x'', replace
	}

use `observation_af_1', clear	
forvalues x=2/9 {
	append using `observation_af_`x''
	}

save "$intermediatedatadir\observation_AF.dta", replace

***ASSIGN IN DATASET
local denom StudyPop SensStudyPop
foreach pop of local denom {
	use `pop', clear
	keep patid studystartdate 
	merge 1:1 patid using $intermediatedatadir\observation_AF, keep(master match) nogen
	replace atrialfib=0 if atrialfibdate==. | atrialfibdate>studystartdate
	save "$datadir/`pop'_atrialfib", replace
	}


*******ANTI-HYPERTENSIVES*******

forvalues x=1/9 {
forvalues y=1/6 {
	capture noisily use "$rawdatadir\ari_cvd_extract_drugissue_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 prodcodeid using "$codelistdir\cr_codelist_antihypertensives_aurum.dta", keep(match) keepusing(prodcodeid) nogen force
	if _N == 0 continue
	
	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	gen antihypertens=1
	
	*ONLY KEEP ONE OBSERVATION PER EVENT DATE
	sort patid issuedate
	duplicates drop
	drop if issuedate>d(31aug2018)
	rename issuedate antihypertensdate

	tempfile drugissue_antihypertens_`x'_`y'
	save `drugissue_antihypertens_`x'_`y'', replace
	}
	}

forvalues x=1/9 {	
use `drugissue_antihypertens_`x'_1', clear
forvalues y=2/6 {
	capture noisily append using `drugissue_antihypertens_`x'_`y''
	}
	if _rc==111{
	continue
	}

duplicates drop
tempfile drugissue_antihypertens_`x'
save `drugissue_antihypertens_`x'', replace
}

use `drugissue_antihypertens_1', clear	
forvalues x=2/9 {
	append using `drugissue_antihypertens_`x''
	}	
save "$intermediatedatadir\drugissue_antihypertens.dta"

***ASSIGN IN DATASET
local denom StudyPop SensStudyPop
foreach pop of local denom {
	use "$datadir/`pop'", clear
	keep patid studystartdate 
	merge 1:m patid using $intermediatedatadir\drugissue_antihypertens, keep(master match) nogen
	gen days_antihypertens=antihypertensdate-studystartdate
	gen antihypertensin365days=1 if days_antihypertens>-366 & days_antihypertens<=0
	sort patid antihypertensin365days
	by patid: replace antihypertensin365days=antihypertensin365days[1]
	keep patid antihypertens antihypertensin365days
	duplicates drop
	replace antihypertens=. if antihypertensin365days!=1
	drop antihypertensin365days
	save "$datadir/`pop'_antihypertens", replace
	}
	
	
*******STATINS*******

forvalues x=1/9 {
forvalues y=1/6 {
	capture noisily use "$rawdatadir\ari_cvd_extract_drugissue_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 prodcodeid using "$codelistdir\cr_codelist_statins_aurum.dta", keep(match) keepusing(prodcodeid) nogen force
	if _N == 0 continue
	
	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	gen statin=1
	
	*ONLY KEEP ONE OBSERVATION PER EVENT DATE
	sort patid issuedate
	duplicates drop
	drop if issuedate>d(31aug2018)
	rename issuedate statindate

	tempfile drugissue_statins_`x'_`y'
	save `drugissue_statins_`x'_`y'', replace
	}
	}

forvalues x=1/9 {	
use `drugissue_statins_`x'_1', clear
forvalues y=2/6 {
	capture noisily append using `drugissue_statins_`x'_`y''
	}
	if _rc==111{
	continue
	}

duplicates drop
tempfile drugissue_statins_`x'
save `drugissue_statins_`x'', replace
}

use `drugissue_statins_1', clear	
forvalues x=2/9 {
	append using `drugissue_statins_`x''
	}	
save "$intermediatedatadir\drugissue_statins.dta"

***ASSIGN IN DATASET
local denom StudyPop SensStudyPop
foreach pop of local denom {
	use "$datadir/`pop'", clear
	keep patid studystartdate 
	merge 1:m patid using $intermediatedatadir\drugissue_statins, keep(master match) nogen
	gen days_statin=statindate-studystartdate
	gen statinin365days=1 if days_statin>-366 & days_statin<=0
	sort patid statinin365days
	by patid: replace statinin365days=statinin365days[1]
	keep patid statin statinin365days
	duplicates drop
	replace statin=. if statinin365days!=1
	drop statinin365days
	save "$datadir/`pop'_statins", replace
	}
	
	
*******ANTIVIRALS*******

forvalues x=1/9 {
forvalues y=1/6 {
	capture noisily use "$rawdatadir\ari_cvd_extract_drugissue_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 prodcodeid using "$codelistdir\Antivirals_Jan_2019_hf_aurum.dta", keep(match) nogen
	if _N == 0 continue
	
	*ONLY KEEP ONE OBSERVATION PER EVENT DATE
	sort patid issuedate
	duplicates drop
	drop if issuedate>d(31aug2018)
	rename issuedate antiviraldate

	tempfile drugissue_antiviral_`x'_`y'
	save `drugissue_antiviral_`x'_`y'', replace
	}
	}

forvalues x=1/9 {	
use `drugissue_antiviral_`x'_1', clear
forvalues y=2/6 {
	capture noisily append using `drugissue_antiviral_`x'_`y''
	}
	if _rc==111{
	continue
	}

duplicates drop
tempfile drugissue_antiviral_`x'
save `drugissue_antiviral_`x'', replace
}

use `drugissue_antiviral_1', clear	
forvalues x=2/9 {
	append using `drugissue_antiviral_`x''
	}	
save "$intermediatedatadir\drugissue_antiviral.dta"

***ASSIGN IN DATASET
local denom StudyPop SensStudyPop
foreach pop of local denom {
	use "$datadir/`pop'", clear
	keep patid studystartdate 
	merge 1:m patid using $intermediatedatadir\drugissue_antiviral, keep(master match) nogen
	save "$datadir/`pop'_antivirals", replace
	}
	

*******ANTIPLATELETS*******

forvalues x=1/9 {
forvalues y=1/6 {
	capture noisily use "$rawdatadir\ari_cvd_extract_drugissue_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 prodcodeid using "$codelistdir\Antiplatelet_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*ONLY KEEP ONE OBSERVATION PER EVENT DATE
	sort patid issuedate
	duplicates drop
	drop if issuedate>d(31aug2018)
	rename issuedate antiplateletdate

	tempfile drugissue_antiplatelet_`x'_`y'
	save `drugissue_antiplatelet_`x'_`y'', replace
	}
	}

forvalues x=1/9 {	
use `drugissue_antiplatelet_`x'_1', clear
forvalues y=2/6 {
	capture noisily append using `drugissue_antiplatelet_`x'_`y''
	}
	if _rc==111{
	continue
	}

duplicates drop
tempfile drugissue_antiplatelet_`x'
save `drugissue_antiplatelet_`x'', replace
}

use `drugissue_antiplatelet_1', clear	
forvalues x=2/9 {
	append using `drugissue_antiplatelet_`x''
	}	
save "$intermediatedatadir\drugissue_antiplatelet.dta"

***ASSIGN IN DATASET
local denom StudyPop SensStudyPop
foreach pop of local denom {
	use "$datadir/`pop'", clear
	keep patid studystartdate 
	merge 1:m patid using $intermediatedatadir\drugissue_antiplatelet, keep(master match) nogen
	gen days_antiplatelet=antiplateletdate-studystartdate
	gen antiplateletin365days=1 if days_antiplatelet>-366 & days_antiplatelet<=0
	sort patid antiplateletin365days
	by patid: replace antiplateletin365days=antiplateletin365days[1]
	keep patid antiplatelet antiplateletin365days
	duplicates drop
	replace antiplatelet=. if antiplateletin365days!=1
	drop antiplateletin365days
	save "$datadir/`pop'_antiplatelet", replace
	}