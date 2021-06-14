/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Clinical, Referral & Therapy data extracts from CPRDFast
							
==============================================================================*/

************
***ASTHMA***
************

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\Asthma_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen asthmadate=min(eventdate) 
format asthmadate %td
drop if asthmadate>d(31aug2018)

sort patid eventdate
by patid: egen asthmahospdate=min(eventdate) if asthmahosp==1
format asthmahospdate %td
sort patid asthmahospdate
by patid: replace asthmahospdate=asthmahospdate[1]
replace asthmahosp=. if asthmahospdate>d(31aug2018)
replace asthmahospdate=. if asthmahospdate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid asthmadate asthma asthmahosp asthmahospdate

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid asthmahosp
duplicates drop patid, force
unique patid // 212,880

save "$intermediatedatadir\Clinical_Asthma.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\Asthma_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen asthmadate=min(eventdate) 
format asthmadate %td
drop if asthmadate>d(31aug2018)

sort patid eventdate
by patid: egen asthmahospdate=min(eventdate) if asthmahosp==1
format asthmahospdate %td
sort patid asthmahospdate
by patid: replace asthmahospdate=asthmahospdate[1]
replace asthmahosp=. if asthmahospdate>d(31aug2018)
replace asthmahospdate=. if asthmahospdate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid asthmadate asthma asthmahosp asthmahospdate

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid asthmahosp
duplicates drop patid, force
unique patid // 4,805

save "$intermediatedatadir\Referral_Asthma.dta", replace

***COMBINE CLINICAL & REFERRAL

append using "$intermediatedatadir\Clinical_Asthma.dta"

*CREATE EARLIEST DATE FOR ANY DIAG AGAIN AS THERE MAY BE DIFFERENT COMBINATIONS OF DATA BETWEEN CLINICAL & REFERRAL
sort patid asthmadate
by patid: egen asthmadate1=min(asthmadate)
format asthmadate1 %td
sort patid asthmahospdate
by patid: egen asthmahospdate1=min(asthmahospdate)
format asthmahospdate1 %td

drop asthmadate asthmahospdate
rename asthmadate1 asthmadate
rename asthmahospdate1 asthmahospdate

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid asthmahosp
duplicates drop patid, force
unique patid // 212,929

label variable asthmadate "earliest asthma date"
label variable asthmahospdate "earliest asthma admission date"

save "$intermediatedatadir\ClinicalReferral_Asthma.dta", replace

***THERAPY

*COMBINE DATASETS
use "$rawdatadir\Therapy_extract_ari_cvd_1.dta", clear
drop sysdate consid staffid dosageid qty numdays numpacks packtype issueseq
append using "$rawdatadir\Therapy_extract_ari_cvd_2.dta"
drop sysdate consid staffid dosageid qty numdays numpacks packtype issueseq
merge m:1 prodcode using "$codelistdir\AsthmaProdcodes_Gold_Jul19.dta", keep(match) nogen

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
drop if asthma_steroid!=1
keep patid eventdate asthma_steroid

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
count // 10,462,926
unique patid // 375,445

*CREATE EARLIEST DATE FOR ANY TX & DROP IF BEYOND STUDY PERIOD END
by patid: egen asthmasteroiddate_earliest=min(eventdate) 
format asthmasteroiddate_earliest %td
rename eventdate asthmasteroiddate

*CREATE FLAGS FOR ORDER OF EVENT DATES & TOTAL NUMBER OF RECORDS PER PATIENT
by patid: gen asthmasteroid_N=_N
by patid: gen asthmasteroid_n=_n

*ONLY KEEP RECORDS FOR PATIENTS IF HAVE 2+ PRESCRIPTIONS
drop if asthmasteroid_N==1 
count // 2,870,115
unique patid // 146,455

save "$intermediatedatadir\Therapy_Asthma.dta", replace