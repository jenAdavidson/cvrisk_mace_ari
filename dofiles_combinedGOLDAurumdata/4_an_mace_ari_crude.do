////////////////
//MACE OUTCOME//
////////////////


local cvrisk hypertens qrisk 
local exposure ari ari_pneumo ari_flu
local outcome mace macesevere mi angina acs hf ali stroke tia stroketia cvddeath 
local denom StudyPop SensStudyPop


foreach pop of local denom {
foreach infect of local exposure {
foreach risk of local cvrisk {

use $golddir/`pop'_`infect'_mace, clear
merge 1:1 patid indexdate using $golddir/`pop'_`infect'_mace_`risk', keepusing(`risk') nogen
tostring patid, replace
gen patid2=patid+"G"
save "$datadir/`pop'_`infect'_mace_`risk'_gold", replace

use $aurumdir/`pop', clear
keep patid   
merge 1:m patid using $aurumdir/`pop'_`infect'_mace, keep(match) nogen
merge 1:1 patid indexdate using $aurumdir/`pop'_`infect'_mace_`risk', keep(match) keepusing(`risk') nogen
gen patid2=patid+"A"
gen gender2=1 if gender=="M"
replace gender2=2 if gender=="F"
drop gender
rename gender2 gender
save "$datadir/`pop'_`infect'_mace_`risk'_aurum", replace

}
}
}


foreach pop of local denom {
foreach infect of local exposure {
foreach risk of local cvrisk {

use "$datadir/`pop'_`infect'_mace_`risk'_gold", clear
append using "$datadir/`pop'_`infect'_mace_`risk'_aurum"
sort patid2 indexdate

egen newid = group(patid2)

replace endfudate_mace=endfudate_mace+1 if indexdate==endfudate_mace // gives 1 day follow up to those who enter and exit on the same date

foreach cond of local outcome {

preserve
stset endfudate_mace, fail(`cond'==1) origin(time indexdate) enter(time indexdate) id(newid) scale(365.25) 
// those not included are due to outcome on earlier episode so cannot be included in further follow-up. 


*rate by cv risk status
strate `risk', per(1000) cluster(newid) output("$outputdir/mace_after_ari/output_`pop'_`infect'_`cond'_`risk'", replace)


use $outputdir/mace_after_ari/output_`pop'_`infect'_`cond'_`risk', clear
gen dummy=1
reshape wide _D _Y _Rate _Lower _Upper, i(dummy) j(`risk')
foreach var of varlist _Rate1 _Lower1 _Upper1 _Rate0 _Lower0 _Upper0 {
	format `var' %8.1f
	replace `var'=round(`var', 0.1)
	}
save $outputdir/mace_after_ari/table_`pop'_`infect'_`cond'_`risk', replace	
restore	

}
}
}
}

