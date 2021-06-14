/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Clinical & Referral data extracts from CPRDFast

CODELISTS:				PermCMI_Gold_Jul19.dta

NEXT STEPS:				2.8_cr_getimmexclusion_othercmi.do

==============================================================================*/

*******************
***PERMANENT CMI***
*******************

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\PermCMI_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen permcmidate=min(eventdate) 
format permcmidate %td
drop if permcmidate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid permcmidate permcmi

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop
unique patid // 52

save "$intermediatedatadir\Clinical_PermCMI.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\PermCMI_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen permcmidate=min(eventdate) 
format permcmidate %td
drop if permcmidate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid permcmidate permcmi

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop
unique patid // 3

save "$intermediatedatadir\Referral_PermCMI.dta", replace

***COMBINE CLINICAL & REFERRAL

append using "$intermediatedatadir\Clinical_PermCMI.dta"

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid permcmidate
duplicates drop patid, force
unique patid // 54

label variable permcmidate "earliest permanent cellular immune def date"

save "$intermediatedatadir\ClinicalReferral_PermCMI.dta", replace