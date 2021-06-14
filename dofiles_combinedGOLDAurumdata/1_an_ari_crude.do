///////////////////////////////////////
//ACUTE RESPIRATORY INFECTION OUTCOME//
///////////////////////////////////////


local cvrisk hypertens qrisk 
local outcome ari ari_pneumo ari_flu
local denom StudyPop SensStudyPop
foreach pop of local denom {
foreach cond of local outcome {
foreach risk of local cvrisk {

use "$golddir/`pop'_`cond'_poisson", clear
merge m:1 patid using "$golddir/`pop'_`risk'", keepusing(`risk'date b`risk') nogen
tostring patid, replace
gen patid2=patid+"G"
save "$datadir/`pop'_`cond'_`risk'_poisson_gold", replace

use "$aurumdir/`pop'", clear
merge 1:m patid using "$aurumdir/`pop'_`cond'_poisson", keep(master match) nogen
merge m:1 patid using "$aurumdir/`pop'_`risk'", keep(master match) keepusing(`risk'date b`risk') nogen
gen patid2=patid+"A"
gen gender2=1 if gender=="M"
replace gender2=2 if gender=="F"
drop gender
rename gender2 gender
save "$datadir/`pop'_`cond'_`risk'_poisson_aurum", replace

use "$datadir/`pop'_`cond'_`risk'_poisson_gold", clear
append using "$datadir/`pop'_`cond'_`risk'_poisson_aurum"
sort patid startdate_`cond'


egen newid = group(patid2)

//**ARI RATE OVER TIME WITH TIME-VARYING CV RISK**//

*stsplit by agegroup & cv risk

stset endfudate_`cond', fail(`cond'==1) origin(time dob) enter(time startdate_`cond') exit(time .) id(newid) scale(365.25)
assert _st!=0
stsplit curragegrp, at(40(5)65)

stset endfudate_`cond', fail(`cond'==1) origin(time `risk'date) enter(time startdate_`cond') exit(time .) id(newid) scale(365.25)
*assert _st!=0 - only those with hypertension before/during follow-up will be included for this split, which is fine as is not the final set for analysis 
stsplit _`risk', at(0.001) 
gen `cond'`risk'=0 if _`risk'==0 | _`risk'==.
replace `cond'`risk'=1 if `cond'`risk'!=0
label values `cond'`risk' `risk'

stset endfudate_`cond', fail(`cond'==1) origin(time startdate_`cond') enter(time startdate_`cond') exit(time .) id(newid) scale(365.25) 
assert _st!=0

*rate by cv risk status outputted to excel table
strate `cond'`risk', per(1000) cluster(newid) output("$outputdir\ari\output_`pop'_`cond'_`risk'", replace)
preserve
use "$outputdir\ari\output_`pop'_`cond'_`risk'", replace
gen dummy=1
reshape wide _D _Y _Rate _Lower _Upper, i(dummy) j(`cond'`risk')
foreach var of varlist _Rate1 _Lower1 _Upper1 _Rate0 _Lower0 _Upper0 {
	format `var' %8.1f
	replace `var'=round(`var', 0.1)
	}
save "$outputdir\ari\table_rate_`pop'_`cond'_`risk'", replace	
restore	

}
}
}
