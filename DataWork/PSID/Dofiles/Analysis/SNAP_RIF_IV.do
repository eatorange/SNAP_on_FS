summ PFS_FS_ppml [aw=wgt_long_ind] if reg_sample==1


forval	i=10(10)90	{
	cap	drop	PFS_rif_`i'
	egen PFS_rif_`i'=rifvar(PFS_ppml) if reg_sample==1, q(`i') weight(wgt_long_ind)
}

* Run IV-FE with Weights on the 10th Percentile RIF
forval	q=10(10)90	{
	xtivreg2 PFS_rif_`q' ${RHS}		 (${endovar} = ${IV}) [pw=wgt_long_ind]  if reg_sample==1, fe cluster(x11101ll)
	est	store	PFS_rif_`q'
}

coefplot	PFS_rif_10 PFS_rif_20 PFS_rif_30 PFS_rif_40 PFS_rif_50 PFS_rif_60 PFS_rif_70 PFS_rif_80 PFS_rif_90, keep(${endovar})	///
			xline(0)	graphregion(color(white)) bgcolor(white)	///
				legend(lab (2 "10th") lab(4 "20th") lab(6 "30th") lab(8 "40th")	lab(10 "50th")	lab(12 "60th")	///
				lab(14 "70th") lab(16 "80th") 	lab(18 "90th") pos(6)	rows(1))	///
				ylabel(1 "SNAP",	labsize(small)) 	name(PFS_on_SNAP_RIF_IV, replace)	title(Distributional Effects of SNAP over PFS Percentile)
graph display PFS_on_SNAP_RIF_IV, ysize(4) xsize(9.0)
				graph	export	"${SNAP_outRaw}/PFS_on_SNAP_RIF_IV.png", as(png) replace
				
*	Average of 50th and 60th quantile
cap	drop	PFS_qtile
cap	drop	PFS_qtile_q*
xtile	PFS_qtile=PFS_ppml	[aw=wgt_long_ind] if reg_sample==1, nq(10)



summ	PFS_ppml	[aw=wgt_long_ind]	 if reg_sample==1	&	PFS_qtile==5
summ	PFS_ppml	[aw=wgt_long_ind]	 if reg_sample==1	&	PFS_qtile==6