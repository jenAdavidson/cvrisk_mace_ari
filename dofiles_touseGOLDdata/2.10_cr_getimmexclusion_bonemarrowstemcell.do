/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Clinical & Referral data extracts from CPRDFast

CODELISTS:				BoneMarrowStemCell_Gold_Jul19.dta

NEXT STEPS:				2.11_cr_getimmexclusion_malignancy.do

==============================================================================*/

****************************
***BONE MARROW TRANSPLANT***
****************************

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\BoneMarrowStemCell_Gold_Jul19.dta", keep(match) nogen

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate bonemarrow

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
count // 993
unique patid // 716

save "$intermediatedatadir\Clinical_BoneMarrowStemCell.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\BoneMarrowStemCell_Gold_Jul19.dta", keep(match) nogen

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate bonemarrow

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
count // 10
unique patid // 8

save "$intermediatedatadir\Referral_BoneMarrowStemCell.dta", replace

***COMBINE CLINICAL & REFERRAL

append using "$intermediatedatadir\Clinical_BoneMarrowStemCell.dta"

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
by patid: egen bonemarrowdate_earliest=min(eventdate) 
format bonemarrowdate_earliest %td
drop if bonemarrowdate_earliest>d(31aug2018)
rename eventdate bonemarrowdate

count // 999
unique patid // 719

*CREATE FLAGS FOR ORDER OF EVENT DATES & TOTAL NUMBER OF RECORDS PER PATIENT
by patid: gen bonemarrow_N=_N
by patid: gen bonemarrow_n=_n

save "$intermediatedatadir\ClinicalReferral_BoneMarrowStemCell.dta", replace