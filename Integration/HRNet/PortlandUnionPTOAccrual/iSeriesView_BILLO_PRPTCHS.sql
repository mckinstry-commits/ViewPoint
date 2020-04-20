/*
iSeries View
	create view  BILLO.PRPTCHS
	as
	SELECT 
		tch.CHCONO, tch.CHDVNO, tch.CHEENO, mst.MNM25, mst.MDTHR, mst.MDTBG, mst.MDTTE, mst.MDTWK, mst.MSTAT,tch.CHRGHR,tch.CHOVHR,tch.CHOTHR,tch.CHOTTY,(tch.CHRGHR + tch.CHOVHR + tch.CHOTHR) AS CHTLHR, tch.CHDTWE, tch.CHUNNO , tch.CHCRNO
	FROM 
		CMSFIL.PRPTCH tch JOIN
		CMSFIL.PRPMST mst ON
			tch.CHCONO=mst.MCONO
		AND tch.CHDVNO=mst.MDVNO
		AND tch.CHEENO=mst.MEENO
		AND tch.CHDTWE >= 20140101
	WHERE
		tch.CHCONO in (1,20,60) 
	AND tch.CHDVNO=0 
	AND (tch.CHCRNO <> 0 OR tch.CHOTTY <> '')
*/