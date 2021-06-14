/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Clinical & Referral data extracts from CPRDFast

==============================================================================*/

*************************************
***CHRONIC NEUROLOGICAL CONDITIONS***
*************************************

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\ChronicNeuroDiseaseWithDisabilites_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen neurodate=min(eventdate) 
format neurodate %td
drop if neurodate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid neurodate neuro

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop
unique patid // 33,726

save "$intermediatedatadir\Clinical_Neuro.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\ChronicNeuroDiseaseWithDisabilites_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen neurodate=min(eventdate) 
format neurodate %td
drop if neurodate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid neurodate neuro

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop
unique patid // 4,088

save "$intermediatedatadir\Referral_Neuro.dta", replace

***COMBINE CLINICAL & REFERRAL

append using "$intermediatedatadir\Clinical_Neuro.dta"

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid neurodate
duplicates drop patid, force
unique patid // 34,307

label variable neurodate "earliest chr neuro cond date"

save "$intermediatedatadir\ClinicalReferral_Neuro.dta", replace