/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					01/10/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				covariate analysis
							
CODELISTS:				AtrialFibrillation_Gold_Jul19.dta
						cr_codelist_statins.dta
						cr_codelist_antihypertensives.dta

NEXT STEPS:				10_cr_getcvrisk.do

==============================================================================*/

*******ATRIAL FIBRILLATION*******

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\AtrialFibrillation_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen atrialfibdate=min(eventdate) 
format atrialfibdate %td
drop if atrialfibdate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid atrialfibdate atrialfib

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop
unique patid 

save "$intermediatedatadir\Clinical_AF.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\AtrialFibrillation_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen atrialfibdate=min(eventdate) 
format atrialfibdate %td
drop if atrialfibdate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid atrialfibdate atrialfib

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop
unique patid 

save "$intermediatedatadir\Referral_AF.dta", replace

***COMBINE CLINICAL & REFERRAL
append using "$intermediatedatadir\Clinical_AF.dta"

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid atrialfibdate
duplicates drop patid, force
unique patid 

label variable atrialfibdate "earliest AF date for patient"

save "$intermediatedatadir\ClinicalReferral_AF.dta", replace

***ASSIGN IN DATASET
local denom StudyPop SensStudyPop
foreach pop of local denom {
	use `pop', clear
	keep patid studystartdate 
	merge 1:1 patid using $intermediatedatadir\ClinicalReferral_AF, keep(master match) nogen
	replace atrialfib=0 if atrialfibdate==. | atrialfibdate>studystartdate
	save "$datadir/`pop'_atrialfib", replace
	}


*******ANTI-HYPERTENSIVES*******

***THERAPY

use "$rawdatadir\Therapy_extract_ari_cvd_combined.dta", clear
merge m:1 prodcode using "$codelistdir\cr_codelist_antihypertensives.dta", keep(match) keepusing(prodcode) nogen force

gen antihypertens=1

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate antihypertens

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
rename eventdate antihypertensdate

save "$intermediatedatadir\Therapy_antihypertens.dta", replace

***ASSIGN IN DATASET
local denom StudyPop SensStudyPop
foreach pop of local denom {
	use `pop', clear
	keep patid studystartdate 
	merge 1:m patid using $intermediatedatadir\Therapy_antihypertens, keep(master match) nogen
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

***THERAPY

use "$rawdatadir\Therapy_extract_ari_cvd_combined.dta", clear
merge m:1 prodcode using "$codelistdir\cr_codelist_statins.dta", keep(match) keepusing(prodcode) nogen force

gen statins=1

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate statins

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
rename eventdate statinsdate

save "$intermediatedatadir\Therapy_statins.dta", replace

***ASSIGN IN DATASET
local denom StudyPop SensStudyPop
foreach pop of local denom {
	use `pop', clear
	keep patid studystartdate 
	merge 1:m patid using $intermediatedatadir\Therapy_statins, keep(master match) nogen
	gen days_statins=statinsdate-studystartdate
	gen statinsin365days=1 if days_statins>-366 & days_statins<=0
	sort patid statinsin365days
	by patid: replace statinsin365days=statinsin365days[1]
	keep patid statin statinsin365days
	duplicates drop
	replace statins=. if statinsin365days!=1
	drop statinsin365days
	save "$datadir/`pop'_statins", replace
	}
	
*******ANTIVIRALS*******

***THERAPY

use "$rawdatadir\Therapy_extract_ari_cvd_combined.dta", clear
merge m:1 prodcode using "$codelistdir\Antivirals_Jan_2019_hf.dta", keep(match) nogen

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate antiviral

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
rename eventdate antiviraldate

save "$intermediatedatadir\Therapy_antiviral.dta", replace

***ASSIGN IN DATASET
local denom StudyPop SensStudyPop
foreach pop of local denom {
	use `pop', clear
	keep patid studystartdate 
	merge 1:m patid using $intermediatedatadir\Therapy_antiviral, keep(master match) nogen
		save "$datadir/`pop'_antivirals", replace
	}
	

*******ANTIPLATELETS*******

***THERAPY

use "$rawdatadir\Therapy_extract_ari_cvd_combined.dta", clear
merge m:1 prodcode using "$codelistdir\antiplatelets.dta", keep(match) keepusing(prodcode) nogen

gen antiplatelet=1

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate antiplatelet

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
rename eventdate antiplateletdate

save "$intermediatedatadir\Therapy_antiplatelet.dta", replace

***ASSIGN IN DATASET
local denom StudyPop SensStudyPop
foreach pop of local denom {
	use `pop', clear
	keep patid studystartdate 
	merge 1:m patid using $intermediatedatadir\Therapy_antiplatelet, keep(master match) nogen
	gen days_antiplatelet=antiplateletdate-studystartdate
	gen antiplatelet365days=1 if days_antiplatelet>-366 & days_antiplatelet<=0
	sort patid antiplatelet365days
	by patid: replace antiplatelet365days=antiplatelet365days[1]
	keep patid antiplatelet antiplatelet365days
	duplicates drop
	replace antiplatelet=. if antiplatelet365days!=1
	drop antiplatelet365days
	save "$datadir/`pop'_antiplatelet", replace
	}