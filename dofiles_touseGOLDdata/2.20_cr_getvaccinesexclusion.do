/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					05/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & exclusion criteria			
						for objective 1-3 (part 1)

DATASETS:			Denominator_InclusionApplied.dta
						Raw data extracts from CPRDFast
							
CODELISTS:				PPV_medcodes_Gold_Jul19
						PPV_prodcodes_Gold_Jul19
						FluVac_medcodes_Gold_Jul19
						FluVac_prodcodes_Gold_Jul19

NEXT STEPS:				3.1_cr_flagexclusions.do

==============================================================================*/

**********************************
***ANY PNEUMOCOCCAL VACCINATION***
**********************************

***CLINICAL
use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear

merge m:1 medcode using "$codelistdir\PPV_medcodes_Gold_Jul19.dta", keep(match) nogen

*DROP IF EVENT DATE BEYOND STUDY PERIOD END
sort patid eventdate
drop if eventdate>d(31aug2018)

count // 46,304
unique patid // 40,271

save "$intermediatedatadir\Clinical_PPV.dta", replace

***REFERRAL
use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear

merge m:1 medcode using "$codelistdir\PPV_medcodes_Gold_Jul19.dta", keep(match) nogen

*DROP IF EVENT DATE BEYOND STUDY PERIOD END
sort patid eventdate
drop if eventdate>d(31aug2018)

count // 57
unique patid // 57

save "$intermediatedatadir\Referral_PPV.dta", replace

***COMBINE CLINICAL & REFERRAL
append using "$intermediatedatadir\Clinical_PPV.dta"
sort patid eventdate

*REMOVE DUPLICATES
keep patid eventdate PPV_vac PPV_given PPV_neutral PPV_declined PPV_contraindic PPV_consent PPV_date_unclear
duplicates drop

*REFORMAT BY EVENTDATE
gen patcount=1
collapse (max) PPV_vac PPV_given PPV_neutral PPV_declined PPV_contraindic PPV_consent PPV_date_unclear (count) patcount, by(patid eventdate)

count // 45,995
unique patid // 40,316
save "$intermediatedatadir\ClinicalReferral_PPV.dta", replace

***IMMUNISATION
use "$rawdatadir\Immunisation_extract_ari_cvd_1.dta", clear

sort patid eventdate

keep if immstype==13 | immstype==28
drop if status==9

*DROP IF EVENT DATE BEYOND STUDY PERIOD END
drop if eventdate>d(31aug2018)

keep patid eventdate status
gen ppv_imms=1
duplicates drop

count // 268,120
unique patid // 253,713

save "$intermediatedatadir\Immunisation_PPV.dta", replace

***THERAPY

*COMBINE DATASETS
use "$rawdatadir\Therapy_extract_ari_cvd_1.dta", clear
drop sysdate consid staffid dosageid qty numdays numpacks packtype issueseq
append using "$rawdatadir\Therapy_extract_ari_cvd_2.dta"
drop sysdate consid staffid dosageid qty numdays numpacks packtype issueseq

merge m:1 prodcode using "$codelistdir\PPV_prodcodes_Gold_Jul19.dta", keep(match) nogen

*DROP IF EVENT DATE BEYOND STUDY PERIOD END
drop if eventdate>d(31aug2018)

keep patid eventdate ppvprod
duplicates drop

count // 77,164
unique patid // 74,597

save "$intermediatedatadir\Therapy_PPV.dta", replace 

***CLINCAL, REFERRAL, IMMUNISATION & THERAPY
merge m:m patid eventdate using "$intermediatedatadir\ClinicalReferral_PPV.dta", nogen
merge m:m patid eventdate using "$intermediatedatadir\Immunisation_PPV.dta", nogen

*REMOVE RECORDS IF ONLY HAVE DECLINE OR CONTRAINDICATED FLAG 
drop if PPV_declined==1 & ppvprod==. & PPV_given==. & PPV_date_unclear==. & status!=1
drop if status==4 & ppvprod==. & PPV_given==. & PPV_date_unclear==.
drop if PPV_contraindic==1 & ppvprod==. & PPV_given==. & PPV_date_unclear==. & status!=1

*FLAG RECORDS WITH CONFLICTS
gen ppvconflict=1 if PPV_declined==1 & (PPV_given==1 | ppvprod==1 | status==1)
replace ppvconflict=1 if status==4 & (PPV_given==1 | ppvprod==1)

*KEEP EARLIEST RECORD
sort patid eventdate
duplicates drop patid, force

rename eventdate ppvdate
gen ppvvacc=1
keep patid ppvdate ppvvacc ppvconflict

*RENAME VARIABLES FOR LOOPS TO WORK
rename ppvdate ppvvaccdate
rename ppvconflict ppvvaccconflict

unique patid // 245,320

save "$intermediatedatadir\ClinicalReferralImmunisationTherapy_PPV.dta", replace


**********************************************************
***INFLUENZA VACCINATION IN 12 MONTHS PRIOR TO BASELINE***
**********************************************************

***CLINICAL
use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear

merge m:1 medcode using "$codelistdir\FluVac_medcodes_Gold_Jul19.dta", keep(match) nogen

*DROP IF EVENT DATE BEYOND STUDY PERIOD END
sort patid eventdate
drop if eventdate>d(31aug2018)

count // 701,474
unique patid // 275,139

save "$intermediatedatadir\Clinical_FluVac.dta", replace

***REFERRAL
use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear

merge m:1 medcode using "$codelistdir\FluVac_medcodes_Gold_Jul19.dta", keep(match) nogen

*DROP IF EVENT DATE BEYOND STUDY PERIOD END
sort patid eventdate
drop if eventdate>d(31aug2018)

count // 45
unique patid // 45

save "$intermediatedatadir\Referral_FluVac.dta", replace

***COMBINE CLINICAL & REFERRAL
append using "$intermediatedatadir\Clinical_FluVac.dta"
sort patid eventdate

*REMOVE DUPLICATES
keep patid eventdate flu_vacc flu_given flu_neutral flu_declined flu_contraindic flu_consent
duplicates drop

*REFORMAT BY EVENTDATE
gen patcount=1
collapse (max) flu_vacc flu_given flu_neutral flu_declined flu_contraindic flu_consent (count) patcount, by(patid eventdate)

count // 681,270
unique patid // 275,162
save "$intermediatedatadir\ClinicalReferral_FluVac.dta", replace

***IMMUNISATION
use "$rawdatadir\Immunisation_extract_ari_cvd_1.dta", clear

keep if immstype==4 | immstype==71 | immstype==72 | immstype==73 | immstype==74 | immstype==75 | immstype==76 | immstype==78 | immstype==84 | immstype==85 | immstype==89 | immstype==97 | immstype==100
drop if status==9

*DROP IF EVENT DATE BEYOND STUDY PERIOD END
drop if eventdate>d(31aug2018)

keep patid eventdate status
gen fluvac_imms=1
duplicates drop

count // 2,935,396
unique patid // 562,667
save "$intermediatedatadir\Immunisation_FluVac.dta", replace

***THERAPY
*COMBINE DATASETS
use "$rawdatadir\Therapy_extract_ari_cvd_1.dta", clear
drop sysdate consid staffid dosageid qty numdays numpacks packtype issueseq
append using "$rawdatadir\Therapy_extract_ari_cvd_2.dta"
drop sysdate consid staffid dosageid qty numdays numpacks packtype issueseq

merge m:1 prodcode using "$codelistdir\FluVac_prodcodes_Gold_Jul19.dta", keep(match) nogen

*DROP IF EVENT DATE BEYOND STUDY PERIOD END
drop if eventdate>d(31aug2018)

keep patid eventdate fluvacprod
duplicates drop

count // 690,752
unique patid // 166,256

save "$intermediatedatadir\Therapy_FluVac.dta", replace

***CLINCAL, REFERRAL, IMMUNISATION & THERAPY
merge m:m patid eventdate using "$intermediatedatadir\ClinicalReferral_FluVac.dta", nogen
merge m:m patid eventdate using "$intermediatedatadir\Immunisation_FluVac.dta", nogen

*REMOVE RECORDS IF ONLY HAVE DECLINE OR CONTRAINDICATED FLAG 
drop if flu_declined==1 & fluvacprod==. & flu_given==. & status!=1
drop if status==4 & fluvacprod==. & flu_given==.
drop if flu_contraindic==1 & fluvacprod==. & flu_given==. & status!=1

*FLAG RECORDS WITH CONFLICTS
gen fluconflict=1 if flu_declined==1 & (flu_given==1 | fluvacprod==1 | status==1)
replace fluconflict=1 if status==4 & (flu_given==1 | fluvacprod==1)

rename eventdate fluvaccdate
gen fluvacc=1
keep patid fluvaccdate fluvacc fluconflict

count // 2,975485
unique patid // 544,539
sort patid fluvaccdate
by patid: gen fluvacc_n=_n

save "$intermediatedatadir\ClinicalReferralImmunisationTherapy_FluVac.dta", replace