/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Clinical & Referral data extracts from CPRDFast

CODELISTS:				ChemoRadioTherapy_Gold_Jul19.dta

NEXT STEPS:				2.13_cr_getimmexclusion_immunosuppressants.do

==============================================================================*/

*********************************
***CHEMOTHERAPY & RADIOTHERAPY***
*********************************

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\ChemoRadioTherapy_Gold_Jul19.dta", keep(match) nogen

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate chemoradio

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
count // 46,001
unique patid // 24,818

save "$intermediatedatadir\Clinical_ChemoRadioTherapy.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\ChemoRadioTherapy_Gold_Jul19.dta", keep(match) nogen

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate chemoradio

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
count // 1,231
unique patid // 909

save "$intermediatedatadir\Referral_ChemoRadioTherapy.dta", replace

***COMBINE CLINICAL & REFERRAL

append using "$intermediatedatadir\Clinical_ChemoRadioTherapy.dta"

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
count // 46,985
unique patid // 25,543

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
by patid: egen chemoradiodate_earliest=min(eventdate) 
format chemoradiodate_earliest %td
rename eventdate chemoradiodate

*CREATE FLAGS FOR ORDER OF EVENT DATES & TOTAL NUMBER OF RECORDS PER PATIENT
by patid: gen chemoradio_N=_N
by patid: gen chemoradio_n=_n

save "$intermediatedatadir\ClinicalReferral_ChemoRadioTherapy.dta", replace