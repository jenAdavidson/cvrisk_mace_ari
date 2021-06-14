/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					23/06/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify CPRD recorded outcomes objective 1-3 (part 1)

DATASETS USED:			ARI CPRD & HES

NEXT STEPS:				11.4_cr_flagari

==============================================================================*/

**********************************
***ACUTE RESPIRATORY INFECTIONS***
**********************************

///
***COMBINE CPRD & HES EPISODES

use $datadir\ari_cprd, clear
append using $datadir\ari_hes

gen aridate=aridate_cprd
replace aridate=aridate_hes if aridate==.
format aridate %td

gen ari=1
gen ari_flu=1 if ari_flu_cprd==1 | ari_flu_hes==1 
gen ari_pneumo=1 if ari_pneumo_cprd==1 | ari_pneumo_hes==1

drop *cprd *hes

foreach var of varlist ari ari_flu ari_pneumo {
	
	sort patid `var' aridate
	by patid: gen `var'_n=_n if `var'==1
	by patid: gen time`var'=aridate-aridate[_n-1] if `var'==1
	by patid: replace `var'_n=`var'_n[`var'_n-1] if time`var'<=28 & `var'==1
	
	sort patid `var'_n
	by patid `var'_n: egen `var'dateend=max(aridate) if `var'==1
	format `var'dateend %td
	drop time`var'
	}

*EXTRA CODING FOR FLU TO MAKE EPI RECOGNISED FROM FIRST ARI CONS DATE
sort patid ari_n ari_flu_n	
by patid ari_n: egen ari_flu_n1=max(ari_flu_n)
drop ari_flu_n
rename ari_flu_n1 ari_flu_n
replace ari_fludateend=aridateend if ari_flu_n!=.
sort patid ari_flu_n ari_fludateend
by patid ari_flu_n: egen ari_fludateend1=min(ari_fludateend)
format ari_fludateend1 %td
drop ari_fludateend
rename ari_fludateend1 ari_fludateend
	
foreach var of varlist ari ari_flu ari_pneumo {

	preserve
	keep if `var'==1
	keep patid aridate `var' `var'_n `var'dateend
	sort patid aridate
	duplicates drop patid `var'_n, force
	drop `var'_n 

	save `var'episodes, replace
	restore
	}


**NOTED TRIED TO CREATE A MASTER DATASET WITH ALL ARI & SECONDARY OUTCOMES IN BUT CODING DIDN'T WORK
