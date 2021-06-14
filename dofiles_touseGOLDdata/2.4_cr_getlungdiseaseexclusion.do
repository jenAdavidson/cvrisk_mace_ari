/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Clinical & Referral data extracts from CPRDFast

CODELISTS:				LungDisease_Gold_Jul19.dta

NEXT STEPS:				2.5_cr_getimmexclusion_hiv.do

==============================================================================*/

**************************
***CHRONIC LUNG DISEASE***
**************************

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\LungDisease_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen lungdate=min(eventdate) 
format lungdate %td
drop if lungdate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid lungdate lung

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop
unique patid // 51,361

save "$intermediatedatadir\Clinical_Lung.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\LungDisease_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen lungdate=min(eventdate) 
format lungdate %td
drop if lungdate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid lungdate lung

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop
unique patid // 2,784

save "$intermediatedatadir\Referral_Lung.dta", replace

***COMBINE CLINICAL & REFERRAL

append using "$intermediatedatadir\Clinical_Lung.dta"

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid lungdate
duplicates drop patid, force
unique patid // 51,594

label variable lungdate "earliest chr lung dis date"

save "$intermediatedatadir\ClinicalReferral_Lung.dta", replace