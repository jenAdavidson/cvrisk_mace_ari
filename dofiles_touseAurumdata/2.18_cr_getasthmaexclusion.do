/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					04/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Patient_Denom_InclusionApplied.dta
						Raw Observation data extracts from CPRDFast
							
CODELISTS:				Asthma_Aurum_Mar20.dta

NEXT STEPS:				2.19_cr_getobesityexclusion.do

==============================================================================*/


*******************************
***APPLY EXCLUSIONS - ASTHMA***
*******************************

***OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\Asthma_Aurum_Mar20.dta", keep(match) nogen
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid obsdate
	by patid: egen asthmadate=min(obsdate) 
	format asthmadate %td
	drop if asthmadate>d(31aug2018)
	
	sort patid obsdate
	by patid: egen asthmahospdate=min(obsdate) if asthmahosp==1
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
	
	tempfile observation_Asthma_`x'_`y'
	save `observation_Asthma_`x'_`y'', replace
	}
	}

forvalues x=1/9 {	
use `observation_Asthma_`x'_1', clear
	forvalues y=2/10 {
	capture noisily append using `observation_Asthma_`x'_`y''
	}
	if _rc==111{
	continue
	}

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
	tempfile observation_asthma_`x'
	save `observation_asthma_`x'', replace
	}

use `observation_asthma_1', clear
forvalues x=2/9 {
	append using `observation_asthma_`x''
	}
	
save "$intermediatedatadir\observation_Asthma.dta"


***DRUG ISSUE

forvalues x=1/9 {
forvalues y=1/6 {
	capture noisily use "$rawdatadir\ari_cvd_extract_drugissue_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 prodcodeid using "$codelistdir\AsthmaProdcodes_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	drop if asthma_steroid!=1
	keep patid issuedate asthma_steroid
	duplicates drop
	
	*DROP IF BEYOND STUDY PERIOD END
	drop if issuedate>d(31aug2018)
	rename issuedate asthmasteroiddate
	
	tempfile drugissue_Asthma_`x'_`y'
	save `drugissue_Asthma_`x'_`y'', replace
	}
	}

forvalues x=1/9 {	
use `drugissue_Asthma_`x'_1', clear
forvalues y=2/6 {
	capture noisily append using `drugissue_Asthma_`x'_`y''
	}
	if _rc==111{
	continue
	}

duplicates drop
sort patid
by patid: gen asthmasteroid_n=_n
by patid: gen asthmasteroid_N=_N
drop if asthmasteroid_N==1

tempfile drugissue_asthma_`x'
save `drugissue_asthma_`x'', replace
}

use `drugissue_asthma_1', clear	
forvalues x=2/9 {
	append using `drugissue_asthma_`x''
	}	


save "$intermediatedatadir\drugissue_Asthma.dta"