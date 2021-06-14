/*=========================================================================
AUTHOR:					Jennifer Davidson (edit of Rohini's do file for my study)
DATE:					05/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population covariates

DATASETS USED:			Denom_SensStudyPop.dta

NEXT STEPS:				8_getconsultations
						
*=========================================================================*/


/****************************************************************************
**CREATE FILE OF ALL ETHNICITY CODES IN CLINICAL FILE IN WHOLE CPRD POPULATION
*****************************************************************************/
use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\codelist_ethnicity_gold.dta", nogen keep(match)

keep patid eventdate sysdate eth16 eth5
replace eventdate=sysdate if eventdate==.
gsort patid -eventdate // keep earliest record for any duplicates
duplicates report patid eth5
duplicates drop patid eth5, force 

bysort patid (eth5 eth16): gen n1=_n
by patid: drop if n1>1 & eth5==5 // prioritise non-"not stated" recording
bysort patid (eth5 eth16): gen n2=_n
by patid: drop if n2>1 & eth5==3 // prioritise non "other" recording
bysort patid (eth16 eth5): gen n3=_n
by patid: drop if n3>1 & eth16==16 // prioritise non "other" recording
drop n*

save "$datadir\ethnicity_cprd", replace

merge m:1 patid using "$datadir\ethnicity_hes", keepusing(heseth5 heseth16)
sort patid
duplicates tag patid, gen(dup1)
by patid: gen match1=1 if dup1>0 & eth16==heseth16 & eth5==heseth5
sort patid match1
by patid: replace match1=0 if dup1>0 & match1!=1
by patid: egen matchmax1=max(match1) if dup1>0 
drop if match1==0 & matchmax1==1 // prioritise record which matches HES

duplicates tag patid, gen(dup2)
by patid: gen match2=1 if dup2>0 & eth5==heseth5
sort patid match2
by patid: replace match2=0 if dup2>0 & match2!=1
by patid: egen matchmax2=max(match2) if dup2>0 
drop if match2==0 & matchmax2==1

duplicates tag patid eth5, gen(dupeth5)
assert dupeth5==0 // no remaining duplicates have the same eth5 recorded more than once
gsort patid -eventdate // no other way to prioritise so keep latest
duplicates drop patid, force

gen ethnicity_source=0
replace ethnicity_source=1 if heseth5!=. & eth5==. 
replace ethnicity_source=1 if (heseth5!=. & heseth5!=5) & (eth5==. | eth5==5)
label define ethnicity_source 0"CPRD" 1"HES"
label values ethnicity_source ethnicity_source

replace eth5=heseth5 if (eth5==. | eth5==5) & heseth5!=.
replace eth16=heseth16 if (eth16==. | eth16==17) & heseth16<18

merge 1:1 patid using "$datadir\SensStudyPop", nogen keep(match) keepusing(patid)

keep patid eth16 eth5 ethnicity_source

save "$datadir\ethnicity_final", replace