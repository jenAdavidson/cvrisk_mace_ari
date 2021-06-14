/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Clinical & Referral data extracts from CPRDFast

CODELISTS:				Spleen_Gold_Jul19.dta

NEXT STEPS:				2.4_cr_getlungdiseaseexclusion.do

==============================================================================*/

***********************************
***ASPLENIA / SPLEEN DYSFUNCTION***
***********************************

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\Spleen_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen spleendate=min(eventdate) 
format spleendate %td
drop if spleendate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid spleendate spleen

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop
unique patid // 10,359

save "$intermediatedatadir\Clinical_Spleen.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\Spleen_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen spleendate=min(eventdate) 
format spleendate %td
drop if spleendate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid spleendate spleen

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop
unique patid // 906

save "$intermediatedatadir\Referral_Spleen.dta", replace

***COMBINE CLINICAL & REFERRAL

append using "$intermediatedatadir\Clinical_Spleen.dta"

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid spleendate
duplicates drop patid, force
unique patid // 10,541

label variable spleendate "earliest spleen dysfun date"

save "$intermediatedatadir\ClinicalReferral_Spleen.dta", replace