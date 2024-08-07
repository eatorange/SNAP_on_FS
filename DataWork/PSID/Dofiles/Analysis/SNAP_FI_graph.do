	use	"${SNAP_dtInt}/SNAP_policy_data_official",	clear
		
		
	
	collapse	(mean)	SNAP_index_w, by(year)
	
	tempfile	SNAP_index_year
	save		`SNAP_index_year'
	
	*	Annual plots
		use	"${SNAP_dtInt}/SNAP_1979_2019_census_annual", clear
		merge	1:1	year	using	`SNAP_index_year', assert(1 3) nogen
		
		replace	FSSS_FI_official	=	0.104	if	year==1996
		replace	FSSS_FI_official	=	0.087	if	year==1997
		replace	FSSS_FI_official	=	0.102	if	year==1998
		
		replace	FSSS_FI_official	=	FSSS_FI_official*100
		
		
		
	*	Merge unemployment rate
		merge	1:1	year	using	"${SNAP_dtInt}/Unemployment Rate_nation", assert(2 3) nogen
	
		
/*
		graph	twoway	(line	FSSS_FI_official	year if inrange(year,1997,2014))	///
						(line	SNAP_index_w	year if inrange(year,1997,2014))	///
						(line	foodexp_tot_inclFS_pc_real	year if inrange(year,1997,2014), yaxis(2))
*/
		*	FI, food spending (in study sample) and SPI
		graph	twoway	(line FSSS_FI_official	year if inrange(year,1997,2013), lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Official Food Insecurity Rate (%)")))	///
						(line SNAP_index_w	year if inrange(year,1997,2013), lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "SNAP Policy Index")))	///
						(line foodexp_tot_inclFS_pc_real year if inrange(year,1997,2013), yaxis(2) lc(red) lp(dash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Per capita food exp (real) ($)") row(2) size(small))), 	///
						ytitle("Percent", axis(1)) ytitle("Dollars", axis(2)) xtitle("Log(Consumption Expenditure)")	title("Food Insecurity, Food Expenditure and SPI") name(FI_foodexp_SPI, replace)
		graph	export	 "${SNAP_outRaw}/FI_foodexp_SPI.png", as(png) replace
		
		
		*	FI, unemployment rate and SPI
		graph	twoway	(line FSSS_FI_official	year if inrange(year,1997,2014), lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Food Insecurity Rate (%)")))	///
						(line SNAP_index_w	year if inrange(year,1997,2014), lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "SNAP Policy Index")))	///
						(line unemp_rate year if inrange(year,1997,2014), yaxis(2) lc(red) lp(dash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Unemployment Rate (%)") row(2) size(small))), 	///
						ytitle("Percent", axis(1))  xtitle("Log(Consumption Expenditure)")	title("Food Insecurity, Unemployment Rate and SPI (1997-2014)") name(FI_unemp_SPI, replace)
		graph	export	 "${SNAP_outRaw}/FI_unemp_SPI.png", as(png) replace