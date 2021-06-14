/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					12/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify CPRD recorded outcomes objective 1-3 (part 1)

DATASETS USED:			Raw Clinical & Referral data extracts from CPRDFast

NEXT STEPS:				11.2_cr_getari_hes

==============================================================================*/

**********************************
***ACUTE RESPIRATORY INFECTIONS***
**********************************

///
***IDENTIFY EVENTS IN CLINICAL FILE

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\ARI_Gold_Jul19.dta", keep(match) nogen

*DROP DUPLCATES & RECORDS BEYOND STUDY PERIOD END
drop if eventdate>d(31aug2018)

keep patid eventdate ari ari_flu ari_pneumo
duplicates drop

tempfile ari
save `ari'

///
***IDENTIFIY EVENTS IN REFERRAL FILE

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\ARI_Gold_Jul19.dta", keep(match) nogen

*DROP DUPLCATES & RECORDS BEYOND STUDY PERIOD END
drop if eventdate>d(31aug2018)

keep patid eventdate ari ari_flu ari_pneumo
duplicates drop

///
***COMBINE CLINICAL & REFERRAL
append using `ari'

*DROP DUPLCATES FROM COMBINED FILE
duplicates drop

sort patid eventdate
rename eventdate aridate_cprd
rename ari ari_cprd
rename ari_flu ari_flu_cprd
rename ari_pneumo ari_pneumo_cprd

///
***SAVE MASTER COPY OF ALL MATCHES
save "$datadir\ari_cprd.dta", replace
