/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Clinical & Referral data extracts from CPRDFast

CODELISTS:				AplasticAnaemia_Gold_Jul19.dta

NEXT STEPS:				2.10_cr_getimmexclusion_bonemarrowstemcell.do


==============================================================================*/

**********************
***APLASTIC ANAEMIA***
**********************

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\AplasticAnaemia_Gold_Jul19.dta", keep(match) nogen

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate aplastic

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
count // 309
unique patid // 147

save "$intermediatedatadir\Clinical_AplasticAnaemia.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\AplasticAnaemia_Gold_Jul19.dta", keep(match) nogen

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate aplastic

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
count // 51
unique patid // 14

save "$intermediatedatadir\Referral_AplasticAnaemia.dta", replace

***COMBINE CLINICAL & REFERRAL

append using "$intermediatedatadir\Clinical_AplasticAnaemia.dta"

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
count // 316
unique patid // 148

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
by patid: egen aplasticdate_earliest=min(eventdate) 
format aplasticdate_earliest %td
rename eventdate aplasticdate

*CREATE FLAGS FOR ORDER OF EVENT DATES & TOTAL NUMBER OF RECORDS PER PATIENT
by patid: gen aplastic_N=_N
by patid: gen aplastic_n=_n

save "$intermediatedatadir\ClinicalReferral_AplasticAnaemia.dta", replace