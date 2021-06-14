/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					17/03/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population from denominator file by 
						applying inclusion criteria for objectives 1-3 (part 1)

DATASETS USED:			CPRD Gold July 2020 denominator patient file Jul 2019
						CPRD Gold July 2020 denominator practice file Jul 2019
						CPRD Gold linkage eligibility file set 18
							
CODELISTS:				None
							
DATASETS CREATED:		Patient_Denom_Inclusion.dta 
						(acceptable, linkable patients meeting date & age criteria)
						results_ari_cvd.dta
						(as above but only patid)
						
NEXT STEPS:				2.1_cr_getcvdexclusion.do

==============================================================================*/

******************************************************
***USE DENOMINATOR FILE TO APPLY INCLUSION CRITERIA***
******************************************************

**OPEN DENOMINATOR FILES**
use "$denomcprddir\allpatients_JUL2020.dta", clear
gen pracid=mod(patid,1000)
sort pracid
merge m:1 pracid using "$denomcprddir\allpractices_JUL2020.dta", nogen
unique patid // 21,708,314

**MERGE WITH LINKAGE FILE**
merge m:1 patid using "$denomhesdir\linkage_eligibility.dta"
drop if _merge==2
drop _merge
unique patid // 21,708,314
drop _merge

**KEEP ACCEPTABLE QUALITY PATIENTS**
drop if accept==0 // 2,689,528 patients removed
unique patid //  19,018,786

**KEEP HES LINKAGE ELIGIBLE PATIENTS**
drop if hes!=1 // 10,794,794 patients removed
unique patid // 8,223,992

**CREATE AGE VARIABLE**
gen day=1
gen mob2=mob
replace mob2=7 if mob==0
gen dob=mdy(mob2, day, yob)
format dob %td
gen birthday40 = dob + 40*365.25
format birthday40 %td
gen birthday65 = dob + 65*365.25
format birthday65 %td

**KEEP PATIENTS IN AGE GROUP OF INTEREST**
**Drop if not aged 40-64 between 01/09/2008 & 31/08/2018
br if birthday65<=d(01/09/2008)
drop if birthday65<=d(01/09/2008) // 1,303,650 patients removed
br if birthday40>=d(31/08/2018)
drop if birthday40>=d(31/08/2018) // 3,361,091 patients removed

unique patid // 3,559,251

**KEEP PATIENTS IN FOLLOW UP DURING STUDY END**
**Calculate patient start dates from dataset variables
gen crd2=date(crd, "DMY")
format crd2 %td
drop crd
rename crd2 crd
gen crd12m = crd + 365.25
format crd12m %td
lab var crd12m "12 months after crd"

gen uts2=date(uts, "DMY")
format uts2 %td
drop uts
rename uts2 uts
gen startdate = max(crd12m, uts)
format startdate %td
lab var startdate "Latest of CRD 12M + UTS"

**Drop if not aged 40-64 at start of follow up date
drop if birthday65<=startdate // 77,675 patients removed
unique patid // 3,481,576

**Calculate patient end date from dataset variables
gen lcd2=date(lcd, "DMY")
format lcd2 %td
drop lcd
rename lcd2 lcd
gen tod2=date(tod, "DMY")
format tod2 %td
drop tod
rename tod2 tod
gen deathdate2=date(deathdate, "DMY")
format deathdate2 %td
drop deathdate
rename deathdate2 deathdate
gen enddate=min(lcd, tod, deathdate)
format enddate %td
lab var enddate "Earliest of LCD, TOD & DOD"

**Drop if aged <40 at end of follow up dates
drop if birthday40>=enddate // 1,221,122 patients removed
unique patid // 2,260,454

**Drop if end of follow up date <01/09/2008
br if enddate <=d(01/09/2008)
drop if enddate <=d(01/09/2008) // 443,674 patients removed
unique patid // 1,816,780

**Drop if start date >31/08/2018
br if startdate >=d(31/08/2018)
drop if startdate >=d(31/08/2018) // 66,619 patients removed
unique patid // 1,750,161

**Drop if start date after end date
br if startdate>=enddate
drop if startdate>=enddate // 105,627 patients removed
unique patid // 1,644,534

**Calculate patient start follow up date
gen studystartdate=max(startdate, birthday40, d(01/09/2008))
format studystartdate %td

**Identify practices which are also in Aurum dataset
rename pracid gold_pracid
merge m:1 gold_pracid using "J:\EHR Share\3 Database guidelines and info\CPRD Aurum\Vision to Emis Migrators\202007VisionToEmisMigrators.dta"
keep if _merge==1
rename gold_pracid pracid
unique patid // 1,000,139

**SAVE DATASETS**
save "$intermediatedatadir\Denom_Inclusion.dta", replace

keep patid
save "$dataextractdir\results_ari_cvd.dta", replace

/*db cprdfast
rungprddlg, define(0) extract(1) build(July 2020) directory(Z:\GPRD_GOLD\Jennifer\ARI_CVcomplications\Gold\Part1\Define) studyname(ari_cvd_part1) memorytoassign(16g)*/