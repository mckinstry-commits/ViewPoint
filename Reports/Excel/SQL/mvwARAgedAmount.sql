IF OBJECT_ID ('dbo.mvwARAgedAmount', 'view') IS NOT NULL
DROP VIEW dbo.mvwARAgedAmount;
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 11/18/2014 Amit Mody			Authored
** 
******************************************************************************/

CREATE VIEW dbo.mvwARAgedAmount
--WITH SCHEMABINDING --For indexed views
AS
	SELECT * FROM
	(SELECT	ARCo
	,		ltrim(rtrim(InvoiceContract)) AS [Contract]
	,		DaysBracket
	--,		SUM(Amount) AS Amount
	--,		SUM(Retainage) AS Retainage 
	,		COALESCE(SUM(AgeAmount), 0.0) as AgeAmount
	FROM (
			SELECT		
				ARTH.ARCo, 
				InvoiceContract=ISNULL(ARTH.Contract,ARTL.Contract),
				AgeDate=ARTH.TransDate,
				DaysFromAge=DATEDIFF(day, ARTH.TransDate, GETDATE()),
				DaysBracket=CASE WHEN (DATEDIFF(day, ARTH.TransDate, GETDATE()) <= 30) THEN 'Current'
									WHEN (DATEDIFF(day, ARTH.TransDate, GETDATE()) > 30 AND DATEDIFF(day, ARTH.TransDate, GETDATE()) <= 60) THEN '31-60 Days'
									WHEN (DATEDIFF(day, ARTH.TransDate, GETDATE()) > 60 AND DATEDIFF(day, ARTH.TransDate, GETDATE()) <= 90) THEN '61-90 Days'
									ELSE '>91 Days' END,
				Amount=isnull(ARTL.Amount,0)-0, 
				Retainage=isnull(ARTL.Retainage,0)-0,
				AgeAmount=isnull(ARTL.Amount,0)-isnull(ARTL.Retainage,0)-0
			FROM    
				ARTL ARTL with (NOLOCK) 
				JOIN ARTH ARTH with (NOLOCK) 
					ON	ARTL.ARCo = ARTH.ARCo 
					AND ARTL.ApplyMth = ARTH.Mth 
					AND ARTL.ApplyTrans = ARTH.ARTrans    
			WHERE
				--(@company IS NULL OR ARTL.ARCo=@company) AND
				--ARTL.Mth <= @thisMonth AND
				ARTH.TransDate <= GETDATE() AND
				ARTL.RecType = 1
			--ORDER BY    
			--    ARTH.ARCo ASC, 
			--	isnull(ARTH.Contract,ARTL.Contract)
			) Data
	GROUP BY
		ARCo, 
		InvoiceContract, 
		DaysBracket
	HAVING
		COALESCE(SUM(AgeAmount), 0.0) <> 0
	) Aggr
	PIVOT
	(
		SUM(AgeAmount)
		FOR DaysBracket IN ([Current], [31-60 Days], [61-90 Days], [>91 Days])
	) Piv
	--ORDER BY 
	--	ARCo
	--,	InvoiceContract
GO

GRANT SELECT ON dbo.mvwARAgedAmount TO [public]
GO

-- Test Script
SELECT * FROM dbo.mvwARAgedAmount
WHERE ARCo=1
order by Contract