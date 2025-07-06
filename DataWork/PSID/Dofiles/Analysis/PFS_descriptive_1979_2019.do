

	/***************************************************************
		SECTION 1: Data prep		 									
	***************************************************************/		 
		
	
	
	*	Open 1979-2019 PFS data, which does NOT have spell constructed
	
	use	"${SNAP_dtInt}/SNAP_long_PFS", clear
	lab	var	PFS_ppml_noCOLI		"PFS"
		
		*	Keep relevant study sample only
		keep	if	!mi(PFS_ppml_noCOLI)
		
	*	Additional cleaning

		*	(2024-6-27) Classifying FS/FI using PFS
		
			*	For post-1995, we have annual USDA FI prevalnce rate, which we can use it as a reference.
			*	For pre-1995, we do not have annual USDA FI prevalence to refer.
			*	Thus, methods could differ b/w pre-1995 and post-1995
			
			*	For post-1995, there are two ways to do it based on official prevalence rate.
				*	(1) Categorize the equal share of households as FI based on PFS (like Lee et al. 2023)
					*	For example, if 10% is food insecure by CPS in a given year, categorize bottom 10th percentile of PFS as FI.
				*	(2) For a subsample where PSID collected FSSS, we can re-classify FSSS-based FI using the Rasch score.
					*	For example, if 10% is food insecure by CPS in a given year, classify the 10% highest Rasch scores as food insecure.
					*	This method can be used to further investigate mismatch b/w PSID and CPS, it cannot be used for the years when PSID didn't collect RFSSS.
					*	This method "re-classifies" FSSS_FI.
			*	For pre-1995, there are two ways to to do it.
				*	(1) Use a fixed PFS probability as a cut-off (like, 0.5)
				*	(2) Use a predicted cut-off from the model using post-1995 data
					*	Model estimating the association of PFS cut-off with macroeconomic indicators.
			
			*	1st method of post-1995 is done above.
			
		*	2nd method of post-1995
			
			*	Distribution of Rasch scores (FSSS) measured by PSID
			loc	var	FSSS_FI_cps_base
			cap	drop	`var'
			gen	`var'=.
			lab	var	`var'	"Food insecure (FSSS - matched to official prevalence)"
			
				*	1999: 10.1% are FI
				loc	year=1999
				tab	HFSM_raw	[aw=wgt_long_ind] if year==`year'	//	About 10% of households have the score 2 or higher
				replace	`var'=0	if	inrange(HFSM_raw,0,1)	&	year==`year'
				replace	`var'=1	if	inrange(HFSM_raw,2,18)	&	year==`year'
				
				*	2001:	10.7% are FI
				loc	year=2001
				tab	HFSM_raw	[aw=wgt_long_ind] if year==`year'	//	About 12% of households have the score 1 or higher, 8% have 2 or higher
				replace	`var'=0	if	inrange(HFSM_raw,0,0)	&	year==`year'
				replace	`var'=1	if	inrange(HFSM_raw,1,18)	&	year==`year'
				
				*	2003:	11.2% are FI
				loc	year=2003
				tab	HFSM_raw	[aw=wgt_long_ind] if year==`year'	//	About 13% of households have the score 1 or higher, 9% have 2 or higher
				replace	`var'=0	if	inrange(HFSM_raw,0,0)	&	year==`year'
				replace	`var'=1	if	inrange(HFSM_raw,1,18)	&	year==`year'
				
				*	2015:	12.7% are FI
				loc	year=2015
				tab	HFSM_raw	[aw=wgt_long_ind] if year==`year'	//	About 14.6% of households have the score 2 or higher, 11% have 3 or higher
				replace	`var'=0	if	inrange(HFSM_raw,0,2)	&	year==`year'
				replace	`var'=1	if	inrange(HFSM_raw,3,18)	&	year==`year'
				
				*	2017:	11.8% are FI
				loc	year=2017
				tab	HFSM_raw	[aw=wgt_long_ind] if year==`year'	//	About 12.9% of households have the score 2 or higher, 9.6% have 3 or higher
				replace	`var'=0	if	inrange(HFSM_raw,0,1)	&	year==`year'
				replace	`var'=1	if	inrange(HFSM_raw,2,18)	&	year==`year'
				
				*	2019:	10.5% are FI
				loc	year=2019
				tab	HFSM_raw	[aw=wgt_long_ind] if year==`year'	//	About 11.3% of households have the score 2 or higher, 9% have 3 or higher
				replace	`var'=0	if	inrange(HFSM_raw,0,1)	&	year==`year'
				replace	`var'=1	if	inrange(HFSM_raw,2,18)	&	year==`year'
				
			*	FS indicator - opposite of FI indicator
			cap	drop	FSSS_FS_cps_base
			recode		FSSS_FI_cps_base	(0=1)	(1=0), gen(FSSS_FS_cps_base)
			lab	var		FSSS_FS_cps_base	"Food secure (FSSS - matched to official prevalence)"
	
		
	
	*	Re-scale annual income per capita
		replace	fam_income_pc_real	=	fam_income_pc_real / 1000
		lab	var	fam_income_pc_real		"Annual family income per capita (K) (Jan 2019 dollars)"
	
	*	Additional cleaning	
		lab	var	foodexp_tot_exclFS_pc_real	"Monthly food expenditure per capita (Jan 2019 dollars)"
		lab	var	FS_rec_amt_capita_real		"SNAP benefit amount (Jan 2019 dollars)"
		lab	var	FS_rec_wth					"Received SNAP"
		
		
		*	Label variables
			lab	define	rp_female	0	"Male"	1	"Female", replace
			lab	val	rp_female	rp_female
			
			lab	var	ind_female	"Female (ind)"
			label	value	ind_female	rp_female
			
			lab	define	rp_nonWhite	0	"White"	1	"Non-White", replace
			lab	val	rp_nonWhte	rp_nonWhite
			
			lab	define	rp_disabled	0	"NOT disabled"	1	"Disabled", replace
			lab	val	rp_disabled	rp_disabled
			
	
		*	(2024-2-26) Individual-level race
		*	Race is not observed in every period for individuals. It is observed only when (i) RP (ii) Spouse (after 1985)
		*	But since our individuals are RP or SP at least once during the survey period, we observe individuals' race at least once for each individual (except small share of ppl  who were not RP prior to 1985)
		*	So we replace missing races in certain periods with the race from the observed period(s).
		
				*	Validate the race is time-invariant througout the study period.
				cap	drop	min_ind_White
				cap	drop	max_ind_White
				cap	drop	min_ind_nonWhite
				cap	drop	max_ind_nonWhite
				bys	x11101ll: egen min_ind_White = min(ind_White)
				bys	x11101ll: egen max_ind_White = max(ind_White)
				bys	x11101ll: egen min_ind_nonWhite = min(ind_nonWhite)
				bys	x11101ll: egen max_ind_nonWhite = max(ind_nonWhite)
				
				*	In principal, race should be time-invariant. Let's see if that's the case.
				loc	var		same_race_over_time
				cap	drop	`var'
				gen		`var'=0	if	min_ind_White!=max_ind_White
				replace	`var'=1	if	min_ind_White==max_ind_White
				lab	var	`var'	"=1 if race is time-invariant"
				
				tab	`var'	//	Less than 3% of have time-varying race
				unique	x11101ll	if	`var'==0	//	# of individuals with time-varying.
			
				*	TReplace missing race with the first observed non-missing race.
				cap	drop	obsno
				cap	drop	ind_race_missing
				cap	drop	first_nm_race_ind
				
				sort	x11101ll	year, stable
				bys	x11101ll:	gen	long	obsno	=	_n
				bys	x11101ll:	gen	ind_race_W_missing	=	missing(ind_White)
				bys	x11101ll	(ind_race_W_missing	obsno):	gen	first_nm_ind_W	=	ind_White[1]
				
				
				lab	var	obsno	"# of observations per individual"
				lab	var	ind_race_W_missing	"=1 if individual racial status is missing"
				lab	var	first_nm_ind_W	"=1 if the first non-missing raical status is White"
				

				br	x11101ll	year	ind_White	same_race_over_time	obsno	ind_race_W_missing	first_nm_ind_W
				
				*	Update missing racial status
				**	NOTE: 3% of obs have still missing race.
				replace	ind_White		=	1	if	mi(ind_White)		&	first_nm_ind_W==1
				replace	ind_White		=	0	if	mi(ind_White)		&	first_nm_ind_W==0
				replace	ind_nonWhite	=	1	if	mi(ind_nonWhite)	&	first_nm_ind_W==0
				replace	ind_nonWhite	=	0	if	mi(ind_nonWhite)	&	first_nm_ind_W==1
				
	
			* (2024-02-08) Replace missing educational attainment when a child (15-year-old or younger) with RP's attainment.
			
			foreach	var	in	edu_cat	NoHS	HS	somecol	col	{
				
				replace	ind_`var'	=	rp_`var'	if	ind_`var'==0 & inrange(age_ind,1,15)
				
				
			}
		
			*	Replace full category variable as missing if inappropriate
			replace	ind_edu_cat=.n	if	ind_edu_cat==0
			
				*	Replace dummies as missing if full category is missing
				replace	ind_NoHS=.n		if	mi(ind_edu_cat)
				replace	ind_HS=.n		if	mi(ind_edu_cat)
				replace	ind_somecol=.n	if	mi(ind_edu_cat)
				replace	ind_col=.n		if	mi(ind_edu_cat)	

		
		*	Temporarily save, to import cut-off later
		*tempfile	SNAP_long_PFS_before_cutoff
		*save		`SNAP_long_PFS_before_cutoff', replace
		
		
	
	*	Categorize food security status based on annual food security prevalence rate (1995-2019)
	*	CAUTION: TAKES SOME TIME
	*	This code is take from the LBH, with a few minor modification 
		
		
			*	Categorize food security status based on the PFS.
			 quietly	{
				foreach	type	in	ppml_noCOLI	/*ls	rf*/	{
						
						cap	drop		PFS_FS_`type'
						cap	drop		PFS_FI_`type'
						
						gen	PFS_FS_`type'	=	0	if	!mi(PFS_`type')	//	Food secure
						gen	PFS_FI_`type'	=	0	if	!mi(PFS_`type')	//	Food insecure (low food secure and very low food secure)
						*gen	PFS_LFS_`type'	=	0	if	!mi(PFS_`type')	//	Low food secure
						*gen	PFS_VLFS_`type'	=	0	if	!mi(PFS_`type')	//	Very low food secure
						*gen	PFS_cat_`type'	=	0	if	!mi(PFS_`type')	//	Categorical variable: FS, LFS or VLFS
												
						*	Generate a variable for the threshold PFS
						cap	drop	PFS_threshold_`type'
						gen	PFS_threshold_`type'=.
						
						foreach	year	in	1995 1996 1997 1999 2001 2003 2005 2007 2009 2011 2013 2015 2017 2019	{
							
							*if	"`type'"=="glm_RPPadj" & inrange(`year',2,5) continue	
							
							di	"current loop is `plan',  in year `year'"
							cap	drop	pctile_`type'_`year'
							xtile pctile_`type'_`year' = PFS_`type' if !mi(PFS_`type')	&	year==`year', nq(1000)
	
							* We use loop to find the threshold value for categorizing households as food (in)secure
							local	counter 	=	1	//	reset counter
							local	ratio_FI	=	0	//	reset FI population ratio
							*local	ratio_VLFS	=	0	//	reset VLFS population ratio
							
							foreach	indicator	in	FI	/*VLFS*/	{
								
								local	counter 	=	1	//	reset counter
								local	ratio_`indicator'	=	0	//	reset population ratio
							
								* To decrease running time, we first loop by 10 
								summ	`indicator'_pct if year==`year'
								local	prop_`indicator'_`year'=r(mean)
								
								while (`counter' < 1000 & `ratio_`indicator''<`prop_`indicator'_`year'') {	//	Loop until population ratio > USDA ratio
									
									qui di	"current indicator is `indicator', counter is `counter'"
									qui	replace	PFS_`indicator'_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',1,`counter')	//	categorize certain number of households at bottom as FI
									
									*qui	svy, subpop(year_enum`year'): mean 	PFS_`indicator'_`type'	//	Generate population ratio
									*local ratio_`indicator' = _b[PFS_`indicator'_`type']
									
									summ	PFS_`indicator'_`type'	[aw=wgt_long_ind]	if	year==`year'
									local ratio_`indicator'	=	r(mean)
									
									local counter = `counter' + 10	//	Increase counter by 10
								}

								*	Since we first looped by unit of 10, we now have to find to exact value by looping 1 instead of 10.
								qui di "internediate counter is `counter'"
								local	counter=`counter'-10	//	Adjust the counter, since we added extra 10 at the end of the first loop

								while (`counter' > 1 & `ratio_`indicator''>`prop_`indicator'_`year'') {	//	Loop until population ratio < USDA ratio
									
									qui di "counter is `counter'"
									qui	replace	PFS_`indicator'_`type'=0	if	year==`year'	&	inrange(pctile_`type'_`year',`counter',1000)
									*qui	svy, subpop(year_enum`year'): mean 	PFS_`indicator'_`type'
									*local ratio_`indicator' = _b[PFS_`indicator'_`type']
									summ	PFS_`indicator'_`type'	[aw=wgt_long_ind]	if	year==`year'
									local ratio_`indicator'	=	r(mean)
									
									local counter = `counter' - 1
								}
								qui di "Final counter is `counter'"

								*	Now we finalize the threshold value - whether `counter' or `counter'+1
									
									*	Counter
									local	diff_case1	=	abs(`prop_`indicator'_`year''-`ratio_`indicator'')

									*	Counter + 1
									qui	replace	PFS_`indicator'_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',1,`counter'+1)
									*qui	svy, subpop(year_enum`year'): mean 	PFS_`indicator'_`type'
									*local	ratio_`indicator' = _b[PFS_`indicator'_`type']
									summ	PFS_`indicator'_`type'	[aw=wgt_long_ind]	if	year==`year'
									local ratio_`indicator'	=	r(mean)
									
									local	diff_case2	=	abs(`prop_`indicator'_`year''-`ratio_`indicator'')
									qui	di "diff_case2 is `diff_case2'"

									*	Compare two threshold values and choose the one closer to the USDA value
									if	(`diff_case1'<`diff_case2')	{
										global	threshold_`indicator'_`plan'_`type'_`year'	=	`counter'
									}
									else	{	
										global	threshold_`indicator'_`plan'_`type'_`year'	=	`counter'+1
									}
								
								*	Categorize households based on the finalized threshold value.
								qui	{
									replace	PFS_`indicator'_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',1,${threshold_`indicator'_`plan'_`type'_`year'})
									replace	PFS_`indicator'_`type'=0	if	year==`year'	&	inrange(pctile_`type'_`year',${threshold_`indicator'_`plan'_`type'_`year'}+1,1000)		
								}	
								di "thresval of `indicator' in year `year' is ${threshold_`indicator'_`plan'_`type'_`year'}"
							}	//	indicator
							
							*	Food secure households
							replace	PFS_FS_`type'=0	if	year==`year'	&	inrange(pctile_`type'_`year',1,${threshold_FI_`plan'_`type'_`year'})
							replace	PFS_FS_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',${threshold_FI_`plan'_`type'_`year'}+1,1000)
							
							*	Low food secure households
							*replace	PFS_LFS_`type'=1	if	year==`year'	&	PFS_FI_`type'==1	&	PFS_VLFS_`type'==0	//	food insecure but NOT very low food secure households			
							
							*	Categorize households into one of the three values: FS, LFS and VLFS						
							*replace	PFS_cat_`type'=1	if	year==`year'	&	PFS_VLFS_`type'==1
							*replace	PFS_cat_`type'=2	if	year==`year'	&	PFS_LFS_`type'==1
							*replace	PFS_cat_`type'=3	if	year==`year'	&	PFS_FS_`type'==1
							*assert	PFS_cat_`type'!=0	if	year==`year'
							
							*	Save threshold PFS as global macros and a variable, the average of the maximum PFS among the food insecure households and the minimum of the food secure households					
							qui	summ	PFS_`type'	if	year==`year'	&	PFS_FS_`type'==1	//	Minimum PFS of FS households
							local	min_FS_PFS	=	r(min)
							qui	summ	PFS_`type'	if	year==`year'	&	PFS_FI_`type'==1	//	Maximum PFS of FI households
							local	max_FI_PFS	=	r(max)
							
							*	Save the threshold PFS
							replace	PFS_threshold_`type'	=	(`min_FS_PFS'	+	`max_FI_PFS')/2		if	year==`year'
							*global	PFS_threshold_`type'_`year'	=	(`min_FS_PFS'	+	`max_FI_PFS')/2
							
							
						}	//	year
						
						label	var	PFS_FI_`type'	"Food Insecurity (PFS) (`type')"
						label	var	PFS_FS_`type'	"Food security (PFS) (`type')"
						*label	var	PFS_LFS_`type'	"Low food security (PFS) (`type')"
						*label	var	PFS_VLFS_`type'	"Very low food security (PFS) (`type')"
						*label	var	PFS_cat_`type'	"PFS category: FS, LFS or VLFS"
						
						

				}	//	type
				
				*lab	define	PFS_category	1	"Very low food security (VLFS)"	2	"Low food security (LFS)"	3	"Food security(FS)"
				*lab	value	PFS_cat_*	PFS_category
				
				lab	var	PFS_threshold_ppml_noCOLI			"Threshold value (PFS)"
				
			 }	//	qui
	
	
		save	"${SNAP_dtInt}/SNAP_long_PFS_cat", replace	
		
		

	
	*	Categorize food security status based on annual food security prevalence rate (pre-1995)
	use	"${SNAP_dtInt}/SNAP_long_PFS_cat", clear

	*	Thresholds of 1995-2019, determined by the code above, to determine thresholds for earlier period.		
			tab PFS_threshold_ppml_noCOLI
			
			*	Time trend
			collapse (mean) PFS_threshold_ppml_noCOLI, by(year)
			
			summ	PFS_threshold_ppml_noCOLI	//	Average threshold
			
			graph	twoway	(connected PFS_threshold_ppml_noCOLI	year if inrange(year,1995,2019)), ytitle(Probability) title(Threshold probability of being food secure: 1995-2019)	///
			note(Threshold defined based on the official food insecuriy prevalence rate) 	ysc(range(0 1)) bgcolor(white) ylabel(0(0.2)1)	graphregion(color(white)) 	name(cutoff_prob_PFS_9519, replace)
		
			graph display cutoff_prob_PFS_9519, ysize(8) xsize(12.0)
			graph	export	"${SNAP_outRaw}/PFS_cutoff_prob_PFS_9519.png", as(png) replace
			graph	close


			
	*	Food insecurity trends
	use	"${SNAP_dtInt}/SNAP_long_PFS_cat", clear	
		

		*	FI trends (both PFS and FSSS)
		preserve
			collapse (mean) PFS_FI_ppml_noCOLI	FSSS_FI	FI_pct	[aw=wgt_long_ind], by(year)
			
			
			twoway	(line PFS_FI_ppml_noCOLI	year if inrange(year,1999,2019), lc(green) lp(solid) lwidth(medium)  graphregion(fcolor(white)) legend(label(1 "PFS)")))	///
					(line FI_pct	year if inrange(year,1999,2019), lc(black) lp(longdash) lwidth(medium)	 graphregion(fcolor(white)) legend(label(2 "USDA official")))	///
					(connected FSSS_FI	year if inlist(year,1999,2001,2003), lc(red) lp(shortdash) lwidth(medium)	msymbol(circle)	graphregion(fcolor(white)) legend(label(3 "FSSS")))	///
					(connected FSSS_FI	year if inlist(year,2015,2017,2019), lc(red) lp(shortdash) lwidth(medium)	msymbol(circle) graphregion(fcolor(white)) legend(label(4 "FSSS") row(2) size(small) keygap(0.1) symxsize(5))),	///
					title("Food Insecurity Prevalence Rates") ytitle("Fraction") xtitle("Year") name(FI_prevalence_cutoffs, replace)
			
			graph	export	"${SNAP_outRaw}/PFS_FSSS_FI_trend.png", as(png) replace
			graph	close	
		restore
	


			
		
		*	Load previously saved data and import pre-1995 cutoff
		use	 "${SNAP_dtInt}/SNAP_long_PFS_cat", clear
		merge	m:1	year using	"${SNAP_dtInt}/SNAP_1979_2019_census_annual", keepusing(/*PFS_cutoff_full_hat	 PFS_cutoff_full2_hat*/	PFS_cutoff_*_hat) assert(2 3) keep(3) nogen
		
			*	Construct a cut-off variable covering full study period
			loc	var	PFS_threshold_7919
			cap	drop	var
			gen	double	`var'=.
			replace	`var'	=	PFS_threshold_ppml_noCOLI	if	inrange(year,1995,2019)	//	Realized cut-off using USDA FI prevalence rate
				
				*	(2025-2-22) Use new cut-off
				replace	`var'	=	PFS_cutoff_full3_hat 			if	inrange(year,1979,1994)	//	Predicted cut-off from macroindicators
				lab	var	`var'	"PFS FI threshold (1979-2019)"
		
		
		
			*	Update PFS-based food security based on updated pre-1995 cutoff
			******	IMPORTANT: PREVIOUSLY, I RE-CLASSIFED ALL HOUSEHOLDS, INCLUDING POST-1995! I THINK IT IS AN ERROR, OR AN OLD METHOD OF SNAP PAPER.
			******	MUST RE-DO THE ANALYSIS.
			loc	var	PFS_FI_ppml_noCOLI
			*cap	drop	`var'
			*gen		`var'=.
			replace	`var'=1	if	!mi(PFS_ppml_noCOLI)	&	inrange(year,1979,1994)	&	PFS_ppml_noCOLI<PFS_threshold_7919	//	less than cut-off
			replace	`var'=0	if	!mi(PFS_ppml_noCOLI)	&	inrange(year,1979,1994)	&	PFS_ppml_noCOLI>=PFS_threshold_7919	//	greater than cut-off
			*lab	var	`var'	"Food insecure (PFS < 0.5)"
			
			
			*	Update FS  FOR PRE-1995 PERIODS
			loc	var		PFS_FS_ppml_noCOLI
			replace	`var'=1	if	PFS_FI_ppml_noCOLI==0	&	!mi(PFS_ppml_noCOLI)	&	inrange(year,1979,1994)
			replace	`var'=0	if	PFS_FI_ppml_noCOLI==1	&	!mi(PFS_ppml_noCOLI)	&	inrange(year,1979,1994)
			
/*
			loc	var		l2_PFS_FS_ppml_noCOLI
			replace	`var'=1	if	l2_PFS_FI_ppml_noCOLI==0	&	!mi(l2_PFS_ppml_noCOLI)	&	inrange(year,1979,1994)
			replace	`var'=0	if	l2_PFS_FI_ppml_noCOLI==1	&	!mi(l2_PFS_ppml_noCOLI)	&	inrange(year,1979,1994)
			
*/
	
					
		*	Generate lagged PFS variable
		sort	x11101ll	year
		foreach	var	in		PFS_FI_ppml_noCOLI	PFS_FS_ppml_noCOLI	{
			
			cap	drop	l2_`var'
			local	label:	variable	label	`var'
			di	"`label'"
			gen	l2_`var'	=	l2.`var'
			lab	var	l2_`var'	"Lagged `label'"
			
		}


	*	Construct spell length
		**	IMPORANT NOTE: Since the PFS data has (1) gap period b/w 1988-1991 and (2) changed frequency since 1997, it is not clear how to define "spell"
		**	Based on 2023-7-25 discussion, we decide to define spell as "the number of consecutive 'OBSERVATIONS' experiencing food insecurity", regardless of gap period and updated frequency
			**	We can do robustness check with the updated spell (i) splitting pre-gap period and post-gap period, and (ii) Multiplying spell by 2 for post-1997		
		cap drop	_seq	_spell	_end
		tsspell, cond(year>=1979 & PFS_FI_ppml_noCOLI==1)

	*	Create additional indicators
	
		
		*	Create "unique" variable that has only one value for individual (need to generate individual-level summary stats)
			
			*	Gender
			local	var	ind_female
			cap	drop	`var'_uniq
			bys x11101ll	live_in_FU:	gen `var'_uniq=`var' if _n==1	&	live_in_FU==1	
			summ `var'_uniq	
			label	var	`var'_uniq "Gender (ind)"
			
			*	Number of waves living in FU
			loc	var	num_waves_in_FU
			cap	drop	`var'
			cap	drop	`var'_temp
			cap	drop	`var'_uniq
			bys	x11101ll:	egen	`var'=total(live_in_FU)	if	live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
			bys x11101ll:	egen	`var'_temp	=	max(`var')
			bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
			drop	`var'
			rename	`var'_temp	`var'
			summ	`var'_uniq,d
			label	var	`var'_uniq "\# of waves surveyed"
			
			*	Ever been food insecure
			loc	var	PFS_FI_ever_been
			cap	drop	`var'
			cap	drop	`var'_uniq
			cap	drop	`var'_temp
			bys	x11101ll:	egen	`var'=	max(PFS_FI_ppml_noCOLI)	if live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
			bys x11101ll:	egen	`var'_temp	=	max(`var')
			bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
			drop	`var'
			rename	`var'_temp	`var'
			summ	`var'_uniq,d
			label	var	`var'_uniq "=1 if ever esimated to be food insecure"
			
			*	Ever-used FS over stuy period
			loc	var	FS_ever_used
			cap	drop	`var'
			cap	drop	`var'_uniq
			cap	drop	`var'_temp
			bys	x11101ll:	egen	`var'=	max(FS_rec_wth)	if live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
			bys x11101ll:	egen	`var'_temp	=	max(`var')
			bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
			drop	`var'
			rename	`var'_temp	`var'
			summ	`var'_uniq ,d
			label var	`var'		"FS ever used throughouth the period"
			label var	`var'_uniq	"FS ever used throughouth the period"
			
			*	# of waves FS redeemed	(if ever used)
			loc	var	total_FS_used
			cap	drop	`var'
			cap	drop	`var'_temp
			cap	drop	`var'_uniq
			bys	x11101ll:	egen	`var'=	total(FS_rec_wth)	if	live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
			bys x11101ll:	egen	`var'_temp	=	max(`var')
			bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
			summ	`var'_uniq if `var'_uniq>=1,d
			label var	`var'		"Total FS used throughouth the period"
			label var	`var'_uniq	"Total FS used throughouth the period"
			
			*	% of FS redeemed (# FS redeemed/# surveyed)		
			loc	var	share_FS_used
			cap	drop	`var'
			cap	drop	`var'_uniq
			gen	`var'	=	total_FS_used_uniq	/	num_waves_in_FU_uniq
			bys x11101ll:	gen 	`var'_uniq	=	`var' if _n==1
			label var	`var'		"\% of FS used throughouth the period"
			label var	`var'_uniq	"\% of FS used throughouth the period"
			
	*	Additional data label
			lab	var	ind_female				"Gender"
			lab	var	baseline_indiv			"Surveyed in 1979"
			lab	var	num_waves_in_FU_uniq	"Number of waves surveyed"
			lab	var	PFS_FI_ever_been_uniq	"Ever estimated to be food insecure"
			lab	var	FS_ever_used_uniq		"Ever used SNAP benefits"
			lab	var	total_FS_used_uniq		"Years SNAP benefits used"
			
			lab	define	yes1no0		0	"No"	1	"Yes", replace
			*lab	val		PFS_FI_ever_been_uniq	FS_ever_used_uniq	yes1no0
			
			lab define baseline_indiv 0 "NOT surveyed in 1979" 1 "Surveyed in 1979",	replace
			lab val baseline_indiv baseline_indiv
			
			lab	define	PFS_FI_ever_been_uniq	0	"Never estimated to be food insecure"	1	"Ever estimated to be food insecure",	replace
			lab	val		PFS_FI_ever_been_uniq	PFS_FI_ever_been_uniq
			
			lab	define	FS_ever_used_uniq		0	"Never used SNAP benefit"	1	"Ever used SNAP benefit", replace
			lab	val		FS_ever_used_uniq	FS_ever_used_uniq
			
			
			lab	define	rp_married	0	"NOT married (RP)"	1	"Married (RP)",	replace
			lab	val		rp_married	rp_married
			lab	define	rp_female	0	"Male (RP)"	1	"Female (RP)", replace
			lab	define	rp_nonWhite	0	"White (RP)"	1	"non-White (RP)", replace
			lab	var		rp_edu_cat	"Education (RP)"
			lab	define	rp_employed	0	"NOT employed (RP)"	1	"Employed (RP)", replace
			lab	val		rp_employed	rp_employed
			lab	define	rp_disabled	0	"NOT disabled (RP)"	1	"Disabled (RP)",	replace
			lab	var		ratio_child	"Proportion of children"
			lab	define	FS_rec_wth	0	"NOT received SNAP"	1	"Received SNAP"
			lab	val		FS_rec_wth	FS_rec_wth
			lab	define	PFS_FI_ppml_noCOLI	0	"NOT estiamted to be food insecure by PFS"	1	"Estimated to be food insecure by PFS", replace
			lab	val		PFS_FI_ppml_noCOLI	PFS_FI_ppml_noCOLI
			lab	define	NME_below_1	0	"NME is above 1"	1	"NME is below 1", replace
			lab	val		NME_below_1	NME_below_1
			
			
			lab	var	rp_region		"Region"
		
		
		
		
		*	Save
		save	"${SNAP_dtInt}/SNAP_descdta_1979_2019", replace	//	Inermediate descriptive data for 1979-2019
		
		
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		*	Preparing data to be shared with Senan
	
			*	(2024-7-8)	Additional cleaning
			
				*	Rename HFSM to FSSS
				rename	(HFSM_raw HFSM_cat)	(FSSS_raw	FSSS_cat)
				lab	var	FSSS_raw	"FSSS (raw score)"
				lab	var	FSSS_cat	"FSSS (category)"
				lab	define	FSSS_cat	1	"High Food Security"	2	"Marginal Food Security"	3	"Low Food Security"	4	"Very Low Food Security"
				lab	val	FSSS_cat	FSSS_cat
				
				*	Drop suffix in PFS variables
				rename	(PFS_ppml_noCOLI PFS_FS_ppml_noCOLI PFS_FI_ppml_noCOLI)	(PFS_7919	PFS_FS_7919	PFS_FI_7919)
				lab	var	PFS_7919		"PFS (1979-2019)"
				lab	var	PFS_FS_7919		"=1 if food secure by PFS (1979-2019)"
				lab	var	PFS_FI_7919		"=1 if food insecure by PFS (1979-2019)"
				
				*	Re-label variables
			
			
			*	keeping necessary variables only for sharing with Senan
			local	IDvars		x11101ll pn	year
			local	samplevars	surveyid seqnum sampstr sampcls wgt_long_ind wgt_long_fam sample_source
			local	rpvars		rp_age rp_female rp_state rp_married rp_White rp_employed rp_edu_cat rp_disabled
			local	indvars		ind_female ind_race ind_White ind_employed_dummy ind_edu_cat
			local	FSSSvars	FSSS_cat FSSS_raw FSSS_FI
			local	PFSvars		PFS_7919 PFS_FS_7919 PFS_FI_7919
			local	foodvars	foodexp_tot_inclFS_pc  foodexp_tot_inclFS_pc_real	foodexp_W_TFP	foodexp_W_TFP_real	foodexp_W_TFP_pc	foodexp_W_TFP_pc_real	NME
			
			order	`IDvars'	`samplevars'	`rpvars'	`indvars'	`FSSSvars'	`PFSvars'	`foodvars'
			keep	`IDvars'	`samplevars'	`rpvars'	`indvars'	`FSSSvars'	`PFSvars'	`foodvars'
			
			*	Save
			compress
			save	"${SNAP_dtInt}/PFS_7919", replace	//	Inermediate descriptive data for 1979-2019
		


	
	/***************************************************************
		SECTION 2: Summary and Descriptive stats
	***************************************************************/		 
			
		
	use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
	assert	!mi(PFS_ppml_noCOLI)
	
		
	*	Basic sample information
		di	_N	// # of observations (non-missing PFS)
		distinct	year	//	26 waves
			
		*	Number of individuals
			distinct	x11101ll	//	# of unique individuals in sample
			distinct	x11101ll	if	baseline_indiv==1	//	# of baseline individuals
			distinct	x11101ll	if	splitoff_indiv==1	//	# of splitoff individuals

	
	*	Table 1: Summary stats, pooled

		*	Additional macros are added for summary stats
		
	
		global	indvars			ind_female	baseline_indiv	/*splitoff_indiv*/	num_waves_in_FU_uniq	PFS_FI_ever_been_uniq FS_ever_used_uniq	total_FS_used_uniq	/*share_FS_used_uniq*/	//	Individual-level variables
		
		*global	statevars		l2_foodexp_tot_inclFS_pc_1_real l2_foodexp_inclFS_pc_2_real_K
		global	demovars		rp_age /*rp_age_sq*/	rp_female	rp_nonWhte	rp_married	
		global	eduvars_all		rp_NoHS	rp_HS rp_somecol rp_col	//	Include "High school diploma" which was excluded as a reference category in "eduvars" macro (thus in regression)
		global	empvars			rp_employed
		global	healthvars		rp_disabled
		global	familyvars		famnum	ratio_child
		global	regionvars		rp_region_NE rp_region_MidAt rp_region_South rp_region_MidWest rp_region_West
		global	foodvars		FS_rec_wth	//	Should I use prected FS redemption from 1st-stage IV?, or even drop it for exclusion restriction?
		
		*	Monetary variables
		global	econvars		fam_income_pc_real	
		global	foodamtvars		foodexp_tot_exclFS_pc_real	FS_rec_amt_capita_real	
		
		*	State- and Year-FE, which are absorbed in "ppmlhdfe"
		global	timevars		year_enum4-year_enum11 year_enum14-year_enum30 //	Exclude year_enum3 (1979) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
		
		*	Outcome var (PFS)
		global	outcomevars		PFS_ppml_noCOLI	NME	PFS_FI_ppml_noCOLI	NME_below_1
		
		*	Set of macros used to generate summary stats
		global	summvars_obs		${demovars}	${eduvars_all}	${empvars}	${healthvars}	${familyvars}	${regionvars}	${foodvars}	${econvars}	${foodamtvars}	${outcomevars}
		
		
		*	Individual-vars
		estpost tabstat	${indvars}	[aw=wgt_long_ind]	if	!mi(num_waves_in_FU_uniq),	statistics(count	mean	sd	min		/*median	p95*/	max) columns(statistics)		// save
		est	store	sumstat_ind
		*estpost tabstat	${indvars}	[aw=wgt_long_ind]	if	!mi(num_waves_in_FU_uniq) & income_below_200==1,	statistics(count	mean	sd	min	median	p95	max) columns(statistics)		// save
		*est	store	sumstat_ind_incbelow200
		
		collect	clear
		
		*	Individual-level
		dtable if !mi(num_waves_in_FU_uniq) [aweight = wgt_long_ind], sample(, statistic(frequency) ) ///
			continuous(num_waves_in_FU_uniq total_FS_used_uniq, statistics( mean sd)) factor(ind_female baseline_indiv PFS_FI_ever_been_uniq FS_ever_used_uniq, statistics( fvpercent)) ///
			nformat(%9.0fc  frequency ) nformat(%9.2fc  mean sd) nformat(%9.1fc  fvpercent ) name(summstat_ind)
			
			*	Custom setup to display 
			collect style autolevels result frequency mean sd fvproportion fvpercent, clear
			collect layout (var#result) (cmdset)
			collect label levels cmdset 1 "Summary"
			collect style header result, level(hide)
				
			collect layout (var[_N]#result ind_female[1]#result baseline_indiv[1]#result var[num_waves_in_FU_uniq]#result ///
				PFS_FI_ever_been_uniq[1]#result	FS_ever_used_uniq[1]#result	var[total_FS_used_uniq]#result) (cmdset) (), name(summstat_ind)
				
		
			collect preview
	
		*	Individual-year level
		 
		 global	indyear_contvar	rp_age	famnum	ratio_child	fam_income_pc_real	foodexp_tot_exclFS_pc_real	FS_rec_amt_capita_real	PFS_ppml_noCOLI	NME	
		 global	indyear_factvar	rp_female	rp_nonWhte	rp_married	 rp_edu_cat	rp_employed	rp_disabled	rp_region	FS_rec_wth	PFS_FI_ppml_noCOLI	NME_below_1
		 
		 cap	collect	drop	summstat_indyear
		 dtable [aweight = wgt_long_ind], sample(, statistic(frequency) ) ///
			continuous(${indyear_contvar}, statistics( mean sd)) factor(${indyear_factvar}, statistics( fvpercent)) ///
			nformat(%9.0fc  frequency ) nformat(%9.2fc  mean sd) nformat(%9.1fc  fvpercent ) name(summstat_indyear)
			
				*	Custom setup to display 
			collect style autolevels result frequency mean sd fvproportion fvpercent, clear
			collect layout (var#result) (cmdset)
			collect label levels cmdset 1 "Summary"
			collect style header result, level(hide)
			
			collect layout (var[_N]#result var[rp_age]#result	rp_female[1]#result	rp_nonWhte[1]#result	rp_married[1]#result		///
				var[1.rp_edu_cat]#result	var[2.rp_edu_cat]#result	var[3.rp_edu_cat]#result	var[4.rp_edu_cat]#result	rp_employed[1]#result	rp_disabled[1]#result	///
				var[famnum]#result	var[ratio_child]#result	var[1.rp_region]#result	var[2.rp_region]#result	var[3.rp_region]#result	var[4.rp_region]#result	var[5.rp_region]#result	///
				FS_rec_wth[1]#result	var[fam_income_pc_real]#result	var[foodexp_tot_exclFS_pc_real]#result	var[FS_rec_amt_capita_real]#result	///
				PFS_FI_ppml_noCOLI[1]#result	NME_below_1[1]#result	) (cmdset) (), name(summstat_indyear)
			
			cap	collect	drop	sumstat_all
			collect combine sumstat_all = summstat_ind	summstat_indyear
			
			
			collect layout (var[_N]#result#collection[summstat_ind] ind_female[1]#result baseline_indiv[1]#result var[num_waves_in_FU_uniq]#result ///
				PFS_FI_ever_been_uniq[1]#result	FS_ever_used_uniq[1]#result	var[total_FS_used_uniq]#result	///
				var[_N]#result#collection[summstat_indyear] var[rp_age]#result	rp_female[1]#result	rp_nonWhte[1]#result	rp_married[1]#result		///
				var[1.rp_edu_cat]#result	var[2.rp_edu_cat]#result	var[3.rp_edu_cat]#result	var[4.rp_edu_cat]#result	rp_employed[1]#result	rp_disabled[1]#result	///
				var[famnum]#result	var[ratio_child]#result	var[1.rp_region]#result	var[2.rp_region]#result	var[3.rp_region]#result	var[4.rp_region]#result	var[5.rp_region]#result	///
				FS_rec_wth[1]#result	var[fam_income_pc_real]#result	var[foodexp_tot_exclFS_pc_real]#result	var[FS_rec_amt_capita_real]#result	///
				PFS_FI_ppml_noCOLI[1]#result	NME_below_1[1]#result	) (cmdset) (), name(sumstat_all)
			
			collect	export	"${SNAP_outRaw}/Sumstats_desc_7919.docx", replace as(docx)
			
			
		*	CPI and TFP cost
		use		"${SNAP_dtInt}/TFP cost/TFP_costs_all", clear
		keep	if	age_ind==25
		collapse	(mean)	TFP_monthly_cost, by(year)
		tempfile	TFP
		save	`TFP'
		
		use		"${SNAP_dtInt}/CPI_1947_2021",	clear
		collapse	(mean)	CPI, by(year)
		merge	1:1	year	using	`TFP'
		
		gen	TFP_monthly_cost_real	=	TFP_monthly_cost	*		(100/CPI)
		keep	if	!mi(TFP_monthly_cost)
		
		graph	twoway	(line	CPI	year, lc(black) lp(solid) lwidth(medium) yaxis(1) graphregion(fcolor(white))) 	///
						(line	TFP_monthly_cost year, lc(reg) lp(dash) lwidth(medium) yaxis(2) graphregion(fcolor(white))) 	///
						(line	TFP_monthly_cost_real year, lc(blue) lp(dot) lwidth(medium) yaxis(2) graphregion(fcolor(white))), 	///
						legend(order(1 "CPI" 2 "TFP cost (nominal)"	3 "TFP cost (real)") size(small) keygap(0.1) symxsize(5)) ///
						title("CPI and TFP monthly cost") ytitle("CPI", axis(1))  ytitle("Amount ($)", axis(2))	xtitle("Year") name(CPI_TFP, replace)	///
						note(TFP cost for 25-year old. Averaged over gender and month)
		graph	export	"${SNAP_outRaw}/CPI_TFP_trend.png", as(png) replace
		
		
			
			
			/* Examples on Statalist
			
			
			*dtable price mpg rep78
			dtable, continuous(num_waves_in_FU_uniq  total_FS_used_uniq, statistics( mean sd)) factor(ind_female baseline_indiv	PFS_FI_ever_been_uniq	FS_ever_used_uniq, statistics( fvpercent)) nformat(%12.2f)

				



			* report the layout specification
			collect layout

			* look into which result levels are being shown
			collect query autolevels result
			collect levelsof result
			collect query composite
			collect query composite _dtable_stats
			* stop using the composite result, we want results to be stacked into a
			* single column
			collect style autolevels result frequency fvpercent mean percent proportion rawpercent rawproportion sd sumw, clear

			* change how the cells are arranged;
			* stack the results across rows for each variable;
			* use -cmdset- for a column header
			collect layout (var#result) (cmdset)

			* nicer column header
			collect label levels cmdset 1 "Summary"

			collect preview

			* hide result levels in row headers
			collect style header result, level(hide)

			collect preview

			* make the sample size last
			collect style autolevels var num_waves_in_FU_uniq ind_female _N, clear

			collect preview

			dtable price mpg rep78
			
			
			*/
		
		*	Ind-year vars (observation level)
		estpost tabstat	${summvars_obs}	[aw=wgt_long_ind],	statistics(count	mean	sd	min	median	/*p95*/	max) columns(statistics)		// save
		est	store	sumstat_indyear

		
		esttab	sumstat_ind	sumstat_indyear	using	"${SNAP_outRaw}/Sumstats_desc_7919.csv",  ///
				cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace
		
		*esttab	sumstat_ind	sumstat_indyear	using	"${SNAP_outRaw}/Sumstats_desc_7919.csv",  ///
				main(mean %12.2f) aux(sd %12.2f keep(ind_female)) label	title("Summary Statistics") noobs 	  replace
		
		
		*esttab sumstat_ind	sumstat_indyear using	"${SNAP_outRaw}/Sumstats_desc_7919.csv", cells("mean(fmt(2) label(Prop./Mean)) sd(fmt(2) label(SD) keep(ind_female))") replace
		
		

	

		*	Annual plots
		use	"${SNAP_dtInt}/SNAP_1979_2019_census_annual", clear
	
			*	Gender (RP) 
			graph	twoway	(line pct_rp_female_Census	year, lpattern(dash_dot) xaxis(1) yaxis(1))	///
							(line rp_female year if inrange(year,1979,1988)			, lpattern(dash) xaxis(1) yaxis(1))		///	
							(line rp_female year if inrange(year,1991,2019)			, lpattern(dash) xaxis(1) yaxis(1)),	///	
							legend(order(1 "Census" 2 "Study Sample (PSID)") row(1)  keygap(0.1) symxsize(5)) ///
							xtitle(Year)	/*xtitle("", axis(1))*/	///
							ytitle("Fraction", axis(1)) title(Female)	yscale(r(0 0.5)) ylabel(0(0.2)1) yscale(range(0 1) titlegap(1))	bgcolor(white)	graphregion(color(white)) 	name(gender_annual, replace)	
			
			graph	export	"${SNAP_outRaw}/gender_annual.png", replace	
			graph	close	
			
			*	Race (RP)
			graph	twoway	(line pct_rp_nonWhite_Census	year, lpattern(dash_dot) xaxis(1) yaxis(1))	///
							(line rp_nonWhte year if inrange(year,1979,1988)			, lpattern(dash) xaxis(1) yaxis(1))		///	
							(line rp_nonWhte year if inrange(year,1991,2019)			, lpattern(dash) xaxis(1) yaxis(1)),	///	
							legend(order(1 "Census" 2 "Study Sample (PSID)") row(1)  keygap(0.1) symxsize(5)) ///
							xtitle(Year)	/*xtitle("", axis(1))*/	///
							ytitle("Fraction", axis(1)) title(non-White)	yscale(r(0 0.5)) ylabel(0(0.2)1) yscale(range(0 1) titlegap(1))	bgcolor(white)	graphregion(color(white)) 	name(race_annual, replace)	

			graph	export	"${SNAP_outRaw}/race_annual.png", replace	
			graph	close	
			
			*	Figure 1: Sex and Racial Composition
			grc1leg gender_annual race_annual, rows(1) cols(2) legendfrom(gender_annual)	graphregion(color(white)) position(6)	graphregion(color(white))	///
					title(Sex and Racial Composition of Reference Person) name(gender_race, replace) 	///
					note("Source: U.S. Census" "Shaded region (1988-1991) are missing in the sample" 	"All married couple households are treated as male RP in Census" ///
						"All households without White RP are treated as non-White in Census" )  
					
			graph display gender_race, ysize(8) xsize(12.0)
			graph	export	"${SNAP_outRaw}/gender_race_annual.png", as(png) replace
			graph	close
			

	
			
			*	Figure A1: Food expenditure per capita (including stamp benefit), TFP cost (real)
			graph	twoway	(line foodexp_tot_inclFS_pc_real	year, lpattern(dash) xaxis(1 2) yaxis(1)  legend(label(1 "Food exp")))  ///
							(line foodexp_W_TFP_pc_real			year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(2 "TFP cost"))),	///						
							xline(1987 1992 2007, axis(1) lcolor(black) lpattern(dash))	///
							xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
							xtitle(Year)	xtitle("", axis(2))	ytitle("Food exp with stamp benefit ($)", axis(1)) ///
							/*ytitle("Stamp benefit ($)", axis(2))*/ title(Food expenditure and TFP cost (monthly per capita))	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(foodexp_TFP_annual, replace)
			
			graph display foodexp_TFP_annual, ysize(8) xsize(12.0)
			graph	export	"${SNAP_outRaw}/foodexp_TFP_annual.png", replace	
			graph	close	
			
			
				
		*	Outcomes over different categories
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		
		
			*	Rank correlation b/w PFS and FSSS
				
				*	PFS by RP's gender and race and education
			
				*	Summary states PFS for selected group
				summ	PFS_ppml_noCOLI	[aw=wgt_long_ind]	if	ind_female==1	&	ind_edu_cat==1	&	ind_nonWhite==1, d	//	Non-white, women, less than HS
				summ	PFS_ppml_noCOLI	[aw=wgt_long_ind]	if	ind_female==0	&	ind_edu_cat==4	&	ind_nonWhite==0, d	//	white, men, college
			

			*	PFS by individual's gender and race and education

				
				*	Rescale FSSS
				loc	var	FSSS_rescale
				cap	drop	`var'
				gen	double	`var'	=	(9.3-HFSM_scale)/9.3
				replace	`var'=0	if	HFSM_raw==18	
				

				*	Rank correlation (CAUTION: Kendalls tau takes some time)
				spearman	PFS_ppml_noCOLI	FSSS_rescale, stats(rho obs p) star(0.05)
				ktau		PFS_ppml_noCOLI	FSSS_rescale, stats(taua taub obs p) star(0.05)
			

			
			*	Distribution of PFS over time, by category
				*	"lgraph" ssc ins required	 
				*	Overall 
				
				*	These two lone show that they generate the same mean estimates.
				summ	PFS_ppml_noCOLI	[aw=wgt_long_ind] if year==1997
				svy, subpop(if year==1997): mean PFS_ppml_noCOLI
				
							
				*	Figure 2
				lgraph PFS_ppml_noCOLI year [aw=wgt_long_ind], errortype(iqr) separate(0.01) title(PFS (1979-2019)) note(Interquantile) bgcolor(white)	///
					graphregion(color(white)) /*note(Source: USDA & BLS)*/	 yscale(range(0.5 1) titlegap(1)) 	ylabel(0.5(0.1)1) 	name(PFS_annual, replace) ytitle(Average)
					
				graph 	display PFS_annual, ysize(8) xsize(12.0)
				graph	export	"${SNAP_outRaw}/PFS_annual.png", replace
				graph	close
				
				
				
			
					*	(2025-5-10) Figure 2A - PFS plotting 5-10-15-20 percentile
					preserve
						collapse	(mean)	mean_PFS=PFS_ppml_noCOLI	mean_PFS_FI=PFS_FI_ppml_noCOLI	(p5) 	p5_PFS=PFS_ppml_noCOLI	(p10)	p10_PFS=PFS_ppml_noCOLI	///
									(p15)	p15_PFS=PFS_ppml_noCOLI		(p20)	p20_PFS=PFS_ppml_noCOLI [aw=wgt_long_ind], by(year)
									
						summ	mean_PFS	mean_PFS_FI p20_PFS	p5_PFS	//	11% FI prevalence rate
						
						graph	twoway	(connected	mean_PFS year)	/*(rcapsym p20_PFS p5_PFS  year) 	(rcapsym p15_PFS p10_PFS year)*/ (area p20_PFS  p5_PFS  year), bgcolor(white) graphregion(color(white))	///
						legend(lab (1 "Mean") lab(2 "20 percentile") lab(3 "5 percentile")  rows(1) pos(6))	///
						title(Trends and Distribution in PFS - 1979 to 2019)	name(PFS_annual_qtile, replace)	 ytitle(Probability)
						graph 	display PFS_annual_qtile, ysize(8) xsize(12.0)	
						
						graph	export	"${SNAP_outRaw}/PFS_annual_qtile.png", replace
						graph	close
					restore
		
	
		*	(2023-12-24) Food exp and TFP cost per capita (nominal and real)
		preserve
			collapse	(mean) HFSM_FI	PFS_ppml	PFS_FI_ppml_noCOLI	foodexp_W_TFP_pc	foodexp_W_TFP_pc_real	CPI	///
								foodexp_tot_inclFS_pc	foodexp_tot_inclFS_pc_real	[aw=wgt_long_ind], by(year)	//	weighted average by year
			
			graph	twoway	(line	foodexp_tot_inclFS_pc		year	if inrange(year,1979,2019),	lc(black) lp(solid) lwidth(medium)  graphregion(fcolor(white))) ///
							(line	foodexp_tot_inclFS_pc_real	year 	if inrange(year,1979,2019),	lc(blue) lp(shortdash) lwidth(medium)  graphregion(fcolor(white))) ///
							(line	foodexp_W_TFP_pc		year	if inrange(year,1979,2019),	lc(green) lp(dot) lwidth(medium)  graphregion(fcolor(white))) ///
							(line	foodexp_W_TFP_pc_real	year	if inrange(year,1979,2019),	lc(red) lp(dash) lwidth(medium)  graphregion(fcolor(white))),	///
							legend(order(1 "Food exp (nominal)" 2 "Food exp (real)"	3 "TFP (nominal)" 4 "TFP pc (real)") size(small) keygap(0.1) symxsize(5)) ///
							title("Food Expenditure and TFP cost per capita ($)") ytitle("Amount") xtitle("Year") name(FI_pravelence_measures, replace)
							graph	export	"${SNAP_outRaw}/Foodexp_TFP_pc_trend.png", as(png) replace
		restore
			
		
	
		*	Figure 3: Compute FI trend b/w PFS and FSSS
		preserve
				
			collapse	(mean) HFSM_FI	PFS_ppml_noCOLI	PFS_FI_ppml_noCOLI	foodexp_W_TFP_pc_real	FI_pct	[aw=wgt_long_ind], by(year)	//	weighted average by year
				
			summ	PFS_FI_ppml_noCOLI if inrange(year,1979,1999), d
			return list
		
			 *	Data manipulation for graph plot
			 set	obs	30
			 replace	year=1988 in 27
			 replace	year=1989 in 28
			 replace	year=1990 in 29
			 replace	year=1991 in 30
			 

			 
			 *	(2025-2-15) Import SNAP participation rate, poverty rate and unemployment from Census data
			 merge	1:1	year	using	"${SNAP_dtInt}/SNAP_1979_2019_census_annual"
			 replace	pov_rate_national	=	pov_rate_national/100
			 replace	unemp_rate	=	unemp_rate/100
			 
			 sort	year
			 
			 cap	drop	upper
			 gen	double	upper=0.2
			 
			
			*	(2024-12-9)	Somehow collapsed var has precision issue. Make a double-version of the same variable for plotting
			gen	double	PFS_FI_ppml_noCOLI_db	=	PFS_FI_ppml_noCOLI
			lab	var	PFS_FI_ppml_noCOLI_db	"Estimated to be food insecure"
			
			*	Figure 3	
			twoway	(bar	upper year if inrange(year, 1988, 1991), bcolor(gs14) barwidth(2)	graphregion(fcolor(white)))	///
					(line PFS_FI_ppml_noCOLI_db	year if inrange(year,1979,1987),	lc(blue) lp(solid) lwidth(medium)  graphregion(fcolor(white))) 	 ///
					(line PFS_FI_ppml_noCOLI_db	year if inrange(year,1992,2019),	lc(blue) lp(solid) lwidth(medium)  graphregion(fcolor(white))) 	 ///
					(connected HFSM_FI	year if inlist(year,1999,2001,2003), lc(red) lp(shortdash) lwidth(medium)	msymbol(circle)	graphregion(fcolor(white)))	 ///
					(connected HFSM_FI	year if inlist(year,2015,2017,2019), lc(red) lp(shortdash) lwidth(medium)	msymbol(circle) graphregion(fcolor(white)))		///
					(line FI_pct		year if inrange(year,1979,2019),	lc(black) lp(dash) lwidth(medium)  graphregion(fcolor(white))), 	 ///
					legend(order(2 "PFS" 4 "FSSS" /* 4 "USDA official (individual-level)" */) row(1) size(small) keygap(0.1) symxsize(5) pos(6)) /*yscale(range(0 0.2) titlegap(1)) ylabel(0(0.025)0.2)*/ ///
					note("Note: PFS is missing from 1988 to 1991 due to missing data in PSID")	///
					title("Food Insecurity Prevalence (1979-2019)") ytitle("Fraction") xtitle("Year") name(FI_pravelence_measures, replace)	
			
			graph 	display FI_pravelence_measures, ysize(8) xsize(12.0)
			
			graph	export	"${SNAP_outRaw}/PFS_FI_rate_PFS_FSSS.png", as(png) replace
			graph	close	
			
			
			
				
			
			*	Figure B1 (2025-2-15) Figure plotting PFS-based FI and other national statistics
			replace	GDP_growth_real	=	GDP_growth_real/100
			
			twoway	/*(bar	upper year if inrange(year, 1988, 1991), bcolor(gs14) barwidth(2)	graphregion(fcolor(white)))*/	///
					(line PFS_FI_ppml_noCOLI_db	year if inrange(year,1979,1987),	lc(blue) lp(solid) lwidth(medium)  graphregion(fcolor(white))) 	 ///
					(line PFS_FI_ppml_noCOLI_db	year if inrange(year,1992,2019),	lc(blue) lp(solid) lwidth(medium)  graphregion(fcolor(white))) 	 ///
					(line frac_SNAP_person		year if inrange(year,1979,2019), 	lc(red)	 lp(shortdash) lwidth(medium)	graphregion(fcolor(white)))	 ///
					(line unemp_rate			year if inrange(year,1979,2019),	lc(black) lp(dash) lwidth(medium)  graphregion(fcolor(white)))	 ///
					(line GDP_growth_real		year if inrange(year,1979,2019), 	lc(black)	 lp(dot) lwidth(medium)	graphregion(fcolor(white))),	///
					legend(order(1 "Food insecure (PFS-based)" 3 "SNAP participation " 4 "Unemployment Rate" 5 "GDP Growth" )	///
					row(2) size(small) keygap(0.1) symxsize(5) pos(6)) /*yscale(range(0 0.2) titlegap(1)) ylabel(0(0.025)0.2)*/ ///
					note("Note: PFS is missing from 1988 to 1991 due to missing data in PSID")	///
					title("Estimated Food Insecurity, SNAP Participation," "Poverty and GDP Growth Rates") ytitle("Fraction") xtitle("Year") name(PFS_SNAP_povrate, replace)	
			
			graph 	display PFS_SNAP_povrate, ysize(8) xsize(12.0)
			
			graph	export	"${SNAP_outRaw}/FigB1_PFS_FI_SNAP_unemp.png", as(png) replace
			
		restore
		
		
		
		*	Table 3 & 4: Food Security Status as estimated by PFS and FSSS
		
			*	Decompose into 4 categories.			
			loc	var	PFS_FI_FSSS_FI
			cap	drop	`var'
			gen	`var'=.
			replace	`var'=0	if	!mi(PFS_FI_ppml_noCOLI)	&	!mi(HFSM_FI)
			replace	`var'=1	if	PFS_FI_ppml_noCOLI==1	&	HFSM_FI==1
			lab	var	`var'	"FI(PFS) and FI(FSSS)"
			
			loc	var	PFS_FS_FSSS_FS
			cap	drop	`var'
			gen	`var'=.
			replace	`var'=0	if	!mi(PFS_FI_ppml_noCOLI)	&	!mi(HFSM_FI)
			replace	`var'=1	if	PFS_FI_ppml_noCOLI==0	&	HFSM_FI==0
			lab	var	`var'	"FS(PFS) and FS(FSSS)"
			
			loc	var	PFS_FI_FSSS_FS
			cap	drop	`var'
			gen	`var'=.
			replace	`var'=0	if	!mi(PFS_FI_ppml_noCOLI)	&	!mi(HFSM_FI)
			replace	`var'=1	if	PFS_FI_ppml_noCOLI==1	&	HFSM_FI==0
			lab	var	`var'	"FI(PFS) and FS(FSSS)"
			
			loc	var	PFS_FS_FSSS_FI
			cap	drop	`var'
			gen	`var'=.
			replace	`var'=0	if	!mi(PFS_FI_ppml_noCOLI)	&	!mi(HFSM_FI)
			replace	`var'=1	if	PFS_FI_ppml_noCOLI==0	&	HFSM_FI==1
			lab	var	`var'	"FS(PFS) and FI(FSSS)"
			
			summ	PFS_FI_FSSS_FI	PFS_FS_FSSS_FS	PFS_FI_FSSS_FS	PFS_FS_FSSS_FI
			summ	PFS_FI_FSSS_FI	PFS_FS_FSSS_FS	PFS_FI_FSSS_FS	PFS_FS_FSSS_FI	[aweight=wgt_long_ind]
			
				
				*	Table B4: Repeat it with the re-classified status (Table B4)			
				loc	var	PFS_FI_FSSS_FI_cps
				cap	drop	`var'
				gen	`var'=.
				replace	`var'=0	if	!mi(PFS_FI_ppml_noCOLI)	&	!mi(FSSS_FI_cps_base)
				replace	`var'=1	if	PFS_FI_ppml_noCOLI==1	&	FSSS_FI_cps_base==1
				lab	var	`var'	"FI(PFS) and FI(FSSS)"
				
				loc	var	PFS_FS_FSSS_FS_cps
				cap	drop	`var'
				gen	`var'=.
				replace	`var'=0	if	!mi(PFS_FI_ppml_noCOLI)	&	!mi(FSSS_FI_cps_base)
				replace	`var'=1	if	PFS_FI_ppml_noCOLI==0	&	FSSS_FI_cps_base==0
				lab	var	`var'	"FS(PFS) and FS(FSSS)"
				
				loc	var	PFS_FI_FSSS_FS_cps
				cap	drop	`var'
				gen	`var'=.
				replace	`var'=0	if	!mi(PFS_FI_ppml_noCOLI)	&	!mi(FSSS_FI_cps_base)
				replace	`var'=1	if	PFS_FI_ppml_noCOLI==1	&	FSSS_FI_cps_base==0
				lab	var	`var'	"FI(PFS) and FS(FSSS)"
				
				loc	var	PFS_FS_FSSS_FI_cps
				cap	drop	`var'
				gen	`var'=.
				replace	`var'=0	if	!mi(PFS_FI_ppml_noCOLI)	&	!mi(FSSS_FI_cps_base)
				replace	`var'=1	if	PFS_FI_ppml_noCOLI==0	&	FSSS_FI_cps_base==1
				lab	var	`var'	"FS(PFS) and FI(FSSS)"
				
				summ	PFS_FI_FSSS_FI_cps	PFS_FS_FSSS_FS_cps	PFS_FI_FSSS_FS_cps	PFS_FS_FSSS_FI_cps
				summ	PFS_FI_FSSS_FI_cps	PFS_FS_FSSS_FS_cps	PFS_FI_FSSS_FS_cps	PFS_FS_FSSS_FI_cps	[aweight=wgt_long_ind]
			
				
				*	About 2,800 of them got different status.
				tab	HFSM_FI	FSSS_FI_cps_base
			
				
			
			*	Table 3
			tabstat	PFS_FS_FSSS_FS	PFS_FI_FSSS_FI	PFS_FI_FSSS_FS	PFS_FS_FSSS_FI	[aw=wgt_long_ind] if inlist(year,1999,2001,2003,2015,2017,2019),	///
				statistics(/*count*/	mean		/*sd	min	 median	p95 max*/	) columns(statistics)  by(year)	save	// save
			
			mat	matching_PFS_FSSS	=	r(Stat1)	\	r(Stat2)	\	r(Stat3)	\	r(Stat4)	\	r(Stat5)	\	r(Stat6)	\	r(StatTotal)
			mat	matching_PFS_FSSS	=	matching_PFS_FSSS'	
			
			mat	rownames	matching_PFS_FSSS	=	"FS(PFS) and FS(FSSS)"	"FI(PFS) and FI(FSSS)"	"FI(PFS) and FS(FSSS)"	"FS(PFS) and FI(FSSS)"
			mat	colnames	matching_PFS_FSSS	=	"1999"	"2001"	"2003"	"2015"	"2017"	"2019"	"Total"
			mat	list	matching_PFS_FSSS
			
				*	Export
			putexcel	set "${SNAP_outRaw}/PFS_FSSS_FI_by_year.xlsx", sheet(Tab2_PFS_FSSS_match) replace /*modify*/
			putexcel	A5	=	matrix(matching_PFS_FSSS), names overwritefmt nformat(number_d2)	
				
				*	Table B4
				tabstat	PFS_FS_FSSS_FS_cps	PFS_FI_FSSS_FI_cps	PFS_FI_FSSS_FS_cps	PFS_FS_FSSS_FI_cps	[aw=wgt_long_ind] if inlist(year,1999,2001,2003,2015,2017,2019),	///
				statistics(/*count*/	mean		/*sd	min	 median	p95 max*/	) columns(statistics)  by(year)	save	// save
			
				mat	matching_PFS_FSSS_cps	=	r(Stat1)	\	r(Stat2)	\	r(Stat3)	\	r(Stat4)	\	r(Stat5)	\	r(Stat6)	\	r(StatTotal)
				mat	matching_PFS_FSSS_cps	=	matching_PFS_FSSS_cps'	
				
				mat	rownames	matching_PFS_FSSS_cps	=	"FS(PFS) and FS(FSSS)"	"FI(PFS) and FI(FSSS)"	"FI(PFS) and FS(FSSS)"	"FS(PFS) and FI(FSSS)"
				mat	colnames	matching_PFS_FSSS_cps	=	"1999"	"2001"	"2003"	"2015"	"2017"	"2019"	"Total"
				mat	list	matching_PFS_FSSS_cps
				
					*	Export
				putexcel	set "${SNAP_outRaw}/PFS_FSSS_FI_by_year.xlsx", sheet(TabB4_PFS_FSSS_match) modify
				putexcel	A5	=	matrix(matching_PFS_FSSS_cps), names overwritefmt nformat(number_d2)	

	
			*	Table 4
			*	Summary stats based on FS status
			
				*	(2025-2-16) Panel (a) matching status by category (Responding 4th R&R  comments)
		
			
			
			*	Mismatch probability
				
				loc	summvars	PFS_FS_FSSS_FS  PFS_FS_FSSS_FI  PFS_FI_FSSS_FS  PFS_FI_FSSS_FI 
				tabstat	`summvars' [aweight = wgt_long_ind] ,	statistics(mean	/* sd	min	  max	sd	min	 median	p95 max*/	) columns(variables)  save
				
				cap	mat	drop	matching_PFS_FSSS
				mat	matching_PFS_FSSS	=	 r(StatTotal)
				mat list matching_PFS_FSSS

				*	By category
				loc conditions rp_female==0 rp_female==1	rp_nonWhte==0	rp_nonWhte==1	rp_married==1	rp_married==0	rp_disabled==0	rp_disabled==1	rp_NoHS==1	rp_col==1
				foreach	cond of loc conditions {
					
					//cap	mat	drop	matching_PFS_FSSS_temp
					
					tabstat	`summvars' [aweight = wgt_long_ind] if `cond',	statistics(mean	/* sd	min	  max	sd	min	 median	p95 max*/	) columns(variables)   save
					
					//mat	matching_PFS_FSSS_temp	=	e(PFS_FS_FSSS_FS), e(PFS_FS_FSSS_FI), e(PFS_FI_FSSS_FS), e(PFS_FI_FSSS_FI) 
					mat	matching_PFS_FSSS	=	matching_PFS_FSSS	\	r(StatTotal)
					
				}
				
				mat	rownames	matching_PFS_FSSS	=	"Total" "Male"	"Female" "White" "Non-White" "Not married" "Married" "Not disabled" "Disabled" "Less than high school" "College"
				mat	colnames	matching_PFS_FSSS	=	"FS(PFS) and FS(FSSS)"	"FS(PFS) and FI(FSSS)"	"FI(PFS) and FS(FSSS)"	"FI(PFS) and FI(FSSS)"
				mat list matching_PFS_FSSS
				
					*	Export
				
				putexcel	set "${SNAP_outRaw}/PFS_FSSS_by_characters.xlsx", sheet(Tab4_panela_PFS_FSSS_match) replace
				putexcel	A5	=	matrix(matching_PFS_FSSS), names overwritefmt nformat(number_d2)	
			
			
				*	Panel (b)
				
				loc	summvars	rp_female	rp_age	rp_nonWhte	rp_married	rp_disabled	rp_NoHS		///
							famnum	ln_fam_income_pc_real	foodexp_tot_inclFS_pc_1_real	PFS_ppml_noCOLI HFSM_raw	
			
				*	Full sample
				estpost tabstat	`summvars' 	if	!mi(PFS_ppml_noCOLI)	&	!mi(PFS_FS_FSSS_FI)	[aw=wgt_long_ind],	///
					statistics(count	mean	sd	min	max) columns(statistics)	// save
				est	store	PFS_FSSS_full
				
				*	FS(PFS)/FS(FSSS) individuals
				estpost tabstat	`summvars' 	if	!mi(PFS_ppml_noCOLI)	&	PFS_FS_FSSS_FS==1	[aw=wgt_long_ind],	///
					statistics(count	mean	sd	min	max) columns(statistics)	// save
				est	store	PFS_FS_FSSS_FS
				
				*	FS(PFS)/FI(FSSS) individuals
				estpost tabstat	`summvars' 	if	!mi(PFS_ppml_noCOLI)	&	PFS_FS_FSSS_FI==1	[aw=wgt_long_ind],	///
					statistics(count	mean	sd	min	max) columns(statistics)	// save
				est	store	PFS_FS_FSSS_FI
				
				*	FI(PFS)/FS(FSSS) individuals
				estpost tabstat	`summvars' 	if	!mi(PFS_ppml_noCOLI)	&	PFS_FI_FSSS_FS==1	[aw=wgt_long_ind],	///
					statistics(count	mean	sd	min	max) columns(statistics)	// save
				est	store	PFS_FI_FSSS_FS
				
				*	FI(PFS)/FI(FSSS) individuals
				estpost tabstat	`summvars' 	if	!mi(PFS_ppml_noCOLI)	&	PFS_FI_FSSS_FI==1	[aw=wgt_long_ind],	///
					statistics(count	mean	sd	min	max) columns(statistics)	// save
				est	store	PFS_FI_FSSS_FI
				
				
			
			esttab	/*PFS_FSSS_full*/	PFS_FS_FSSS_FS	PFS_FS_FSSS_FI	PFS_FI_FSSS_FS	PFS_FI_FSSS_FI	using	"${SNAP_outRaw}/summstat_by_status.csv",  ///
				cells("mean(fmt(%12.2f)) sd(fmt(%12.2f))") label	title("Summary Statistics - FS(PFS) and FI(FSSS)") noobs 	  replace
		
		
			*	dtable version (panel b only)
			lab	var	foodexp_tot_inclFS_pc_1_real	"Food expenditure per capita (including SNAP benefit)"
			lab	define	rp_edu_cat	4	"Has college degree (RP)", modify
			lab	var	HFSM_raw	"FSSS (raw score)"
			
			local	tab4_contvar	rp_age	famnum	ln_fam_income_pc_real	foodexp_tot_inclFS_pc_1_real	PFS_ppml_noCOLI	HFSM_raw
			local	tab4_factvar	rp_female	rp_nonWhte	rp_married	rp_disabled	rp_edu_cat
		
		
			 cap	collect	drop	tab4_PFS_FS_FSSS_FS
			 dtable 	if	!mi(PFS_ppml_noCOLI)	&	PFS_FS_FSSS_FS==1	[aweight = wgt_long_ind], sample(, statistic(frequency) ) ///
				continuous(`tab4_contvar', statistics( mean sd)) factor(`tab4_factvar', statistics( fvpercent)) ///
				nformat(%9.0fc  frequency ) nformat(%9.2fc  mean sd) nformat(%9.1fc  fvpercent ) name(tab4_PFS_FS_FSSS_FS)
				
			 cap	collect	drop	tab4_PFS_FS_FSSS_FI
			 dtable 	if	!mi(PFS_ppml_noCOLI)	&	PFS_FS_FSSS_FI==1	[aweight = wgt_long_ind], sample(, statistic(frequency) ) ///
				continuous(`tab4_contvar', statistics( mean sd)) factor(`tab4_factvar', statistics( fvpercent)) ///
				nformat(%9.0fc  frequency ) nformat(%9.2fc  mean sd) nformat(%9.1fc  fvpercent ) name(tab4_PFS_FS_FSSS_FI)	
				
			 cap	collect	drop	tab4_PFS_FI_FSSS_FS
			 dtable 	if	!mi(PFS_ppml_noCOLI)	&	PFS_FI_FSSS_FS==1	[aweight = wgt_long_ind], sample(, statistic(frequency) ) ///
				continuous(`tab4_contvar', statistics( mean sd)) factor(`tab4_factvar', statistics( fvpercent)) ///
				nformat(%9.0fc  frequency ) nformat(%9.2fc  mean sd) nformat(%9.1fc  fvpercent ) name(tab4_PFS_FI_FSSS_FS)	
				
			 cap	collect	drop	tab4_PFS_FI_FSSS_FI
			 dtable 	if	!mi(PFS_ppml_noCOLI)	&	PFS_FI_FSSS_FI==1	[aweight = wgt_long_ind], sample(, statistic(frequency) ) ///
				continuous(`tab4_contvar', statistics( mean sd)) factor(`tab4_factvar', statistics( fvpercent)) ///
				nformat(%9.0fc  frequency ) nformat(%9.2fc  mean sd) nformat(%9.1fc  fvpercent ) name(tab4_PFS_FI_FSSS_FI)
				
			cap	collect	drop	tab4_all
			collect combine tab4_all = tab4_PFS_FS_FSSS_FS	tab4_PFS_FS_FSSS_FI		tab4_PFS_FI_FSSS_FS	tab4_PFS_FI_FSSS_FI
			
			collect style autolevels result frequency mean sd fvproportion fvpercent, clear
		
			collect label levels cmdset 1 "Summary"
			collect style header result, level(hide)	
			collect layout (var[_N]#result rp_female[1]#result var[rp_age]#result rp_nonWhte[1]#result rp_married[1]#result rp_disabled[1]#result rp_edu_cat[1]#result	///
					var[famnum]#result	var[ln_fam_income_pc_real]#result	var[foodexp_tot_inclFS_pc_1_real]#result	var[PFS_ppml_noCOLI]#result	var[HFSM_raw]#result) (collection) (cmdset)
			
			
			collect	export	"${SNAP_outRaw}/Table4.docx", replace as(docx)
			
		
			
	


	
	
			
			
/*
			estpost tabstat	PFS_FS_FSSS_FS	PFS_FI_FSSS_FI	PFS_FI_FSSS_FS	PFS_FS_FSSS_FI	[aw=wgt_long_ind],	statistics(count	mean		/*sd	min	 median	p95 max*/	) columns(statistics)  by(year)		// save
			est	store	PFS_FSSS_FI_by_year

			*	Export table 2
			esttab	PFS_FSSS_FI_by_year	using	"${SNAP_outRaw}/PFS_FSSS_FI_by_year.csv",  ///
					cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace
		
*/
		
		
					
			
			* PFS by RP's gender and race and education
			graph	box	PFS_ppml_noCOLI		[aw=wgt_long_ind], over(rp_female, sort(1)) over(rp_nonWhte, sort(1))	over(rp_edu_cat, sort(1)) ///
					nooutsides name(outcome_subgroup_rp, replace) title(Food Security by Subgroup) note("")
			graph	export	"${SNAP_outRaw}/PFS_by_rp_subgroup.png", replace	
			graph	close
			
			
			*	Figure 4: PFS by individual's sex, race and education
			
			
				*	Cleaning for Individual race label
				lab	define	ind_nonWhite	0	"White"	1	"Non-White", replace
				lab	val	ind_nonWhite	ind_nonWhite
		
				
				graph	box	PFS_ppml_noCOLI		[aw=wgt_long_ind], over(ind_female, sort(1)) over(ind_nonWhite, sort(1))	over(ind_edu_cat, sort(1)) nooutsides ///
					bgcolor(white)	graphregion(color(white))	legend(pos(6) row(1)) ///
					name(outcome_subgroup_ind, replace) title(Estimated Food Security by Subgroup) note("")	///
					note("Extreme values – smaller than the lower quartile minus 1.5 times interquartile range,"  "or greater than the upper quartile plus 1.5 times interquartile range – are not plotted.")
				
				graph display outcome_subgroup_ind, ysize(8) xsize(12.0)
				graph	export	"${SNAP_outRaw}/PFS_by_ind_subgroup.png", replace	
				graph	close
				
				
				*	Stats in the text
				summ	PFS_ppml_noCOLI [aw=wgt_long_ind]	if	ind_female==1	&	ind_nonWhite==1	&	ind_edu_cat==1, d
				summ	PFS_ppml_noCOLI [aw=wgt_long_ind]	if	ind_female==0	&	ind_nonWhite==0	&	ind_edu_cat==4, d
				
				
				*	Missing values
				tab	ind_White,m
				unique	x11101ll	if	mi(ind_White)
				tab	ind_edu_cat,m
				unique	x11101ll	if	mi(ind_edu_cat)
					
// 			*	Figure 5: Annual PFS
// 			*	"lgraph" ssc ins required	 
// 				*	Overall 
//				
// 				*	These two lone show that they generate the same mean estimates.
// 				summ	PFS_ppml_noCOLI	[aw=wgt_long_ind] if year==1997
// 				svy, subpop(if year==1997): mean PFS_ppml_noCOLI
//				
// 				lgraph PFS_ppml_noCOLI year [aw=wgt_long_ind], errortype(iqr) separate(0.01) title(PFS) note(25th and 75th percentile) name(PFS_annual)
// 				graph 	display PFS_annual, ysize(4) xsize(9.0)
// 				graph	export	"${SNAP_outRaw}/PFS_annual.png", replace
// 				graph	close
//		
		
	/***************************************************************
		SECTION 3: Regression
	***************************************************************/		 
					
		
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		
		lab	var	rp_married	"Married (RP)"
		lab	var	rp_NoHS		"Less than HS (RP)"
		lab	var	rp_HS		"High School (RP)"
		lab	var	rp_somecol	"Some college (RP)"
		lab	var	rp_col		"College (RP)"
		lab	var	rp_employed	"Employed (RP)"
		lab	var	rp_disabled	"Disabled (RP)"
		
		lab	var	age_ind		"Age (ind)"
		lab	var	ind_NoHS	"Less than HS (ind)"
		lab	var	ind_HS		"High School (ind)"
		lab	var	ind_somecol	"Some college (ind)"
		lab	var	ind_col		"College (ind)"
		
		
		*	We do three different outcomes: PFS, FSSS (re-scaled) and NME
		*	No longer used
		/*
		{	
		lab	var	PFS_ppml_noCOLI	"PFS (w/o COLI)"
		lab	var	HFSM_scale		"FSSS (scaled)"
		lab	var	NME				"Normalized Monetary Score"
		*	For each variable, I will use two different verions; raw variable and standardized variable
		
			foreach	var	in		PFS_ppml_noCOLI	HFSM_scale	NME	{
			    
				cap	drop	`var'_std
				summ	`var'
				gen	`var'_std	=	(`var'-r(mean))/r(sd)
				
				
			}
			
		lab	var	PFS_ppml_noCOLI_std	"PFS (w/o COLI) - standardized"
		lab	var	HFSM_scale_std		"FSSS (scaled) - standardized"
		lab	var	NME_std				"NME - standardized"
			}
		*/
		*	We do three different specifications; year FE, year and state-FE, and region+year+indiv FE
		loc	outcome_PFS		PFS_ppml_noCOLI
		loc	outcome_FSSS	HFSM_scale
		loc	outcome_NME		NME
		
			*	Set globals
		*global	statevars		l2_foodexp_tot_inclFS_pc_1_real	l2_foodexp_tot_inclFS_pc_2_real 
		global	demovars		rp_age rp_age_sq	rp_nonWhte	rp_married	rp_female	
		global	econvars		ln_fam_income_pc_real	
		global	healthvars		rp_disabled
		global	familyvars		famnum	ratio_child	change_RP
		global	empvars			rp_employed
		global	eduvars			rp_NoHS rp_somecol rp_col
		global	foodvars		FS_rec_wth
		global	macrovars		unemp_rate	CPI
		global	regionvars		rp_state_enum2-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
		*global	timevars		year_enum4-year_enum11 year_enum14-year_enum30 //	Exclude year_enum3 (1978) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
		global	timevars		year_enum4-year_enum11 year_enum14-year_enum30	//	Using year_enum18 (1996) as a base year, when regressing with SNAP index IV (1996-2013)
		global	indvars			/*ind_female*/ age_ind	age_ind_sq ind_NoHS ind_somecol ind_col /* ind_employed_dummy*/
		

				*	State and year FE, no individual vars
					
					*	No individual vars
					reghdfe	PFS_ppml_noCOLI ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	/*${indvars}*/		[aweight=wgt_long_ind],	///
						vce(cluster x11101ll) absorb(rp_state year)	/*noabsorb*/
					est	store	PFS_ysFE_noind
					
					*	Individual vars
					reghdfe	PFS_ppml_noCOLI ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	${indvars}		[aweight=wgt_long_ind],	///
						vce(cluster x11101ll) absorb(rp_state year)	/*noabsorb*/
					est	store	PFS_ysFE_ind
				
				*	State- and Year-FE, Individual FE
				
					
					*	OLS
					reghdfe	PFS_ppml_noCOLI ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	/*${indvars}*/		[aweight=wgt_long_ind],	///
						vce(cluster x11101ll) absorb(rp_state year	x11101ll)	/*noabsorb*/
					est	store	PFS_ysiFE_noind
					
					*	Individual vars
					reghdfe	PFS_ppml_noCOLI ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	${indvars}		[aweight=wgt_long_ind],	///
						vce(cluster x11101ll) absorb(rp_state year	x11101ll)	/*noabsorb*/
					est	store	PFS_ysiFE_ind
				
					
				*	Table B2
				
					*	Regression coefficients
						
					*	OLS
					esttab	PFS_ysFE_noind	PFS_ysFE_ind	PFS_ysiFE_noind		PFS_ysiFE_ind	using "${SNAP_outRaw}/PFS_on_HH X.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(PFS on HH Characteristics)		replace	
					
				
			
	/***************************************************************
		SECTION 4: Dynamics analyses
	***************************************************************/		 
					
		
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		svyset	sampcls [pweight=wgt_long_ind] ,strata(sampstr)   singleunit(scaled)	
		
			*	Spell length by subgroup
			cap	mat	drop	summstat_spell_length
			
				*	Note that the following two line generate the different results, wonder why...
				*	For now I will simply use wgt_long_ind without adjusting survey structure, to be consistent with earlier estiamtes.
				*svy, subpop(if _end==1): mean _seq
				*summ	_seq if _end==1
			
			
			summ	_seq if _end==1
			mat	summstat_spell_length	=	r(N), r(mean), r(sd)
			mat	list	summstat_spell_length
			
			*	The following commands are when using svy-structure adjusted estimates.
			/*
			svy, subpop(if _end==1): mean _seq
			estat sd
			mat	summstat_spell_length	=	e(N_sub), r(mean), r(sd)
			mat	list	summstat_spell_length
			*/

			
			
			*	By category (gender, race, education, region, disability)
			foreach	catvar	in	rp_female rp_nonWhte	rp_edu_cat	rp_region rp_disabled	{
						
				di	"catvar is `catvar'"
				
				if	inlist("`catvar'","rp_region")	{	//	region (1-5)
					
					loc	catval	1	2	3	4	5
					
				}	//	region
				
				else	if	inlist("`catvar'","rp_edu_cat")	{	//	edu (1-4)
					
					loc	catval	1	2	3	4		
				
				}	//	edu
				
				else	{	//	binary (0-1)
					
					loc	catval	0	1		
					
				}	//	binary
				
				foreach	val	of	local	catval	{		
					
					di	"value is `val'"
					qui	summ	_seq	if	_end==1	&	`catvar'==`val'
					mat	summstat_spell_length	=	summstat_spell_length	\		(r(N), r(mean), r(sd))
					
					
					*	For svy-structure adjusted estimates.
					/*
					qui	svy, subpop(if _end==1	&	`catvar'==`val'): mean _seq
					estat	sd
					mat	summstat_spell_length	=	summstat_spell_length	\		(e(N_sub), r(mean), r(sd))
					*/
					
				}	//	val		
				
			}	//	catvar
			
			mat	colnames	summstat_spell_length	=	"N"	"Mean"	"SD"
			mat	rownames	summstat_spell_length	=	"All"	"Male"	"Female"	"White"	"Non-White"	"Less than HS"	"HS"	"Some college"	"College"	///
														"Northeast"	"Mid-Atlantic"	"South"	"Midwest"	"West"	"NOT disabled"	"Disabled"
				
			mat	list	summstat_spell_length
			
			putexcel	set	"${SNAP_outRaw}/spell_length_table", sheet(summstat) replace
			putexcel	A5	=	matrix(summstat_spell_length), names overwritefmt nformat(number_d1)
			
			
			
			
		*	Distribution of spell length	
		*	Since "hist" does not accept aweight, we use the percentage in frequency table
		*	Note (2023-08-03) I eyeballed that the percentage in weighted tabluate "tab [aw=]" is equal to the proportion with svy previs "svy: proportion"
		*	Thus if I am interested in that percentage, I can use "tab aw" which is more convenient.
	
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		cap	mat	drop	spell_pct_all
		
		*	All sample
			tab	_seq	[aw=wgt_long_ind]	if	_end==1,	matcell(spell_freq_w)
			mat	list	spell_freq_w
			local	N=r(N)
			mat	spell_pct_tot	=	spell_freq_w	/	r(N)
			
			mat	spell_pct_all		=	nullmat(spell_pct_all),	spell_pct_tot
			mat	list	spell_pct_all
		

	
	*	Figures
	
	preserve
	
		clear
		set	obs	26
		gen	spell_length	=	_n
		
		svmat	spell_pct_all
		
		rename	spell_pct_all?	(spell_pct_all	/* spell_pct_male	spell_pct_female	spell_pct_nonWhite	spell_pct_White */	/*spell_pct_nocol	spell_pct_col*/)
		lab	var	spell_length	"Spell Length"
		
		*	Y-axis title in h-bar
		gen	ytitle=22	//	https://www.statalist.org/forums/forum/general-stata-discussion/general/1457183-create-title-of-categorical-axis-in-hbar
		lab	def	ytitle	22	"Spell Length"
		lab	val	ytitle	ytitle
		*	Figures
			
/*
			
			graph hbar spell_pct_all, over(spell_length, sort(spell_percent_w) /*descending*/	label(labsize(vsmall)))	legend(lab (1 "Fraction") size(small) rows(1))	///
				bar(1, fcolor(gs03*0.5)) /*bar(2, fcolor(gs10*0.6))*/ graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length) ytitle(Fraction)
		
			graph	export	"${SNAP_outRaw}/Spell_length_dist.png", replace
			
*/
			*	Figure 5: All population
			graph hbar spell_pct_all, over(spell_length, sort(spell_percent_w)  /*descending*/	label(labsize(vsmall))) over(ytitle, label(angle(90) labsize(small)))	///
				bar(1, fcolor(gs03*0.5)) /*bar(2, fcolor(gs10*0.6))*/ ytitle(Fraction) graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length) name(dist_spell_length, replace)
			
			graph display dist_spell_length, ysize(8) xsize(12.0)
			graph	export	"${SNAP_outRaw}/Spell_length_dist.png", as(png) replace
			graph	close
			
			
			/*	2025-6-10 (disabled gender-and race)
			*	By gender
			graph hbar spell_pct_male	spell_pct_female, over(spell_length, /*descending*/	label(labsize(vsmall)))	legend(lab (1 "Male") lab(2 "Female") size(small) rows(1))	///
				bar(1, fcolor(gs03*0.5)) bar(2, fcolor(gs10*0.6))	graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length - By Gender) ytitle(Fraction)
		
			graph	export	"${SNAP_outRaw}/Spell_length_dist_gender.png", replace
			graph	close
			
			*	By race
			graph hbar spell_pct_White	spell_pct_nonWhite, over(spell_length, /*descending*/	label(labsize(vsmall)))	legend(lab (1 "White") lab(2 "Non-White") size(small) rows(1))	///
				bar(1, fcolor(gs03*0.5)) bar(2, fcolor(gs10*0.6))	graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length - By Race) ytitle(Fraction)
		
			graph	export	"${SNAP_outRaw}/Spell_length_dist_race.png", replace
			graph	close
			
			*/
			
			/* Disabled as of 2024-9-22. See the comment above.
			*	By education (college degree)
			graph hbar spell_pct_col	spell_pct_nocol, over(spell_length, /*descending*/	label(labsize(vsmall)))	legend(lab (1 "College degree") lab(2 "No college degree") size(small) rows(1))	///
				bar(1, fcolor(gs03*0.5)) bar(2, fcolor(gs10*0.6))	graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length - By College) ytitle(Fraction)
		
			graph	export	"${SNAP_outRaw}/Spell_length_dist_college.png", replace
			graph	close
			*/
					
	restore
	
			
		
		
		
		
	*	 (2023-08-10) Transition matrix
	*	 (2023-12-19) Changed RP-level to ind-level
		
		*	Declare macros for each categorical condition
		
		local	all_cond	inrange(year,1981,2019)	//	INclude all obs
		
		local	yr_1981_1990_cond	inrange(year,1981,1990)
		local	yr_1991_2000_cond	inrange(year,1991,2000)
		local	yr_2001_2010_cond	inrange(year,2001,2010)
		local	yr_2011_2019_cond	inrange(year,2011,2019)
		
		local	female_cond		ind_female==1	//	rp_female==1
		local	male_cond		ind_female==0	//	rp_female==0
		
		local	nonWhite_cond	ind_nonWhite==1	//	rp_White==0
		local	White_cond		ind_White==1	//	rp_White==1
		
// 		local	NE_cond			rp_region_NE==1 
// 		local	MidAt_cond		rp_region_MidAt==1
// 		local	South_cond		rp_region_South==1
// 		local	MidWest_cond	rp_region_MidWest==1
// 		local	West_cond		rp_region_West==1
		
		local	NoHS_cond		ind_NoHS	//	rp_NoHS==1 
		local	HS_cond			ind_HS	//	rp_HS==1
		local	somecol_cond	ind_somecol	//	rp_somecol==1 
		local	col_cond		ind_col	//	rp_col==1
		   
// 		local	disab_cond		rp_disabled==1
// 		local	nodisab_cond	rp_disabled==0
//		
// 		local	SNAP_cond		FS_rec_wth==1
// 		local	noSNAP_cond		FS_rec_wth==0
		
		lab	var	FS_rec_wth	"Received SNAP"
		
		
		loc	categories	all	yr_1981_1990	yr_1991_2000	yr_2001_2010	yr_2011_2019	///
						female	male	nonWhite	White	/*NE	MidAt	South	MidWest	West*/	///
						NoHS	HS	somecol	col	/*disab	nodisab	SNAP	noSNAP*/
		
		*	Loop over categories
		*	NOTE: the joint tabulate command below generates the same relative frequency to the one using "svy:". I use this one for computation speed.
		cap	mat	drop	trans_2by2_combined
		cap	mat	drop	trans_2by2_entry_byyr
		cap	mat	drop	trans_2by2_persistence_byyr
		cap	mat	drop	trans_2by2_chronic_byyr
		
		mat	define	blankrow	=	J(1,7,.)
		mat	rownames	blankrow	=	""
		
		mat	define	blankrow_4col	=	J(1,4,.)
		mat	rownames	blankrow_4col	=	""
		
		foreach	cat	of	local	categories	{
			
			di	"cat is `cat'"
			
			*	Joint
			tab		l2_PFS_FS_ppml_noCOLI	PFS_FS_ppml_noCOLI	[aw=wgt_long_ind]		if	``cat'_cond'	& inrange(year,1981,2019), cell matcell(trans_2by2_joint_`cat')
			scalar	samplesize_`cat'	=	trans_2by2_joint_`cat'[1,1] + trans_2by2_joint_`cat'[1,2] + trans_2by2_joint_`cat'[2,1] + trans_2by2_joint_`cat'[2,2]	//	calculate sample size by adding up all
			mat trans_2by2_joint_`cat' = trans_2by2_joint_`cat'[1,1], trans_2by2_joint_`cat'[1,2], trans_2by2_joint_`cat'[2,1], trans_2by2_joint_`cat'[2,2]	//	Make it as a row matrix
			mat trans_2by2_joint_`cat' = trans_2by2_joint_`cat'/samplesize_`cat'	//	Divide it by sample size to compute relative frequency
			mat	list	trans_2by2_joint_`cat'	
			
			*	Marginal
			tab		PFS_FS_ppml_noCOLI	[aw=wgt_long_ind]			if	l2_PFS_FS_ppml_noCOLI==0	& inrange(year,1981,2019)	&	``cat'_cond', matcell(temp)	//	Previously FI
			scalar	persistence_`cat'	=  temp[1,1] / (temp[1,1] + temp[2,1])	//	Persistence rate (FI, FI)
			tab		PFS_FS_ppml_noCOLI	[aw=wgt_long_ind]			if	l2_PFS_FS_ppml_noCOLI==1	& inrange(year,1981,2019)	&	``cat'_cond', matcell(temp)	//	Previously FS
			scalar	entry_`cat'			=  temp[1,1] / (temp[1,1] + temp[2,1])	//	Entry rate (FS, FI)
			
				
			*	Combined (Joint + marginal)
			mat	trans_2by2_`cat'	=	samplesize_`cat',	trans_2by2_joint_`cat',	persistence_`cat',	entry_`cat'	
			mat	rownames	trans_2by2_`cat'	=	"`cat'"
			
			*	Acuumulate rows
			if	inlist("`cat'","yr_1981_1990","female","nonWhite","NE","NoHS","disab","SNAP")	{
				
				mat		trans_2by2_combined	=	nullmat(trans_2by2_combined) \ 	blankrow	\	trans_2by2_`cat'	//	Add a blank row at the beginning of subcategory.
				
			}
			else	{
				
				mat		trans_2by2_combined	=	nullmat(trans_2by2_combined) \ trans_2by2_`cat'	//	Add a blank row at the end of subcategory.
				
			}
			
							
			di	"This line is executed, and cat is `cat'"
			
			*	For gender/race/education, repeat for each time-period (1981-1990, 1991-2000, 2001-2010, 2011-2020)
			if	inlist("`cat'","female","male","nonWhite","White","NoHS","HS","somecol","col")	{
				
				di	"Dat line is executed, and cat is `cat'"
				forval	startyear=1981(10)2011	{
					
					local	endyear=`startyear'+9
					di		"startyear is `startyear'"
					di		"endyear is `endyear'"
					
					*	Joint
					tab		l2_PFS_FS_ppml_noCOLI	PFS_FS_ppml_noCOLI	[aw=wgt_long_ind]		if	``cat'_cond'	& inrange(year,`startyear',`endyear'), cell matcell(trans_2by2_joint_`cat')
					scalar	samplesize_`cat'_`startyear'	=	trans_2by2_joint_`cat'[1,1] + trans_2by2_joint_`cat'[1,2] + trans_2by2_joint_`cat'[2,1] + trans_2by2_joint_`cat'[2,2]	//	calculate sample size by adding up all
					mat trans_2by2_joint_`cat'_`startyear' = trans_2by2_joint_`cat'[1,1], trans_2by2_joint_`cat'[1,2], trans_2by2_joint_`cat'[2,1], trans_2by2_joint_`cat'[2,2]	//	Make it as a row matrix
					mat trans_2by2_joint_`cat'_`startyear' = trans_2by2_joint_`cat'/samplesize_`cat'_`startyear'	//	Divide it by sample size to compute relative frequency
					mat	list	trans_2by2_joint_`cat'_`startyear'
					scalar	chronic_`cat'_`startyear'	=	trans_2by2_joint_`cat'_`startyear'[1,1]	//	FI in two consecutive waves
					scalar	list	chronic_`cat'_`startyear'
					
					*	Marginal
					tab		PFS_FS_ppml_noCOLI	[aw=wgt_long_ind]			if	l2_PFS_FS_ppml_noCOLI==0	& inrange(year,`startyear',`endyear')	&	``cat'_cond', matcell(temp)	//	Previously FI
					scalar	persistence_`cat'_`startyear'	=  temp[1,1] / (temp[1,1] + temp[2,1])	//	Persistence rate (FI, FI)
					tab		PFS_FS_ppml_noCOLI	[aw=wgt_long_ind]			if	l2_PFS_FS_ppml_noCOLI==1	& inrange(year,`startyear',`endyear')	&	``cat'_cond', matcell(temp)	//	Previously FS
					scalar	entry_`cat'_`startyear'		=  temp[1,1] / (temp[1,1] + temp[2,1])	//	Entry rate (FS, FI)
						
						
				}	//	startyear
				
				*	Add up persistence and entry rate year
				foreach	type	in	chronic persistence	entry	{
					
					cap	mat	drop	`type'_`cat'_byyear
					mat	`type'_`cat'_byyear	=	`type'_`cat'_1981, `type'_`cat'_1991, `type'_`cat'_2001, `type'_`cat'_2011
					mat	rownames	`type'_`cat'_byyear	=	"`cat'"
					
				}	//	type
				
				
				*	Acuumulate rows
				if	inlist("`cat'","female","nonWhite","NoHS")	{
					
					foreach	type	in	chronic persistence	entry	{
					
						mat		trans_2by2_`type'_byyr	=	nullmat(trans_2by2_`type'_byyr) \ 	blankrow_4col	\	`type'_`cat'_byyear	//	Add a blank row at the beginning of subcategory.
						
					}	//	type
					
				}
				else	{
					
					foreach	type	in	chronic persistence	entry	{
					
						mat		trans_2by2_`type'_byyr	=	nullmat(trans_2by2_`type'_byyr) \ 	`type'_`cat'_byyear	//	
						
					}	//	type
				}
			
			
				
			}	//	if inlist
			
			
		
			
			
		}
		
		mat	colnames	trans_2by2_combined			=	"N"	"Insecure in both rounds" "Insecure in 1st round only" "Insecure in 2nd round only" "Secure in both rounds" "Persistence" "Entry"
		mat	list		trans_2by2_combined
		mat	colnames	trans_2by2_persistence_byyr	=	"1981-1990" "1991-2000" "2001-2010" "2011-2020"
		mat	colnames	trans_2by2_entry_byyr	=	"1981-1990" "1991-2000" "2001-2010" "2011-2020"
		mat	colnames	trans_2by2_chronic_byyr	=	"1981-1990" "1991-2000" "2001-2010" "2011-2020"
		
		mat	list	trans_2by2_persistence_byyr
		mat	list	trans_2by2_entry_byyr
		mat	list	trans_2by2_chronic_byyr
		
		*	Export Table 5
		putexcel	set "${SNAP_outRaw}/Trans_matrix_7919_ind", sheet(Fig_3) replace /*modify*/
		putexcel	A5	=	matrix(trans_2by2_combined), names overwritefmt nformat(number_d2)	//	3a
		putexcel	A40	=	matrix(trans_2by2_persistence_byyr), names overwritefmt nformat(number_d2)	//	3a
		putexcel	A55	=	matrix(trans_2by2_entry_byyr), names overwritefmt nformat(number_d2)	//	3a
		putexcel	A70	=	matrix(trans_2by2_chronic_byyr), names overwritefmt nformat(number_d2)	//	Table 4
		
		*	Table 6
		putexcel	set "${SNAP_outRaw}/Trans_matrix_7919_ind", sheet(Tab6_chronic_FI_by_decade) modify
		putexcel	A5	=	matrix(trans_2by2_chronic_byyr), names overwritefmt nformat(number_d2)	//	3a
		
		
		*	Make it as a graph
		
		/*	Equivalent, but takes longer time to run. I just leave it as a reference
		svy, subpop(if rp_female==0):	tab	l2_PFS_FS_ppml_noCOLI	PFS_FS_ppml
		mat	trans_2by2_joint_male = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
		*/
		
		
		
		
		*	Conpare dynamics - PFS and FSSS
		sort	x11101ll	year
		cap	drop	HFSM_FS
		cap	drop	l2_HFSM_FI
		cap	drop	l2_HFSM_FS
		gen	HFSM_FS	=	HFSM_FI
		recode	HFSM_FS	(1=0)	(0=1)
		gen	l2_HFSM_FI	=	l2.HFSM_FI
		gen	l2_HFSM_FS	=	l2.HFSM_FS
	

		loc	PFS_FS_ppml_noCOLI_name	PFS
		loc	HFSM_FS_name	FSSS
		
		    
		foreach	var	in	PFS_FS_ppml_noCOLI	HFSM_FS	{
			    
			foreach	year	in	2001	2003	2017	2019	{
				    
				*	Joint
				tab		l2_`var'	`var'	[aw=wgt_long_ind]		if	year==`year', cell matcell(temp)
				scalar	samplesize	=	temp[1,1] + temp[1,2] + temp[2,1] +temp[2,2]	//	calculate sample size by adding up all
				mat trans_2by2_joint_``var'_name'_`year' = temp[1,1], temp[1,2], temp[2,1], temp[2,2]	//	Make it as a row matrix
				mat trans_2by2_joint_``var'_name'_`year' =  trans_2by2_joint_``var'_name'_`year'/samplesize	//	Divide it by sample size to compute relative frequency
				mat	list	trans_2by2_joint_``var'_name'_`year'
				
				scalar	FIFI_``var'_name'_`year'	=	trans_2by2_joint_``var'_name'_`year'[1,1]	//	FI, FI
				scalar	FIFS_``var'_name'_`year'	=	trans_2by2_joint_``var'_name'_`year'[1,2]	//	FI, FS
				scalar	FSFI_``var'_name'_`year'	=	trans_2by2_joint_``var'_name'_`year'[1,3]	//	FI, FS
				scalar	FSFS_``var'_name'_`year'	=	trans_2by2_joint_``var'_name'_`year'[1,4]	//	FS, FS
				
			}	//	year
			
			foreach	type	in	FIFI	FIFS	FSFI	FSFS	{
				
				mat	`type'_``var'_name'	=	`type'_``var'_name'_2001,	`type'_``var'_name'_2003,	`type'_``var'_name'_2017,	`type'_``var'_name'_2019
				mat	`type'_``var'_name'	=	`type'_``var'_name'_2001,	`type'_``var'_name'_2003,	`type'_``var'_name'_2017,	`type'_``var'_name'_2019
				
				mat	rownames	`type'_``var'_name'	=	"``var'_name'"
				
				mat	colnames	`type'_``var'_name'	=	"1999-2001"	"2001-2003"	"2015-2017"	"2017-2019"
			}
				
		}	//	var
			
		foreach	type	in	FIFI	FIFS	FSFI	FSFS	{
			
			mat	list	`type'_PFS
			mat	list	`type'_FSSS
			
			mat	`type'_PFS_FSSS	=	`type'_PFS	\	`type'_FSSS
		}

		
		putexcel	set "${SNAP_outRaw}/Trans_matrix_7919_ind", sheet(PFS_FSSS_dyn) modify
		putexcel	A4	=	"Food insecure in both rounds"
		putexcel	A5	=	matrix(FIFI_PFS_FSSS), names overwritefmt nformat(number_d2)	//	3a
		putexcel	A9	=	"Food secure in both rounds"
		putexcel	A10	=	matrix(FSFS_PFS_FSSS), names overwritefmt nformat(number_d2)	//	3a
		putexcel	A14	=	"Food insecure 1st round only"
		putexcel	A15	=	matrix(FIFS_PFS_FSSS), names overwritefmt nformat(number_d2)	//	3a
		putexcel	A19	=	"Food insecure 2nd round only"
		putexcel	A20	=	matrix(FSFI_PFS_FSSS), names overwritefmt nformat(number_d2)	//	3a
			
		
		
		*	(2023-12-27)	Spell length - PFS and FSSS
		*	Exports matrix to Excel file for figure 6.
		
			*	Spell length using FSSS
			sort	x11101ll	year
			
			*	Construct spell length using FSSS
			cap	drop	FSSS_FI_spell
			cap	drop	FSSS_FI_seq
			cap	drop	FSSS_FI_end
			
			tsspell, cond(FSSS_FI==1) spell(FSSS_FI_spell) seq(FSSS_FI_seq) end(FSSS_FI_end)

			
			*	Construct spell length using PFS - 1999-2003 and 2015-2019 only
				
				*	1999-2003
				cap	drop	PFS_FI_9903_spell
				cap	drop	PFS_FI_9903_seq
				cap	drop	PFS_FI_9903_end
				
				tsspell, cond(PFS_FI_ppml_noCOLI==1 & inlist(year,1999,2001,2003)) spell(PFS_FI_9903_spell) seq(PFS_FI_9903_seq) end(PFS_FI_9903_end)
				
				*	2015-2019
				cap	drop	PFS_FI_1519_spell
				cap	drop	PFS_FI_1519_seq
				cap	drop	PFS_FI_1519_end
				
				tsspell, cond(PFS_FI_ppml_noCOLI==1 & inlist(year,2015,2017,2019)) spell(PFS_FI_1519_spell) seq(PFS_FI_1519_seq) end(PFS_FI_1519_end)
				
				*	1999-2019 (combine the above two)
				
				foreach	var	in	spell	seq	end	{
					
					cap	drop	PFS_FI_9919_`var'
					gen			PFS_FI_9919_`var'=.
					replace		PFS_FI_9919_`var'=PFS_FI_9903_`var'	if	inlist(year,1999,2001,2003)
					replace		PFS_FI_9919_`var'=PFS_FI_1519_`var'	if	inlist(year,2015,2017,2019)
					
				}
				
				
				*	I do NOT use the code below, as it constructs consecutive spell b/w 1999-2003 and 2015-2019 if an individual is NOT observed b/w 2005 to 2013 (ex: x11101ll:6365049)
				*tsspell, cond(PFS_FI_ppml_noCOLI==1 & inlist(year,1999,2001,2003,2015,2017,2019)) spell(PFS_FI_9919_spell) seq(PFS_FI_9919_seq) end(PFS_FI_9919_end)
					
			
			*	Spell length distribution
			
			loc	period1	inlist(year,1999,2001,2003)
			loc	period2	inlist(year,2015,2017,2019)
			loc	period3	inlist(year,1999,2001,2003,2015,2017,2019)
			
				foreach	var	in	FSSS_FI	PFS_FI_9919	{
					
					forval	t=1/3	{
						tab	`var'_seq	[aw=wgt_long_ind]	if	`var'_end==1	&	`period`t'',	matcell(`var'_freq_`t')
						
						mat	list	`var'_freq_`t'
						local	N=r(N)
						mat	`var'_pct_`t'	=	`var'_freq_`t'	/	r(N)
						
						mat	rownames	`var'_pct_`t'	=	"1"	"2"	"3"				
						
					}
					
					mat	`var'_pct_tot	=	`var'_pct_3 \ `var'_pct_1	\	`var'_pct_2
					mat	list	`var'_pct_tot
					
				}
			
				
				mat	spell_9919_tot	=	FSSS_FI_pct_tot, PFS_FI_9919_pct_tot
				mat	colnames	spell_9919_tot	=	"FSSS"	 "PFS"
				mat	list	spell_9919_tot
				
				putexcel	set "${SNAP_outRaw}/Spell_9919_PFS_FSSS", sheet(PFS_FSSS_spell) modify
				putexcel	B3	=	"Spell length, 1999-2003 and 2015-2019"
				putexcel	B5	=	matrix(spell_9919_tot), names overwritefmt nformat(number_d2)	//	3a

		
		
		
		
	
	
	*	Change in food security status
		
		*use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		*keep	x11101ll	year	wgt_long_ind	sampstr sampcls year	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI
		*	2 X 2 (FS, FI)	-	FS status over two subsequent periods
		
		*svy:	tab	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI  if inrange(year,1981,2019), missing
		*tab year if mi(l2_PFS_FI_ppml_noCOLI) & inrange(year,1981,2019)
		*svy, subpop(if year==1983): tab 	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI, missing
		*tab	l2_PFS_FI_ppml PFS_FI_ppml [aw=wgt_long_ind] if year==1999	, missing // give the same ratio
		*local	sample_popsize_total=e(N_subpop)
		*mat	trans_change_1999 = e(b)[1,5], e(b)[1,2], e(b)[1,8]
		*mat list trans_change_1999
		**mat	list	e(b)
		cap	mat	drop	trans_years
		cap	mat	drop	trans_2by2_year
		cap	mat	drop	trans_change_year
		cap	mat	drop	FI_still_year_all
		cap	mat	drop	FI_newly_year_all
		cap	mat	drop	FI_persist_rate*
		cap	mat	drop	FI_entry_rate*
	
		*	Year
		global	transyear	1981 1982 1983 1984 1985 1986 1987 1994 1995 1996 1997 1999 2001 2003 2005 2007 2009 2011 2013 2015 2017 2019	//	Years I will use to generate figures
		*	Make a matrix of year matrix
		
		
		*	We test whether svy-structure adjusted (used in AJAE article) and non-svy-structure adjusted (where this paper is based upon) give the same results.
			*	NOT using svy-structure adjusted 
			tab	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI	if year==1997, missing matcell(temp_1997)
			
			tab	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI	[aw=wgt_long_ind] if year==1997, missing matcell(temp_1997)
			mat temp2_1997 = temp_1997 / r(N)
			
			mat list temp_1997
			mat list temp2_1997
			
			mat	trans_change_1997 = temp2_1997[2,2], temp2_1997[1,2], temp2_1997[3,2]
			mat list trans_change_1997
		
			*	Using svy-structure adjusted
			**	They give the same result!
			svy, subpop(if year==1997): tab 	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI, missing
			mat list e(b)
			mat	trans_change_1997 = e(b)[1,4], e(b)[1,2], e(b)[1,6]	//	Still FI, newly FI, previous status unknown.
			mat list trans_change_1997

		
		
		local	run_fig3=0	//	Estimates sub-group level persistence. Takes a long time to run. (2023-09-24) Conformality error happens. Need to figure out so turn it off until then.
		foreach	year of	global	transyear {			

			di	"year is `year'"
		
			*	Make a matrix of years
			mat	trans_years	=	nullmat(trans_years)	\	`year'
		
			*	Change in Status - entire population
			**	Note: here we do NOT limit our sample to non-missing values, as we need the ratio of those with missing values.
				
				*	We found that svy-adjusted and non-svy-adjusted give the same estimates, from the test above
				*	But we still need to run "svy, subpop" to get the # of subpopulation (cannot be generated under general "summarize" command)
				*	Thus, we use svy-adjusted way.
				svy, subpop(if year==`year'): tab 	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI, missing
				local	sample_popsize_total=e(N_subpop)
				mat	trans_change_`year' = e(b)[1,4], e(b)[1,2], e(b)[1,6]
				mat	trans_change_year	=	nullmat(trans_change_year)	\	trans_change_`year'
			
			
			*	Change in status - by group
			if	`run_fig3'==1	{	
			cap	mat	drop	Pop_ratio
			cap	mat	drop	FI_still_`year'	FI_newly_`year'	FI_unknown_`year'	FI_persist_rate_`year'	FI_entry_rate_`year'	FI_unknown_rate_`year'
				
				
				foreach	edu	in	0	 1 	{	//	College, no college
					foreach	race	in	0	 1 	{	//	People of colors, white
						foreach	gender	in	1	 0 	{	//	Female, male
							
							di	"rp_edu=`edu', rp_race=`race', rp_gender=`gender'"
							
							*	Svy-adjusted way
							svy, subpop(if	rp_female==`gender' & rp_White==`race' & rp_col==`edu'	&	year==`year'):	tab l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI, missing
												
							local	Pop_ratio	=	e(N_subpop)/`sample_popsize_total'
							local	FI_still_`year'		=	e(b)[1,4]*`Pop_ratio'	//	% of still FI HH in specific group x share of that population in total sample = fraction of HH in that group still FI in among total sample
							local	FI_newly_`year'		=	e(b)[1,2]*`Pop_ratio'	//	% of newly FI HH in specific group x share of that population in total sample = fraction of HH in that group newly FI in among total sample
							local	FI_unknown_`year'	=	e(b)[1,6]*`Pop_ratio'	//	% of previous status unknown 
							local	FI_persist_rate_`year'		=	e(b)[1,4]
							local	FI_entry_rate_`year'		=	e(b)[1,2]
							local	FI_unknown_rate_`year'		=	e(b)[1,6]
							
							*mat	Pop_ratio	=	nullmat(Pop_ratio)	\	`Pop_ratio'	//	(2023-07-21) Disable it, as we don't need to stack population ratio over years.
							mat	FI_still_`year'		=	nullmat(FI_still_`year')	\	`FI_still_`year''
							mat	FI_newly_`year'		=	nullmat(FI_newly_`year')	\	`FI_newly_`year''
							mat	FI_unknown_`year'	=	nullmat(FI_unknown_`year')	\	`FI_newly_`year''
							mat	FI_persist_rate_`year'	=	nullmat(FI_persist_rate_`year')	\	`FI_persist_rate_`year''
							mat	FI_entry_rate_`year'	=	nullmat(FI_entry_rate_`year')	\	`FI_entry_rate_`year''
							mat	FI_unknown_rate_`year'	=	nullmat(FI_unknown_rate_`year')	\	`FI_unknown_rate_`year''
							
						}	//	gender
					}	//	race
				}	//	education
				
				mat	FI_still_year_all			=	nullmat(FI_still_year_all),	FI_still_`year'
				mat	FI_newly_year_all			=	nullmat(FI_newly_year_all),	FI_newly_`year'
				mat	FI_unknown_year_all			=	nullmat(FI_unknown_year_all),	FI_newly_`year'
				mat	FI_persist_rate_year_all	=	nullmat(FI_persist_rate_year_all),	FI_persist_rate_`year'
				mat	FI_entry_rate_year_all		=	nullmat(FI_entry_rate_year_all),	FI_entry_rate_`year'
				mat	FI_unknown_rate_year_all	=	nullmat(FI_unknown_rate_year_all),	FI_unknown_rate_`year'
			
			}	//	run_fig3
		
		}	//	year
			
			
			
			*	Figure 7
			*	Need to plot from matrix, thus create a temporary dataset to do this
			preserve
			
				clear
				
				set	obs	22
				
				*	Matrix for Figure 2
				svmat	trans_years
				svmat	trans_change_year
				rename	(trans_years1 trans_change_year1 trans_change_year2 trans_change_year3)	(year	still_FI	newly_FI	status_unknown)
				*drop	status_unknown
				label var	still_FI		"Still food insecure"
				label var	newly_FI		"Newly food insecure"
				label var	status_unknown	"Previous status unknown"
				
				egen	FI_prevalence	=	rowtotal(still_FI	newly_FI	status_unknown)
				label	var	FI_prevalence	"Annual FI prevalence (<0.5)"
				
				*	Matrix for Figure 3
				**	(FI_still_year_all, FI_newly_year_all) have years in column and category as row, so they need to be transposed)
				*	Disable for now, as we don't do sub-group analyses for now
				/*
				foreach	fs_category	in	FI_still_year_all	FI_newly_year_all	{
					
					mat		`fs_category'_tr=`fs_category''
					svmat 	`fs_category'_tr
				}
				*/
				
				*	Figure 7	(Change in food security status by year)
					
					*	B&W 
					graph bar still_FI newly_FI	status_unknown, over(year, label(angle(vertical))) stack  legend(pos(6) lab (1 "Still FI") 	lab(2 "Newly FI")	lab(3 "Previously unknown")rows(1))	///
					graphregion(color(white)) bgcolor(white)  bar(1, fcolor(gs11)) bar(2, fcolor(gs6)) bar(3, fcolor(gs1))	///
					ytitle(Fraction of Population) title(Change in Food Security Status)	ylabel(0(.025)0.15) 	name(change_status_byyear, replace)
					
					graph display change_status_byyear, ysize(8) xsize(12.0)
					graph	export	"${SNAP_outRaw}/change_in_status_7919.png", replace
					graph	close
					
					/*
					*	Color
					graph bar still_FI newly_FI	status_unknown, over(year) stack legend(lab (1 "Still FI") lab(2 "Newly FI") lab(3 "Previous status unknown") rows(1))	///
								graphregion(color(white)) bgcolor(white) asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(orange)) bar(3, fcolor(gs12))	///
								ytitle(Fraction of Population)	ylabel(0(.025)0.153)
					graph	export	"${PSID_outRaw}/Fig_3_FI_change_status_byyear.png", replace
					graph	close
					*/
				
				*	Figure 3
				*	Figure 3a
				/*
				graph bar FI_newly_year_all_tr?, over(year, label(labsize(small))) stack	graphregion(color(white)) bgcolor(white)	ytitle(Fraction of Population)	ylabel(0(.025)0.05)	///
							legend(lab (1 "Col/Non-White/Female ") lab(2 "Col/Non-White/Male") lab(3 "Col/White/Female")	lab(4 "Col/White/Male") 	///
							lab (5 "HS/Non-White/Female") lab(6 "HS/Non-White/Male") lab(7 "HS/White/Female")	lab(8 "HS/White/Male") size(vsmall) rows(3))	///
							bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((a) Newly Food Insecure)	name(Newly_FI, replace) scale(0.8)     
				
				
				*	Figure 3b
				graph bar FI_still_year_all_tr?, over(year, label(labsize(small))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))*/	ylabel(0(.025)0.1)	///
							legend(lab (1 "Col/Non-White/Female ") lab(2 "Col/Non-White/Male") lab(3 "Col/White/Female")	lab(4 "Col/White/Male") 	///
							lab (5 "HS/Non-White/Female") lab(6 "HS/Non-White/Male") lab(7 "HS/White/Female")	lab(8 "HS/White/Male") size(vsmall) rows(3))	///
							bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((b) Still Food Insecure)	name(Still_FI, replace)	scale(0.8)  
							
							
				grc1leg Newly_FI Still_FI, rows(2) legendfrom(Newly_FI)	graphregion(color(white)) /*(white)*/
				graph	export	"${SNAP_outRaw}/change_in_status_by_group.png", replace
				graph	close
				*/
			
			restore
			

			
