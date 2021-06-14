 
*ssc install metan
clear
import excel "J:\EHR-Working\Jennifer\ARI_CVcomplications\Gold\OutputFiles\ari\ari_irr.xlsx", sheet("mainstudypop") firstrow
gen source="gold"
save "$outputdir\ari\ari_irr_gold", replace

clear
import excel "J:\EHR-Working\Jennifer\ARI_CVcomplications\Aurum\OutputFiles\ari\ari_irr.xlsx", sheet("mainstudypop") firstrow
gen source="aurum"
save "$outputdir\ari\ari_irr_aurum", replace

use "$outputdir\ari\ari_irr_gold", clear
append using "$outputdir\ari\ari_irr_aurum"

encode infection, gen(outcome)
encode cardiovascularrisk, gen(cvrisk)

levelsof outcome, local(out)
foreach o of local out {

metan i_es i_lci i_uci if outcome==`o' & cvrisk==1, random effect(IRR) nograph

levelsof cvrisk, local(cv)
foreach c of local cv {	

metan c_es c_lci c_uci if outcome==`o' & cvrisk==`c', random effect(IRR) nograph
metan f_es f_lci f_uci if outcome==`o' & cvrisk==`c', random effect(IRR) nograph

}
}

