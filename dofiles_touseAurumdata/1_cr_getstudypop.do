/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					17/03/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population from denominator file by applying inclusion 
						criteria for objectives 1-3 (part 1)

DATASETS USED:			CPRD Aurum JUL 2020 denominator patient file
						CPRD Aurum JUL 2020 denominator practice file 
						CPRD Aurum linkage eligibility file set 18
							
CODELISTS:				None
							
DATASETS CREATED:		Denom_Inclusion.dta 
						(acceptable, linkable patients meeting date & age criteria)
						results_ari_cvd.dta
						(as above but only patid)
						
NEXT STEPS:				2.1_cr_getcvdexclusion.do

==============================================================================*/

******************************************************
***USE DENOMINATOR FILE TO APPLY INCLUSION CRITERIA***
******************************************************

**OPEN DENOMINATOR FILES**
use "$denomcprddir\202007_CPRDAurum_AcceptablePats.dta", clear
sort pracid
merge m:1 pracid using "$denomcprddir\202007_CPRDAurum_Practices.dta", nogen

unique patid // 35,961,474

**MERGE WITH LINKAGE FILE**
merge m:1 patid using "$denomhesdir\linkage_eligibility.dta", force
drop if _merge==2 | _merge==1
drop _merge
unique patid // 23,244,467

**KEEP HES LINKAGE ELIGIBLE PATIENTS**
drop if hes_e!=1 // 1,992,372 patients removed
unique patid // 21,252,095

**CREATE AGE VARIABLE**
gen day=1
gen mob2=mob
replace mob2=7 if mob==.
gen dob=mdy(mob2, day, yob)
format dob %td
gen birthday40 = dob + 40*365.25
format birthday40 %td
gen birthday65 = dob + 65*365.25
format birthday65 %td

**KEEP PATIENTS IN AGE GROUP OF INTEREST**
**Drop if not aged 40-64 between 01/09/2008 & 31/08/2018
br if birthday65<=d(01/09/2008)
drop if birthday65<=d(01/09/2008) // 2,793,421 patients  removed
unique patid // 18,458,674
br if birthday40>=d(31/08/2018) // had initiallly run with 2019 but linked data at time only available until June 2019, so after extraction rerun to drop 2019
drop if birthday40>=d(31/08/2018) // 10,067,378 patients removed
unique patid // 8,391,296

**KEEP PATIENTS IN FOLLOW UP DURING STUDY END**
**Calculate patient start dates from dataset variables
gen regstartdate2=date(regstartdate, "DMY")
format regstartdate2 %td
drop regstartdate
rename regstartdate2 regstartdate

gen crd12m = regstartdate + 365.25
format crd12m %td
lab var crd12m "12 months after crd"

**Drop if aged >65 at start of follow up date
drop if birthday65<=crd12m // 194,126 patients removed
unique patid // 8,197,170

**Calculate patient end date from dataset variables
gen lcd2=date(lcd, "DMY")
format lcd2 %td
drop lcd
rename lcd2 lcd
gen regenddate2=date(regenddate, "DMY")
format regenddate2 %td
drop regenddate
rename regenddate2 regenddate
gen cprd_ddate2=date(cprd_ddate, "DMY")
format cprd_ddate2 %td
drop cprd_ddate
rename cprd_ddate2 cprd_ddate
gen enddate=min(lcd, regenddate, cprd_ddate)
format enddate %td
lab var enddate "Earliest of LCD, TOD & DOD"

**Drop if aged <40 at end of follow up dates
drop if birthday40>=enddate // 2,495,687 patients removed 
unique patid // 5,701,483

**Drop if end of follow up date <01/09/2008
br if enddate <=d(01/09/2008)
drop if enddate <=d(01/09/2008) // 889,470 patients removed
unique patid // 4,812,013

**Drop if start date >31/08/2018
br if crd12m>=d(31/08/2018)
drop if crd12m>=d(31/08/2018) // 260,891 patients removed
unique patid // 4,551,122

**Drop if start date after end date
br if crd12m>=enddate
drop if crd12m>=enddate // 120,335 patients removed 
unique patid // 4,430,787

**Calculate patient start follow up date
gen studystartdate=max(crd12m, birthday40, d(01/09/2008))
format studystartdate %td

**SAVE DATASETS**
save "$intermediatedatadir\Denom_Inclusion.dta", replace 

**Create smaller datasets to be able to handle size of data - note these contain 2019 patients as well, these are removed when excluded patients are removed
gen i=_n

*1 to 500K
preserve
	keep if i<=499999
	count
	save "$dataextractdir\results_ari_cvd_batch1.dta", replace
	export delimited patid using "$dataextractdir\results_ari_cvd_batch1.txt", delimiter(tab) replace
restore

*500K to 1M
preserve
	keep if i>=500000 & i<=999999
	count
	save "$dataextractdir\results_ari_cvd_batch2.dta", replace
	export delimited patid using "$dataextractdir\results_ari_cvd_batch2.txt", delimiter(tab) replace
restore

*1M to 1.5M
preserve
	keep if i>=1000000 & i<=1499999
	count
	save "$dataextractdir\results_ari_cvd_batch3.dta", replace
	export delimited patid using "$dataextractdir\results_ari_cvd_batch3.txt", delimiter(tab) replace
restore

*1.5M to 2M
preserve
	keep if i>=1500000 & i<=1999999
	count
	save "$dataextractdir\results_ari_cvd_batch4.dta", replace
	export delimited patid using "$dataextractdir\results_ari_cvd_batch4.txt", delimiter(tab) replace
restore

*2M to 2.5M
preserve
	keep if i>=2000000 & i<=2499999
	count
	save "$dataextractdir\results_ari_cvd_batch5.dta", replace
	export delimited patid using "$dataextractdir\results_ari_cvd_batch5.txt", delimiter(tab) replace
restore

*2.5M to 3M
preserve
	keep if i>=2500000 & i<=2999999
	count
	save "$dataextractdir\results_ari_cvd_batch6.dta", replace
	export delimited patid using "$dataextractdir\results_ari_cvd_batch6.txt", delimiter(tab) replace
restore

*3M to 3.5M
preserve
	keep if i>=3000000 & i<=3499999
	count
	save "$dataextractdir\results_ari_cvd_batch7.dta", replace
	export delimited patid using "$dataextractdir\results_ari_cvd_batch7.txt", delimiter(tab) replace
restore

*3.5M to 4M
preserve
	keep if i>=3500000 & i<=4000000
	count
	save "$dataextractdir\results_ari_cvd_batch8.dta", replace
	export delimited patid using "$dataextractdir\results_ari_cvd_batch8.txt", delimiter(tab) replace
restore

*4M to 4.5M
preserve
	keep if i>=4000000 
	count
	save "$dataextractdir\results_ari_cvd_batch9.dta", replace
	export delimited patid using "$dataextractdir\results_ari_cvd_batch9.txt", delimiter(tab) replace
restore

