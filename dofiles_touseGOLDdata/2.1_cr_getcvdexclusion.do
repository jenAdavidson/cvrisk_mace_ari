/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					14/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Denominator_InclusionApplied.dta
						Raw Clinical & Referral data extracts from CPRDFast
							
CODELISTS:				ExistingCVD_Gold_Jul19.dta

NEXT STEPS:				2.2_cr_getliverdiseaseexclusion.do

==============================================================================*/


*************************************
***APPLY EXCLUSIONS - EXISTING CVD***
*************************************

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\ExistingCVD_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen cvddate=min(eventdate) 
format cvddate %td
drop if cvddate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid cvddate cvd

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop
unique patid // 94,801

save "$intermediatedatadir\Clinical_CVD.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\ExistingCVD_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen cvddate=min(eventdate) 
format cvddate %td
drop if cvddate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid cvddate cvd

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop
unique patid // 8,186

save "$intermediatedatadir\Referral_CVD.dta", replace

***COMBINE CLINICAL & REFERRAL
append using "$intermediatedatadir\Clinical_CVD.dta"

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid cvddate
duplicates drop patid, force
unique patid // 96,062

label variable cvddate "earliest CVD date for patient"

save "$intermediatedatadir\ClinicalReferral_CVD.dta", replace