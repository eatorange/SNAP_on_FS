use "${SNAP_dtInt}/SNAP_long_PFS_cat", clear
	

*	Construct annaul-nationawide data to generate cutoffs using different macroeconomic indicators

		
		
		*	Variables to be collapsed
		local	collapse_vars	foodexp_tot_exclFS_pc	foodexp_tot_inclFS_pc	foodexp_tot_exclFS_pc_real	foodexp_tot_inclFS_pc_real	///
								foodexp_W_TFP_pc foodexp_W_TFP_pc_real	fam_income_pc_real	fam_income_pc	///	//	Food expenditure and TFP cost per capita (nominal and real)
								rp_age	rp_age_below30 rp_age_over65	rp_female	rp_nonWhte	rp_HS	///
								rp_somecol	rp_col	rp_disabled	famnum	FS_rec_wth	FS_rec_amt_capita	FS_rec_amt_capita_real	/* part_num */	///	//	Gender, race, education, FS participation rate, FS amount
								PFS_ppml_noCOLI	NME	PFS_FI_ppml_noCOLI	NME_below_1	FSSS_FI	FSSS_FI_v2	PFS_threshold_ppml_noCOLI	///	//	Outcome variables		
								/*	FI_pct	FSSS_FI_official */	CPI		TFP_monthly_cost 	//	official FI prevalence rate (used to construct PFS threshold)
		
		*	All population
			collapse (mean) `collapse_vars' (median)	rp_age_med=rp_age	[pw=wgt_long_ind], by(year)
				
			
			lab	var	rp_female	"Female (RP)"
			lab	var	rp_nonWhte	"Non-White (RP)"
			*lab	var	rp_HS_GED	"HS or GED (RP)"
			lab	var	rp_col		"College degree (RP)"
			*lab	var	rp_col_4yr	"4-year College degree (RP)"
			lab	var	rp_disabled	"Disabled (RP)"
			lab	var	FS_rec_wth	"FS received"
			lab	var	PFS_ppml_noCOLI		"PFS"
			lab	var	NME			"NME"
			lab	var	PFS_FI_ppml_noCOLI	"PFS < 0.5"
			lab	var	NME_below_1	"NME < 1"
			lab	var	foodexp_W_TFP_pc		"Monthly TFP cost per capita"
			lab	var	foodexp_W_TFP_pc_real	"Monthly TFP cost per capita (Jan 2019 dollars)"
			lab	var	foodexp_tot_exclFS_pc		"Monthly Food exp per capita (w/o FS)"
			lab	var	foodexp_tot_inclFS_pc		"Monthly Food exp per capita (with FS)"
			lab	var	foodexp_tot_exclFS_pc_real	"Monthly Food exp per capita (w/o FS)	(Jan 2019 dollars) "
			lab	var	foodexp_tot_inclFS_pc_real	"Monthly Food exp per capita (with FS)	(Jan 2019 dollars) "
			lab	var	FS_rec_amt_capita			"Monthly FS amount per capita"
			lab	var	FS_rec_amt_capita_real		"Monthly FS amount per capita (Jan 2019 dollars)"
			lab	var	fam_income_pc				"Annual per capita family income (K)"
			lab	var	fam_income_pc_real			"Annual per capita family income (K) (Jan 2019 dollars)"
			lab	var	NME	"Normalized Monteray Expenditure"
			lab	var	NME_below_1	"=1 if NME<1"
		
		
		
		*	Import Census data
		merge	1:1	year	using	"${SNAP_dtInt}/HH_census_1979_2019.dta", nogen assert(2 3) // Missing years in the PSID data will be imported
					
		*	Import unemploymen rate (national)
		merge	1:1	year	using	"${SNAP_dtInt}/Unemployment Rate_nation.dta", nogen assert(2 3) keep(3) // keep only study period.
		
		*	Import other macroeconomic indicators
		merge	m:1	year	using	"${SNAP_dtInt}/National_GDP_growth_1975_2019", nogen assert(2 3) keep(3)	//	GDP growth
		merge	m:1	year	using	"${SNAP_dtInt}/dis_per_inc_pc", nogen assert(2 3) keep(3)	//	Disposable income
		merge	m:1	year	using	"${SNAP_dtInt}/Gini_index", nogen assert(2 3) keep(3)	//	Gini index
		merge	m:1	year	using	"${SNAP_dtInt}/social_spending", nogen keep(1 3) //	Social spending
		merge	m:1	year	using	"${SNAP_dtInt}/PCE_real_change", nogen keep(1 3) //	Change in real PCE
		merge	m:1	year	using	"${SNAP_dtInt}/Census_change_mean_HH_income_lowestfifth.dta", nogen keep(1 3) // Change in real mean HH income in bottom 20 percentile
		
		*	Import food security related indicators as unweighted 
		merge	m:1	year	using	"${SNAP_dtInt}/SNAP_summary", nogen keep(1 3) keepusing(part_num) //	Change in real PCE
		merge	1:1	year	using	"${SNAP_dtInt}/USDA_FI_prevalnce_rate_person.dta", nogen keep(1 3) keepusing(FI_pct	FSSS_FI_official) //	Change in real PCE
		
		*	Fraction of population in SNAP
		**	NOTE: This is NOT the same as the official SNAP participation rate issued by the USDA
		loc	var	frac_SNAP_person
		gen	`var'	=	(part_num*1000000)/US_est_pop
		lab	var	`var'	"SNAP participation rate (0-1)"
	
		cap	drop	pct_SNAP_person
		gen			pct_SNAP_person	=	frac_SNAP_person*100
		lab	var		pct_SNAP_person	"SNAP Participation Rate (%)"
		
		sort	year
			
			*	Additional cleaning
			gen		dis_per_inc_pc_real	=	dis_per_inc_pc	*	(CPI/100)
			lab	var	dis_per_inc_pc_real	""
	
			*	Recale variables, from 0-1 to 0-100
			foreach	var	in	 pct_col_Census pct_rp_nonWhite_Census	pct_rp_White_Census	change_inc_mean_lowestfifth {
				
				replace	`var'	=	`var'	*	100
				
			}
			
		*	Model of PFS cutoff on macroeconomic indicators

			lab	var	PFS_threshold_ppml_noCOLI	"Cut-off PFS"
			local	macrovars	FI_pct	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	pct_SNAP_person	pov_rate_national	unemp_rate	GDP_pc_growth
			

			*	Summary stats
			estpost tabstat	`macrovars',	statistics(count	mean	sd	min	  max	/*sd	min	 median	p95 max*/	) columns(statistics) 	// save
			est	store	summstats_annual

		
			esttab	summstats_annual	using	"${SNAP_outRaw}/summstats_annual.csv",  ///
				cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics - Annual (1979-2019)") noobs 	  replace
		

			*	Table B3: Correlation
			cd	"${SNAP_outRaw}"	
			asdoc pwcorr	`macrovars'	if	!mi(PFS_threshold_ppml_noCOLI), label star(all) save(TabB3_corr_macro_table) replace
			
			*	Regression
			
				*	Correlation matrix above show that some variables are highly correlated with one another (i.e. Gini index and disposable income)
				*	Thus, I use only one of those variables to avoid multicolinearity and overfitting.
				*	I use the following four variables
					*	ln(disposable personal income per capita)
					*	share of RP that are non-White
					*	GDP per capita growth rate
					*	Poverty rate
					
				*	Bivariate regression of 4 variables above
				
				*	Disposable income
				cap	drop	PFS_cutoff_income_hat
				cap	drop	PFS_cutoff_income_e
				cap	drop	PFS_cutoff_income_e2
			
				reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	ln(disposable income per capita)
				predict	PFS_cutoff_income_hat
				predict	PFS_cutoff_income_e, resid
				gen		PFS_cutoff_income_e2	=	(PFS_cutoff_income_e)^2
				est	store	PFS_cutoff_income
				
				cap	drop	PFS_cutoff_nonWhite_hat
				cap	drop	PFS_cutoff_nonWhite_e
				cap	drop	PFS_cutoff_nonWhite_e2
				
				*	% of non-White population
				reg	PFS_threshold_ppml_noCOLI pct_rp_nonWhite_Census	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	% of non-White RP
				predict	PFS_cutoff_nonWhite_hat
				predict	PFS_cutoff_nonWhite_e, resid
				gen		PFS_cutoff_nonWhite_e2	=	(PFS_cutoff_nonWhite_e)^2
				est	store	PFS_cutoff_nonWhite
						
				*	GDP growth per capita
				cap	drop	PFS_cutoff_GDP_hat
				cap	drop	PFS_cutoff_GDP_e
				cap	drop	PFS_cutoff_GDP_e2
				
				reg	PFS_threshold_ppml_noCOLI GDP_pc_growth	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	GDP per capita growth rate
				est	store	PFS_cutoff_GDPgrowth
				predict	PFS_cutoff_GDP_hat
				predict	PFS_cutoff_GDP_e, resid
				gen		PFS_cutoff_GDP_e2	=	(PFS_cutoff_GDP_e)^2
				est	store	PFS_cutoff_GDPgrowth
								
				*	National poverty rate
				cap	drop	PFS_cutoff_pov_hat
				cap	drop	PFS_cutoff_pov_e
				cap	drop	PFS_cutoff_pov_e2
				
				reg	PFS_threshold_ppml_noCOLI pov_rate_national	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	Poverty rate
				predict	PFS_cutoff_pov_hat
				predict	PFS_cutoff_pov_e, resid
				gen		PFS_cutoff_pov_e2	=	(PFS_cutoff_pov_e)^2
				est	store	PFS_cutoff_povrate
				
				*	(2025-2-15) SNAP participation rate 
				cap	drop	PFS_cutoff_SNAP_hat
				cap	drop	PFS_cutoff_SNAP_e
				cap	drop	PFS_cutoff_SNAP_e2
			
				reg	PFS_threshold_ppml_noCOLI pct_SNAP_person	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	Poverty rate
				predict	PFS_cutoff_SNAP_hat
				predict	PFS_cutoff_SNAP_e, resid
				gen		PFS_cutoff_SNAP_e2	=	(PFS_cutoff_SNAP_e)^2
				est	store	PFS_cutoff_SNAPrate		
				
				*	(2025-2-22)	Change in real mean HH income (20 percentile)
				cap	drop	PFS_cutoff_lowinc_hat
				cap	drop	PFS_cutoff_lowinc_e
				cap	drop	PFS_cutoff_lowinc_e2
				
				reg	PFS_threshold_ppml_noCOLI change_inc_mean_lowestfifth	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	Poverty rate
				predict	PFS_cutoff_lowinc_hat
				predict	PFS_cutoff_lowinc_e, resid
				gen		PFS_cutoff_lowinc_e2	=	(PFS_cutoff_pov_e)^2
				est	store	PFS_cutoff_lowinc
				
				*	(2025-6-28)	Unemployment rate
				cap	drop	PFS_cutoff_unemp_hat
				cap	drop	PFS_cutoff_unemp_e
				cap	drop	PFS_cutoff_unemp_e2
				
				reg	PFS_threshold_ppml_noCOLI unemp_rate	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	Poverty rate
				predict	PFS_cutoff_unemp_hat
				predict	PFS_cutoff_unemp_e, resid
				gen		PFS_cutoff_unemp_e2	=	(PFS_cutoff_unemp_e)^2
				est	store	PFS_cutoff_unemp
				
				*	Multivariate regressions
					
					*	Income and non-White
					reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	pct_rp_nonWhite_Census	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	income and non-White population
					est	store	PFS_cutoff_inc_nonWhite
					
					*	Income, GDP growth, poverty rate
					reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	pct_rp_nonWhite_Census	GDP_pc_growth	pov_rate_national	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	Poverty rate
				
				*	Full regression, without unemlpoyment rate ((2024-08 version, This is the model I use to construct pre-1995 threshold, after discussing with Chris)
				cap	drop	PFS_cutoff_full_hat
				cap	drop	PFS_cutoff_full_e
				cap	drop	PFS_cutoff_full_e2
				
				reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	pct_rp_nonWhite_Census	GDP_pc_growth	pov_rate_national	if	!mi(PFS_threshold_ppml_noCOLI), robust
				predict	PFS_cutoff_full_hat
				predict	PFS_cutoff_full_e, resid
				gen		PFS_cutoff_full_e2	=	(PFS_cutoff_full_e)^2
				est	store	PFS_cutoff_full
				
				
				*	(2025-3-1) Using Poverty and SNAP only
				loc	name	povsnap
				cap	drop	PFS_cutoff_`name'_hat
				cap	drop	PFS_cutoff_`name'_e
				cap	drop	PFS_cutoff_`name'_e2
			
				reg	PFS_threshold_ppml_noCOLI 	pov_rate_national	pct_SNAP_person	if	!mi(PFS_threshold_ppml_noCOLI), robust
				predict	PFS_cutoff_`name'_hat
				predict	PFS_cutoff_`name'_e, resid
				gen		PFS_cutoff_`name'_e2	=	(PFS_cutoff_`name'_e)^2
				est	store	PFS_cutoff_`name'
				
				*	(2025-3-1) Using Poverty and Bottome 20% income only	
				loc	name	povlowinc
				cap	drop	PFS_cutoff_`name'_hat
				cap	drop	PFS_cutoff_`name'_e
				cap	drop	PFS_cutoff_`name'_e2
			
				reg	PFS_threshold_ppml_noCOLI 	pov_rate_national	change_inc_mean_lowestfifth	if	!mi(PFS_threshold_ppml_noCOLI), robust
				predict	PFS_cutoff_`name'_hat
				predict	PFS_cutoff_`name'_e, resid
				gen		PFS_cutoff_`name'_e2	=	(PFS_cutoff_`name'_e)^2
				est	store	PFS_cutoff_`name'
				
				*	(2025-3-1)	Using SNAP and low income only
				loc	name	snaplowinc
				cap	drop	PFS_cutoff_`name'_hat
				cap	drop	PFS_cutoff_`name'_e
				cap	drop	PFS_cutoff_`name'_e2
			
				reg	PFS_threshold_ppml_noCOLI 	pct_SNAP_person	change_inc_mean_lowestfifth	if	!mi(PFS_threshold_ppml_noCOLI), robust
				predict	PFS_cutoff_`name'_hat
				predict	PFS_cutoff_`name'_e, resid
				gen		PFS_cutoff_`name'_e2	=	(PFS_cutoff_`name'_e)^2
				est	store	PFS_cutoff_`name'
				
				*	(2025-2-22) Using poverty rate, SNAP rate and mean bottom 20 percentile income
				cap	drop	PFS_cutoff_full2_hat
				cap	drop	PFS_cutoff_full2_e
				cap	drop	PFS_cutoff_full2_e2
			
				reg	PFS_threshold_ppml_noCOLI 	pov_rate_national	pct_SNAP_person	change_inc_mean_lowestfifth	if	!mi(PFS_threshold_ppml_noCOLI), robust
				predict	PFS_cutoff_full2_hat
				predict	PFS_cutoff_full2_e, resid
				gen		PFS_cutoff_full2_e2	=	(PFS_cutoff_full2_e)^2
				est	store	PFS_cutoff_full2
				
				*	(2025-6-28) SNAP rate/GDP growh rate/disposable income/unemp rate
				cap	drop	PFS_cutoff_full3_hat
				cap	drop	PFS_cutoff_full3_e
				cap	drop	PFS_cutoff_full3_e2
			
				reg	PFS_threshold_ppml_noCOLI 	 ln_dis_per_inc_pc pct_SNAP_person	 unemp_rate 	GDP_pc_growth 	 if	!mi(PFS_threshold_ppml_noCOLI), robust
				predict	PFS_cutoff_full3_hat
				predict	PFS_cutoff_full3_e, resid
				gen		PFS_cutoff_full3_e2	=	(PFS_cutoff_full3_e)^2
				est	store	PFS_cutoff_full3
					
					graph	twoway	(line	pov_rate_national	year)	(connected	pct_SNAP_person	year)	(connected change_inc_mean_lowestfifth year, yaxis(2))	(connected	unemp_rate	year),	///
					 legend(label(1 "Poverty rate") label(2 "SNAP participation rate") label(3 "Change in 20 percentile mean income (real)")  label(4 "Unemployment rate")  row(1) size(small) keygap(0.1) pos(6) symxsize(5))	///
					 ytitle(Percentage) title(Trends in new economic indicators in the model)
					 
				    graph	export	"${SNAP_outRaw}/trends_new_indicators.png", replace	
					graph	close	
					 
				
				*	Using "esttab"
					
					*	ln(income), non-White, GDP growth and poverty rate
					esttab	PFS_cutoff_income	PFS_cutoff_nonWhite	PFS_cutoff_GDPgrowth		PFS_cutoff_povrate	PFS_cutoff_SNAPrate	PFS_cutoff_inc_nonWhite	PFS_cutoff_full	using "${SNAP_outRaw}/PFS_cutoff_on_X.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(PFS cutoff on economic indicators)		replace	
					
					*	Poverty rate, SNAP participation rate, change in mean HH inome bottom 20 percentile and their comps
					esttab	PFS_cutoff_povrate	PFS_cutoff_SNAPrate	PFS_cutoff_lowinc	PFS_cutoff_povsnap		PFS_cutoff_povlowinc	PFS_cutoff_snaplowinc	PFS_cutoff_full2	using "${SNAP_outRaw}/PFS_cutoff_on_X2.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(PFS cutoff on economic indicators)		replace	
							
					*	Disposable income, SNAP rate, poverty rate, and unemployment rat and all 
					esttab	PFS_cutoff_income	PFS_cutoff_SNAPrate	PFS_cutoff_povrate		PFS_cutoff_unemp	PFS_cutoff_full3	using "${SNAP_outRaw}/PFS_cutoff_on_X3.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(PFS cutoff on economic indicators)		replace			
			
				*	Using "etable"
				*	(2024-12-9) Formatting issue- significant stars are printed in separate columns...
				*	(2025-7-18) Updated formatting
				collect clear
				cap	putdocx clear    
				putdocx begin
				etable, estimates(PFS_cutoff_income PFS_cutoff_SNAPrate	PFS_cutoff_unemp	PFS_cutoff_GDPgrowth	PFS_cutoff_full3) ///
					cstat(_r_b) cstat(_r_se, nformat(%7.3f)) column(index) mstat(N, nformat(%9.0g)) mstat(r2, nformat(%9.2f)) stars( 0.1 "*" 0.05 "**" 0.01 "***", attach(_r_b)) 	///
					title("Table 2: PFS Thresholds and Macroeconomic Indicators, 1995-2019")	///
					/*export("${SNAP_outRaw}/PFS_cutoff_on_X.docx", as(docx) replace)*/
				*collect layout (coleq#colname#result[_r_b _r_se] result[N r2]) (cmdset#stars) (), name(ETable)
				collect layout (coleq#colname#result[_r_b _r_se] result[N r2]) (cmdset#stars) (), name(ETable)	
				collect stars, result
				collect query stars
				collect preview
				putdocx collect
				putdocx save "${SNAP_outRaw}/PFS_cutoff_on_X.docx", replace
					
					/*
					*	With unemployment rate (supplementary)
					cap	drop	PFS_cutoff_full2_hat	PFS_cutoff_full2_e	PFS_cutoff_full2_e2	
					reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	pct_rp_nonWhite_Census	GDP_pc_growth	pov_rate_national	unemp_rate	if	!mi(PFS_threshold_ppml_noCOLI), robust
					predict	PFS_cutoff_full2_hat
					predict	PFS_cutoff_full2_e, resid
					gen		PFS_cutoff_full2_e2	=	(PFS_cutoff_full2_e)^2
					est	store	PFS_cutoff_full2
					
					esttab	PFS_cutoff_income	PFS_cutoff_nonWhite	PFS_cutoff_GDPgrowth	PFS_cutoff_povrate	PFS_cutoff_unemprate	PFS_cutoff_full	PFS_cutoff_full2	using "${SNAP_outRaw}/PFS_cutoff_on_X2.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 r2_a, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(PFS cutoff on economic indicators)		replace	
				
					*/
				
				*	Comparing the first and the second model
				summ PFS_threshold_ppml_noCOLI PFS_cutoff_full_hat PFS_cutoff_full2_hat	PFS_cutoff_full_e2	PFS_cutoff_full2_e2
				
				
				*	Graph actual PFS cut-off(1995-2019) and predicted PFS cut-off
				graph	twoway	///
					(line PFS_threshold_ppml_noCOLI year, lpattern(solid) xaxis(1 2) yaxis(1) legend(label(1 "Realized")))	///
					(line PFS_cutoff_SNAP_hat		year, lpattern(dash)	lc(gray)  lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Predicted (poverty)")))	///
					(line PFS_cutoff_full_hat		year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Predicted  (current)") row(1) size(small) keygap(0.1) pos(6) symxsize(5)))	///
					(line PFS_cutoff_full3_hat		year, lpattern(dot) lcolor(black) xaxis(1 2) yaxis(1)  legend(label(4 "Predicted  (new)") row(1) size(small) keygap(0.1) pos(6) symxsize(5))),	///
								/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
								xtitle(Year)	ytitle("Probability")	///
								title(PFS Thresholds)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFS_cutoff, replace)
							
							
												/*(line PFS_cutoff_income_hat		year, lpattern(dot) xaxis(1 2) yaxis(1) legend(label(2 "Predicted (disposable income)")))	///
					(line PFS_cutoff_nonWhite_hat	year, lpattern(shortdash)	lc(gray)  lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Predicted (non-White)")))	/// */
			
				graph	export	"${SNAP_outRaw}/PFS_thresholds.png", replace	
				graph	close	
				
				*	(2025-3-1)	Fig 2: Plotting new thresholds only
				cap	drop	upper
				gen	upper=0.7
				
				graph	twoway	///
					(bar	upper year if inlist(year, 1981, 1991, 2001, 2008, 2009), bcolor(gs14) barwidth(2)  legend(label(1 "Recession periods"))	graphregion(fcolor(white)))	///
					(line PFS_threshold_ppml_noCOLI year, lpattern(solid) lc(blue) legend(label(2 "Realized")))	///
					(line PFS_cutoff_income_hat		year, lpattern(dash)	lc(gray)  lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Predicted (Income)")))	///
					(line PFS_cutoff_SNAP_hat		year, lpattern(dash_dot) lc(green)  legend(label(4 "Predicted  (SNAP)") row(1) size(small) keygap(0.1) pos(6) symxsize(5)))	///
					(line PFS_cutoff_unemp_hat		year, lpattern(shortdash) lc(orange)  legend(label(5 "Predicted  (Unemployment)") row(1) size(small) keygap(0.1) pos(6) symxsize(5)))	///
					(line PFS_cutoff_GDP_hat		year, lpattern(shortdash) lc(red)  legend(label(6 "Predicted  (GDP)") row(1) size(small) keygap(0.1) pos(6) symxsize(5)))	///
					(line PFS_cutoff_full3_hat		year, lpattern(dot) lcolor(black)  legend(label(7 "Predicted  (Full)") row(2) size(small) keygap(0.1) pos(6) symxsize(5))),	///
					xtitle(Year)	ytitle("Probability")	///
					/*title(PFS Thresholds)*/	bgcolor(white)	graphregion(color(white)) note(Recession periods are based on NBER Business Cycle Dating)	name(PFS_cutoff, replace)
	
				graph	export	"${SNAP_outRaw}/Fig2.tiff", replace as(tif)
				graph	close	
		
		
		*	Save year-level data
		compress
		save	"${SNAP_dtInt}/SNAP_1979_2019_census_annual", replace
		
		
		
		
		
			
		
			*	(2024-11-11) Follow-up anaysese based on R&R reviewer comments
			use	"${SNAP_dtInt}/SNAP_1979_2019_census_annual", clear
			
			
		
				*	Rescaled poverty rate to percentage scale (for graphic purpose)
				gen	pov_rate_national_pct	=	pov_rate_national * 0.01
					
					
				*	(1)	Inspecting counter-intuitive associations between known characteristics and PFS cut-offs
								
										
					*	Graphing poverty rate and unemployment rate
					graph twoway 	(connected unemp_rate year) ///
									(connected pov_rate_national year, legend(label(3 "Predicted  (full)") row(1) size(small) keygap(0.1) pos(6) symxsize(5))), ///
									title(National Poverty and Unemlpoyment Rate (%)) ytitle(Percentage (%))
					graph	export	"${SNAP_outRaw}/povrate_unemprate_national.png", replace	
					graph	close
				
					
			
					*	Replciating a couple of regression, replacing a few variables in some specifications (column 3 of table 2)
					reg	PFS_threshold_ppml_noCOLI pov_rate_national	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	Poverty rate only (column 4 of Table 2)
					est	store	PFS_cutoff_povrate
					reg	PFS_threshold_ppml_noCOLI unemp_rate	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	unemployment rate only
					est	store	PFS_cutoff_unemp
					reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	pct_rp_nonWhite_Census	GDP_pc_growth	pov_rate_national	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	full regression (Table 2 column 5)
					est	store	PFS_cutoff_full
					reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	pct_rp_nonWhite_Census	GDP_pc_growth	unemp_rate	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	full regression, replacing pov with unemp 
					est	store	PFS_cutoff_full_unemp1
					reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	pct_rp_nonWhite_Census	GDP_pc_growth	pov_rate_national	unemp_rate	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	full regression, adding  unemp 
					est	store	PFS_cutoff_full_unemp2
					*reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	pct_rp_nonWhite_Census	GDP_pc_growth	pov_rate_national	if	!mi(PFS_threshold_ppml_noCOLI) & inrange(year,1995,2009), robust	//	full regression, using 1995-2009 data only
					*est	store	PFS_cutoff_full_9509
					
					esttab	PFS_cutoff_povrate	PFS_cutoff_unemp	PFS_cutoff_full		PFS_cutoff_full_unemp1	PFS_cutoff_full_unemp2	/*PFS_cutoff_full_9509*/	using "${SNAP_outRaw}/PFS_cutoff_on_X_sup1.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 r2_a, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS cutoff on economic indicators)		replace	
					
				
					
					reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	pct_rp_nonWhite_Census	GDP_pc_growth	pov_rate_national	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	full regression (Table 2 column 5)
					est	store	PFS_cutoff_full
					
					
			
				
					
					*	Time trends of cut-offs and 4 covariates in the full model
					*	Since they are all in different scales, we normalize them using 1995-2019 data
					
					foreach	var	in	PFS_threshold_ppml_noCOLI	PFS_FI_ppml_noCOLI ln_dis_per_inc_pc dis_per_inc_pc	pct_rp_nonWhite_Census	GDP_pc_growth	pov_rate_national	{
						
						summ	`var'	if	inrange(year,1995,2019)
						local	mean=r(mean)
						local	sd=r(sd)
						
						cap	drop	`var'_nm
						gen	`var'_nm	=	(`var'-`mean')/`sd'	if	inrange(year,1995,2019)	&	!mi(PFS_threshold_ppml_noCOLI)
						
					}
					
					*	Including 
					preserve
					keep if inrange(year,1995,2019)
					graph	twoway	(connected PFS_threshold_ppml_noCOLI_nm 		year, lpattern(dash) symbol(diamond) xaxis(1 2) yaxis(1) legend(label(1 "PFS thresholds")))	///
									(connected PFS_FI_ppml_noCOLI_nm 		year, lpattern(longdash) symbol(X) xaxis(1 2) yaxis(1) legend(label(2 "FI Prevalence")))	///
									(connected ln_dis_per_inc_pc_nm				year, lpattern(dot) symbol(triangle) xaxis(1 2) yaxis(1) legend(label(3 "ln(disposable income)")))	///
									(connected pct_rp_nonWhite_Census_nm	year, lpattern(dash_dot) xaxis(1 2) symbol(square) yaxis(1)  legend(label(4 "% non-White pop")))  ///
									(connected GDP_pc_growth_nm	year, lpattern(solid) xaxis(1 2) symbol(circle) yaxis(1)  legend(label(5 "GDP per capita growth")))  ///
									(connected pov_rate_national_nm 		year, lpattern(shortdash) xaxis(1 2) yaxis(1)  symbol(plus) legend(pos(6) row(2) label(6 "Poverty rate"))),  ///
									/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
									xtitle(Year)	xtitle("", axis(2))	ytitle("Z-score", axis(1))	///
									title(PFS Thresholds and Key indicators (1995-2019))	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFS_NME_annual, replace)
					graph	export	"${SNAP_outRaw}/Trend_PFS_cutoff_indicators.png",	replace
					restore
					
					
					*	Full model excluding share of non-White population
					reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc		GDP_pc_growth	pov_rate_national	if	!mi(PFS_threshold_ppml_noCOLI), robust	
					est	store	PFS_cutoff_mod
					predict	PFS_cutoff_mod_hat
					
					*	PFS cut-offs of full and modified
					preserve
						*keep	if	inrange(year,1995,2019)
						graph	twoway	(connected PFS_cutoff_full_hat 		year, lpattern(dash) symbol(diamond) xaxis(1 2) yaxis(1) legend(label(1 "Full cut-off")))	///
										(connected PFS_cutoff_mod_hat 	year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(1)  symbol(plus) legend(pos(6) row(2) label(2 "Modified cut-offs"))),  ///
										/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
										xtitle(Year)	xtitle("", axis(2))	ytitle("PFS THreshold", axis(1)) 	///
										title(PFS Thresholds and Key indicators)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFScutoff_inc_foodexp, replace)
					restore		
				
					*	Time trends of (i) PFS thresholds (ii) Official HH FI rate (iii) Official individual FI rate (iv) FI rate (PSID data)
					*	PFS, NME and Dummies
					preserve
						keep	if	inrange(year,1995,2019)
						graph	twoway	(connected PFS_threshold_ppml_noCOLI 		year, lpattern(dash) symbol(diamond) xaxis(1 2) yaxis(1) legend(label(1 "PFS thresholds")))	///
										(connected pov_rate_national_pct				year, lpattern(dot) symbol(triangle) xaxis(1 2) yaxis(2) legend(label(2 "Poverty rate")))	///
										(connected PFS_FI_ppml_noCOLI	year, lpattern(dash_dot) xaxis(1 2) symbol(square) yaxis(2)  legend(label(3 "Food Insecurity Prevalence (PFS)")))  ///
										(connected FSSS_FI_official 		year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(2)  symbol(plus) legend(pos(6) row(2) label(4 "Food Insecurity Prevalence (Household)"))),  ///
										/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
										xtitle(Year)	xtitle("", axis(2))	ytitle("PFS THreshold", axis(1)) 	ytitle("Percentage", axis(2))	///
										title(PFS Thresholds and Key indicators)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFS_NME_annual, replace)
						graph	export	"${SNAP_outRaw}/Trend_FI_indicators.png", replace	
						*graph	close
						
					restore			
					
					
					
					*	Time trends of the PFS thresholds and income/food exp
					
					loc	var		dis_per_inc_pc_monthly
					cap	drop	`var'
					gen	`var'	=	dis_per_inc_pc	/	12
					lab	var	`var'	"Average monthly per capita disposable income"
					
			
					*	Income
					preserve
						keep	if	inrange(year,1995,2019)
						graph	twoway	(connected PFS_threshold_ppml_noCOLI 		year, lpattern(dash) symbol(diamond) xaxis(1 2) yaxis(1) legend(label(1 "PFS thresholds")))	///
										(connected dis_per_inc_pc 	year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(2)  symbol(plus) legend(pos(6) row(2) label(3 "Per capita food expenditure"))),  ///
										/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
										xtitle(Year)	xtitle("", axis(2))	ytitle("PFS THreshold", axis(1)) 	ytitle("Percentage", axis(2))	///
										title(PFS Thresholds and Key indicators)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFScutoff_inc_foodexp, replace)
					restore		
					
					*	C2: NME, Food exp and TFP cost (real)
					preserve
						*keep	if	inrange(year,1995,2019)
						graph	twoway	(connected NME 		year, lpattern(dash) symbol(diamond) xaxis(1 2) yaxis(1) legend(label(1 "NME"))) 	///
										(connected foodexp_W_TFP_pc_real				year, lpattern(dot) symbol(triangle) xaxis(1 2) yaxis(2) legend(label(2 "per capita TFP cost (2019 Dollars)")))	///
										(connected foodexp_tot_inclFS_pc_real 	year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(2)  symbol(plus) legend(pos(6) row(2) label(3 "Per capita food expenditure (2019 Dollars)"))),  ///
										/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
										xtitle(Year)	xtitle("", axis(2))	ytitle("Food expenditure, TFP cost and NME", axis(1)) 	ytitle("Ratio", axis(1)) 	ytitle("Dollars", axis(2))	///
										title(Food expenditure/TFP cost/NME)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFScutoff_inc_foodexp, replace)
						graph	export	"${SNAP_outRaw}/foodexp_TFP_NME.png", replace	
					restore		
					
					* NME
					preserve
						graph	twoway	(connected PFS_threshold_ppml_noCOLI 		year, lpattern(dash) symbol(diamond) xaxis(1 2) yaxis(1) legend(label(1 "PFS thresholds")))	///
										(connected NME 	year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(2)  symbol(plus) legend(pos(6) row(2) label(2 "NME"))),  ///
										/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
										xtitle(Year)	xtitle("", axis(2))	ytitle("PFS THreshold", axis(1)) 	ytitle("Percentage", axis(2))	///
										title(PFS Thresholds and Key indicators)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFScutoff_inc_foodexp, replace)
					restore		
					
					*	Food exp and TFP cost (nominal)
					preserve
						graph	twoway	(connected foodexp_W_TFP_pc 		year if inrange(year,1979,1988), lpattern(dash) symbol(diamond) xaxis(1 2) yaxis(1) legend(label(1 "TFP cost")))	///
										(connected foodexp_tot_inclFS_pc 	year if inrange(year,1979,1988), /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(1)  symbol(plus) legend(pos(6) row(2) label(2 "Per capita food exp"))),  ///
										/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
										xtitle(Year)	xtitle("", axis(2))	ytitle("Dollars", axis(1)) 	///
										title(PFS Thresholds and Key indicators)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFScutoff_inc_foodexp, replace)
					restore	
					
					*	Share of non-White householder
					preserve
					keep if inrange(year,1995,2019)
					graph	twoway		(connected PFS_threshold_ppml_noCOLI 	year, lpattern(dash) symbol(diamond) xaxis(1 2) yaxis(1) legend(label(1 "Thresholds")))	///
										(connected pct_rp_nonWhite_Census 	year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(2)  symbol(plus) legend(pos(6) row(2) label(2 "Percentage(%)"))),  ///
									/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
									xtitle(Year)	xtitle("", axis(2))	ytitle("PFS THreshold", axis(1)) 		///
									title(PFS Thresholds and Key indicators)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFScutoff_inc_foodexp, replace)
					restore
					
					*	PFS itself
					graph	twoway	(connected PFS_ppml_noCOLI 	year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(1)  symbol(plus) legend(pos(6) row(2) label(1 "Non-White HH"))),  ///
									/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
									xtitle(Year)	xtitle("", axis(2))	ytitle("PFS THreshold", axis(1)) 		///
									title(PFS Thresholds and Key indicators)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFScutoff_inc_foodexp, replace)
									
					
					* 	Poverty rate, SNAP participation rate and change in bottom 20 percentile mean income (real)
					graph	twoway	(connected pov_rate_national 		year, lpattern(dash) symbol(diamond) xaxis(1 2) yaxis(1) legend(label(1 "NME"))) 	///
									(connected foodexp_W_TFP_pc_real				year, lpattern(dot) symbol(triangle) xaxis(1 2) yaxis(2) legend(label(2 "per capita TFP cost (2019 Dollars)")))	///
									(connected foodexp_tot_inclFS_pc_real 	year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(2)  symbol(plus) legend(pos(6) row(2) label(3 "Per capita food expenditure (2019 Dollars)"))),  ///
									/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
									xtitle(Year)	xtitle("", axis(2))	ytitle("Food expenditure, TFP cost and NME", axis(1)) 	ytitle("Ratio", axis(1)) 	ytitle("Dollars", axis(2))	///
									title(Food expenditure/TFP cost/NME)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFScutoff_inc_foodexp, replace)
					graph	export	"${SNAP_outRaw}/foodexp_TFP_NME.png", replace	
					
					
		
			cap	drop	NME_real
			gen	NME_real = foodexp_tot_inclFS_pc_real / foodexp_W_TFP_pc_real
			graph twoway (connected fam_income_pc_real year, yaxis(1)) (connected pov_rate_national year, yaxis(2)), legend(pos(6))
			
			graph twoway (connected fam_income_pc_real year, yaxis(1)) (connected foodexp_tot_inclFS_pc_real year, yaxis(2)), legend(pos(6))
			
			
			
			/*
			
				*	Test overfitting
	
	cap	drop	PFS_cutoff_SNAP_e_abs=.
	cap	drop	PFS_cutoff_full3_e_abs
	
	gen		PFS_cutoff_SNAP_e_abs=.
	gen		PFS_cutoff_full3_e_abs=.
	
		foreach	year	in	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
			
			
			*	(2025-2-15) SNAP participation rate 
			cap	drop	PFS_cutoff_SNAP_hat
			cap	drop	PFS_cutoff_SNAP_e
			cap	drop	PFS_cutoff_SNAP_e2
		
			reg	PFS_threshold_ppml_noCOLI pct_SNAP_person	if	inrange(year,1995,2019)	&	year!=`year', robust	//	Poverty rate
			predict	PFS_cutoff_SNAP_hat
			predict	PFS_cutoff_SNAP_e, resid
			gen		PFS_cutoff_SNAP_e2	=	(PFS_cutoff_SNAP_e)^2
			est	store	PFS_cutoff_SNAPrate	
			
			replace		PFS_cutoff_SNAP_e_abs	=	abs(PFS_cutoff_SNAP_e)	if	year==`year'
			
			*	Full model
				*	(2025-6-28) SNAP rate/GDP growh rate/disposable income
			cap	drop	PFS_cutoff_full3_hat
			cap	drop	PFS_cutoff_full3_e
			cap	drop	PFS_cutoff_full3_e2
		
			reg	PFS_threshold_ppml_noCOLI 	 ln_dis_per_inc_pc pct_SNAP_person	pov_rate_national	unemp_rate 	if	inrange(year,1995,2017), robust
			predict	PFS_cutoff_full3_hat
			predict	PFS_cutoff_full3_e, resid
			gen		PFS_cutoff_full3_e2	=	(PFS_cutoff_full3_e)^2
			est	store	PFS_cutoff_full3

			replace		PFS_cutoff_full3_e_abs	=	abs(PFS_cutoff_full3_e)	if	year==`year'
				
		}
		
		summ	PFS_cutoff_SNAP_e_abs	PFS_cutoff_full3_e_abs
		
	*/