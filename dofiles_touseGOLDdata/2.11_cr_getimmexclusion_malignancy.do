/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					05/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Clinical & Referral data extracts from CPRDFast

CODELISTS:				HaematologicalMalignancies_Gold_Jul19.dta

NEXT STEPS:				2.12_cr_getimmexclusion_chemoradiotherapy.do

==============================================================================*/

*********************************
***HAEMATOLOGICAL MALIGNANCIES***
*********************************

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\HaematologicalMalignancies_Gold_Jul19.dta", keep(match) nogen

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate malignancy

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
count // 18,722
unique patid // 9,400

save "$intermediatedatadir\Clinical_HaematologicalMalignancies.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\HaematologicalMalignancies_Gold_Jul19.dta", keep(match) nogen

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate malignancy

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
count // 557
unique patid // 464

save "$intermediatedatadir\Referral_HaematologicalMalignancies.dta", replace

***COMBINE CLINICAL & REFERRAL

append using "$intermediatedatadir\Clinical_HaematologicalMalignancies.dta"

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
count // 19,032
unique patid // 9,440

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
by patid: egen malignancydate_earliest=min(eventdate) 
format malignancydate_earliest %td
rename eventdate malignancydate

*CREATE FLAGS FOR ORDER OF EVENT DATES & TOTAL NUMBER OF RECORDS PER PATIENT
by patid: gen malignancy_N=_N
by patid: gen malignancy_n=_n

save "$intermediatedatadir\ClinicalReferral_HaematologicalMalignancies.dta", replace