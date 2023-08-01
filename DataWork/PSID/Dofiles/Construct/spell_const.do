*	Constructing spell length 

use	"${SNAP_dtInt}/SNAP_long_PFS", clear

*	Keep only non-missing PFS observation
keep	if	!mi(PFS_glm)

*	Generate spell-related variables
**	IMPORANT NOTE: Since the PFS data has (1) gap period b/w 1988-1991 and (2) changed frequency since 1997, it is not clear how to define "spell"
**	Based on 2023-7-25 discussion, we decide to define spell as "the number of consecutive 'OBSERVATIONS' experiencing food insecurity", regardless of gap period and updated frequency
	**	We can do robustness check with the updated spell (i) splitting pre-gap period and post-gap period, and (ii) Multiplying spell by 2 for post-1997
	
cap drop	_seq	_spell	_end
tsspell, cond(year>=1979 & PFS_FI_glm==1)

br	x11101ll	year	PFS_glm	PFS_FI_glm	_seq	_spell	_end

tempfile	temp
save	`temp', replace

	
*	Descriptive stats for spell length

	*	# of su
	
	*	Summary stats (N, mean and SD)
	*	Note: "end==1" restricts only the observations when the spell ends (so only considers the final spell length)
	
	cap	mat	drop	summstat_spell_length
	summ	_seq	[aw=wgt_long_fam_adj]	if	_end==1	//	Total
	
	mat	summstat_spell_length	=	(r(N), r(mean), r(sd))
	mat	list	summstat_spell_length
	
	*	By category
	foreach	catvar	in	rp_female rp_White rp_col	{
			
		foreach	val	in	0 1	{
			
			summ	_seq	[aw=wgt_long_fam_adj]	if	_end==1	&	`catvar'==`val'
			mat	summstat_spell_length	=	summstat_spell_length	\		(r(N), r(mean), r(sd))
			
		}
		
	}
	
	mat	colnames	summstat_spell_length	=	"N"	"Mean"	"SD"
	mat	rownames	summstat_spell_length	=	"All"	"Male"	"Female"	"NonWhite"	"White"	"No-col-degree"	"Col-degree"
		
	mat	list	summstat_spell_length
	
	
	
	
	
	
	*graph	twoway	(kdensity	PFS_glm	[aw=wgt_long_fam_adj]	if	rp_col==0)	(kdensity	PFS_glm	[aw=wgt_long_fam_adj]	if	rp_col==1)
		
	*	Distribution of spell length	
	*	Since "hist" does not accept aweight, we use the percentage in frequency table
		
		cap	mat	drop	spell_pct_all
	
		*	All sample
		tab	_seq	[aw=wgt_long_fam_adj]	if	_end==1,	matcell(spell_freq_w)
		mat	list	spell_freq_w
		local	N=r(N)
		mat	spell_pct_tot	=	spell_freq_w	/	r(N)
		
		mat	spell_pct_all		=	nullmat(spell_pct_all),	spell_pct_tot
		
		*	By category
		*	We use categories by - gender, race and college degree (dummy for each category)
		*	I do NOT use individual-information for two reasons; (i) individual-level race not available. (ii) individual-education not available for indivdiual 16-years or less
		
		foreach	catvar	in	rp_female rp_White rp_col	{
			
			foreach	val	in	0 1	{
				
				tab	_seq	[aw=wgt_long_fam_adj]	if	_end==1	&	`catvar'==`val',	matcell(spell_freq_`catvar'_`val')
				mat	list	spell_freq_`catvar'_`val'
				local	N=r(N)
				mat	spell_pct_`catvar'_`val'	=	spell_freq_`catvar'_`val'	/	r(N)	
				mat	list	spell_pct_`catvar'_`val'
				
				mat	spell_pct_all		=	nullmat(spell_pct_all),	spell_pct_`catvar'_`val'
			}
			
		}
		
	
		
	*preserve
	
	*	Summary table
	
	
	*	Figures
	
	preserve
	
		clear
		set	obs	26
		gen	spell_length	=	_n
		
		svmat	spell_pct_all
		
		rename	spell_pct_all?	(spell_pct_all	spell_pct_male	spell_pct_female	spell_pct_nonWhite	spell_pct_White	spell_pct_nocol	spell_pct_col)
		
		
		*	Figures
			
			*	All population
			graph hbar spell_pct_all, over(spell_length, sort(spell_percent_w) /*descending*/	label(labsize(vsmall)))	legend(lab (1 "Fraction") size(small) rows(1))	///
				bar(1, fcolor(gs03*0.5)) /*bar(2, fcolor(gs10*0.6))*/	graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length) ytitle(Fraction)
		
			graph	export	"${SNAP_outRaw}/Spell_length_dist.png", replace
			graph	close
			
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
			
			*	By education (college degree)
			graph hbar spell_pct_col	spell_pct_nocol, over(spell_length, /*descending*/	label(labsize(vsmall)))	legend(lab (1 "College degree") lab(2 "No college degree") size(small) rows(1))	///
				bar(1, fcolor(gs03*0.5)) bar(2, fcolor(gs10*0.6))	graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length - By College) ytitle(Fraction)
		
			graph	export	"${SNAP_outRaw}/Spell_length_dist_college.png", replace
			graph	close
					
	restore
	
	
	
	tab	_seq	[fw=wgt_long_fam_adj]	if	_end==1
	tab	_seq	[aw=wgt_long_fam_adj]	if	_end==1
	hist	_seq	[fw=wgt_long_fam_adj]	if	_end==1
	
	
	tab	_seq	[aw=wgt_long_fam_adj]	if	_end==1,	matcell(dist_freq)
	
	tabstat	_seq	[aw=wgt_long_fam_adj]	if	_end==1,	stats(mean)


*	SNAP redemption pattern from 1979-1987
*	To see if HH use SNAP continuously or often -in and -out
	
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
	
	*	Ever-used FS over stuy period  (1979-1987)
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
	
	*	# of waves FS redeemed	(if ever used) (1979-1987)
	loc	var	total_FS_used
	cap	drop	`var'
	cap	drop	`var'_temp
	cap	drop	`var'_uniq
	bys	x11101ll:	egen	`var'=	total(FS_rec_wth)	if	live_in_FU==1  // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
	bys x11101ll:	egen	`var'_temp	=	max(`var')
	bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
	summ	`var'_uniq if `var'_uniq>=1,d
	label var	`var'		"Total FS used throughouth the period"
	label var	`var'_uniq	"Total FS used throughouth the period"
	
	hist total_FS_used_uniq	if FS_ever_used_uniq==1, width(0.5)	//	histogram (among those who ever redeemed FS)
	tab	total_FS_used_uniq	if FS_ever_used_uniq==1	
	
	*	% of FS redeemed (# FS redeemed/# surveyed)		(1979-1987)
	loc	var	share_FS_used
	cap	drop	`var'
	cap	drop	`var'_uniq
	gen	`var'	=	total_FS_used_uniq	/	num_waves_in_FU_uniq 
	bys x11101ll:	gen 	`var'_uniq	=	`var' if _n==1
	label var	`var'		"\% of FS used throughouth the period"
	label var	`var'_uniq	"\% of FS used throughouth the period"
	
	hist share_FS_used_uniq if FS_ever_used_uniq==1, width(0.03)	//	histogram (among those who ever redeemed FS)
	
	*	Spell of FS redemption
	cap drop	FS_spell	FS_seq	FS_end
	tsspell, cond(year>=1979 & FS_rec_wth==1) spell(FS_spell) seq(FS_seq) end(FS_end)  
	
	*	Max spell of FS redemption
	loc	var	max_FS_spell
	cap	drop	`var'
	cap	drop	`var'_uniq
	cap	drop	`var'_temp
	bys	x11101ll:	egen	`var'=	max(FS_spell)	 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
	bys x11101ll:	gen 	`var'_uniq	=	`var' if _n==1
	summ	`var'_uniq ,d
	label var	`var'		"max FS spell"
	label var	`var'_uniq	"max FS spell"

	
	*	FI in two consecutive periods (persistent rate)
	loc	var	PFS_FI_FI
	cap	drop	`var'
	gen	`var'=.
	replace	`var'=0	if	(inrange(year,1980,1987)	| inrange(year,1993,1997))	&	!(l.PFS_FI_glm==1	&	PFS_FI_glm==1)
	replace	`var'=1	if	(inrange(year,1980,1987)	| inrange(year,1993,1997))	&	l.PFS_FI_glm==1	&	PFS_FI_glm==1
	
	replace	`var'=0	if	inrange(year,1999,2019)	&	!(l2.PFS_FI_glm==1	&	PFS_FI_glm==1)
	replace	`var'=1	if	inrange(year,1999,2019)	&	l2.PFS_FI_glm==1	&	PFS_FI_glm==1
	
	*	(FS,FI) in two consecutive periods (entry)
	loc	var	PFS_FS_FI
	cap	drop	`var'
	gen	`var'=.
	replace	`var'=0	if	(inrange(year,1980,1987)	| inrange(year,1993,1997))	&	!(l.PFS_FI_glm==0	&	PFS_FI_glm==1)
	replace	`var'=1	if	(inrange(year,1980,1987)	| inrange(year,1993,1997))	&	l.PFS_FI_glm==0	&	PFS_FI_glm==1
	
	replace	`var'=0	if	inrange(year,1999,2019)	&	!(l2.PFS_FI_glm==0	&	PFS_FI_glm==1)
	replace	`var'=1	if	inrange(year,1999,2019)	&	l2.PFS_FI_glm==0	&	PFS_FI_glm==1

	
	collapse (mean) PFS_FI_FI	PFS_FS_FI [aw=wgt_long_fam_adj], by(year)
	
	graph	twoway	(line PFS_FI_FI 	year, lpattern(dash) xaxis(1) yaxis(1) legend(label(1 "Persistence Rate")))	///
					(line PFS_FS_FI	year, lpattern(dash_dot) xaxis(1) yaxis(1) legend(label(2 "Entry Rate"))),	///
					/*(line rp_disabled	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Disabled"))), */ ///
					xline(1987 1992 1999, axis(1) lcolor(black) lpattern(dash))	///
					xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
					xtitle(Year)	/*xtitle("", axis(1))*/	ytitle("Percent", axis(1)) ///
					ytitle("Percentage", axis(1)) title(Persistent and Entry Rate)	bgcolor(white)	graphregion(color(white)) 	name(race_annual, replace)	///
					note()
	
	
	*	Stats (unweighted) (1979-1987)
	tab	share_FS_used_uniq	if	FS_ever_used_uniq==1	//	share of FS redeemd, if ever redeemed (1979-1987)
	tab	total_FS_used_uniq	if	FS_ever_used_uniq==1	//	# of FS used, if ever used
	tab	total_FS_used_uniq	if	FS_ever_used_uniq==1 & num_waves_in_FU==4	//	# of FS used, if ever used and surveyd 4 times
		*	30% used once
		*	21% used twice
		*	27% used three times
		*	22% used 4 times
	
	*	Redemption pattern of individualls fully surveyed 1979-1987 (9 waves)
	tab	total_FS_used_uniq	if	FS_ever_used_uniq==1 & num_waves_in_FU==9
		*	23% redeemed only once
		*	12% redeemd full period
	tab	total_FS_used_uniq	if	FS_ever_used_uniq==1 & num_waves_in_FU==4	//	those who surveyed 4 times
	
	tab	_spell	if	FS_ever_used==1	&	inrange(year,1979,1987)
	
	*	Maximum spell of FS redemption of fully surveyed HH
	tab max_FS_spell_uniq if inrange(year,1979,1987) & FS_ever_used_uniq==1 & num_waves_in_FU==9
	tab max_FS_spell_uniq if inrange(year,1979,1987) & FS_ever_used_uniq==1 & num_waves_in_FU==9 & total_FS_used>=2 // among those used at least twice
	
	tab max_FS_spell_uniq if inrange(year,1979,1987) & FS_ever_used_uniq==1 & num_waves_in_FU==9 & total_FS_used==2 // among those used twice
		*	63% used continuously (two consecutive periods)
		*	37% used in separately (two different periods)
	tab max_FS_spell_uniq if inrange(year,1979,1987) & FS_ever_used_uniq==1 & num_waves_in_FU==9 & total_FS_used==3 // among those used thrice
		*	56% used continuously 
		*	34% used in two consecutive and one separate
		*	10% used in three different periods
	tab max_FS_spell_uniq if inrange(year,1979,1987) & FS_ever_used_uniq==1 & num_waves_in_FU==9 & total_FS_used==4 // among those used four times
		*	41% used continuously
		*	43% used in two different periods
		*	15% used in three different periods
		*	<1% used in four different periods
	
	*	Length of spell
	tab	FS_seq if inrange(year,1979,1987) & FS_rec_wth==1 
	tab	FS_seq if inrange(year,1979,1987) & FS_rec_wth==1 & total_FS_used==2 // among used FS twice
		*	66% of them were 1st sequence
		*	34% of them were 2nd sequence (meaning that 2 consecutive years)
		
		
	*	Transition in FS status, comparing 96-97 (1-year period) and 97-99 (2-year period)
		*	Previously FI
		tab	PFS_FI_glm if year==1995	&	l.PFS_FI_glm==1
		tab	PFS_FI_glm if year==1996	&	l.PFS_FI_glm==1
		tab	PFS_FI_glm if year==1997	&	l.PFS_FI_glm==1
		tab	PFS_FI_glm if year==1999	&	l2.PFS_FI_glm==1
		tab	PFS_FI_glm if year==2001	&	l2.PFS_FI_glm==1
		
		*	Previously FS
		tab	PFS_FI_glm if year==1995	&	l.PFS_FI_glm==0
		tab	PFS_FI_glm if year==1996	&	l.PFS_FI_glm==0
		tab	PFS_FI_glm if year==1997	&	l.PFS_FI_glm==0
		tab	PFS_FI_glm if year==1999	&	l2.PFS_FI_glm==0
		tab	PFS_FI_glm if year==2001	&	l2.PFS_FI_glm==0
		
	
		
		
	*	1992-1997
		
	*	Number of waves living in FU (1992-1997)
	global	startyear	1992
	global	endyear		1997
	loc	var	num_waves_in_FU_${startyear}_${endyear}
	cap	drop	`var'
	cap	drop	`var'_temp
	cap	drop	`var'_uniq
	bys	x11101ll:	egen	`var'=total(live_in_FU)	if	live_in_FU==1 & inrange(year,${startyear},${endyear}) // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
	bys x11101ll:	egen	`var'_temp	=	max(`var')
	bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
	drop	`var'
	rename	`var'_temp	`var'
	summ	`var'_uniq,d
	label	var	`var'_uniq "\# of waves surveyed (${startyear}-${endyear})"
	
	
	*	Ever-used FS over stuy period  (1992-1997)
	loc	var	FS_ever_used_${startyear}_${endyear}
	cap	drop	`var'
	cap	drop	`var'_uniq
	cap	drop	`var'_temp
	bys	x11101ll:	egen	`var'=	max(FS_rec_wth)	if live_in_FU==1 & inrange(year,${startyear},${endyear})  // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
	bys x11101ll:	egen	`var'_temp	=	max(`var')
	bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
	drop	`var'
	rename	`var'_temp	`var'
	summ	`var'_uniq ,d
	label var	`var'		"FS ever used throughouth (${startyear}-${endyear})"
	label var	`var'_uniq	"FS ever used throughouth (${startyear}-${endyear})"
	
	*	# of waves FS redeemed	(if ever used) (1992-1997)
	loc	var	total_FS_used_${startyear}_${endyear}
	cap	drop	`var'
	cap	drop	`var'_temp
	cap	drop	`var'_uniq
	bys	x11101ll:	egen	`var'=	total(FS_rec_wth)	if	live_in_FU==1 & inrange(year,${startyear},${endyear}) // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
	bys x11101ll:	egen	`var'_temp	=	max(`var')
	bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
	summ	`var'_uniq if `var'_uniq>=1,d
	label var	`var'		"Total FS used throughout  (${startyear}-${endyear})"
	label var	`var'_uniq	"Total FS used throughout  (${startyear}-${endyear})"
	
	*	% of FS redeemed (# FS redeemed/# surveyed)		(1979-1987)
	loc	var	share_FS_used_${startyear}_${endyear}
	cap	drop	`var'
	cap	drop	`var'_uniq
	gen	`var'	=	total_FS_used_${startyear}_${endyear}_uniq	/	num_waves_in_FU_${startyear}_${endyear}_uniq if inrange(year,${startyear},${endyear})
	bys x11101ll:	gen 	`var'_uniq	=	`var' if _n==1
	label var	`var'		"\% of FS used throughout  (${startyear}-${endyear})"
	label var	`var'_uniq	"\% of FS used throughout  (${startyear}-${endyear})"
	
		
	
	*	Spell of FS redemption
	cap drop	FS_spell_${startyear}_${endyear}	FS_seq_${startyear}_${endyear}	FS_end_${startyear}_${endyear}
	tsspell, cond(year>=1979 & FS_rec_wth==1 & inrange(year,${startyear},${endyear})) spell(FS_spell_${startyear}_${endyear}) seq(FS_seq_${startyear}_${endyear}) end(FS_end_${startyear}_${endyear})  
	
	