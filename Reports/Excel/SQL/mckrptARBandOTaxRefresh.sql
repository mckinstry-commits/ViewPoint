IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptARBandOTaxRefresh]'))
	DROP PROCEDURE [dbo].[mckrptARBandOTaxRefresh]
GO

-- =================================================================================================================================
-- Author:		Amit Mody
-- Create date: 3/24/2015
-- Description:	Data refresh procedure for AR B and O Tax Report.  
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 
-- ==================================================================================================================================

CREATE PROCEDURE [dbo].[mckrptARBandOTaxRefresh]
AS
BEGIN
	IF OBJECT_ID('tempdb..#Multilevel') IS NOT NULL
		DROP TABLE #Multilevel

	CREATE TABLE #Multilevel     
	(
		Name	varchar (60)		NULL,
		ARCo	tinyint	NULL,
		ARTrans	int	NULL,
		Mth	smalldatetime	NULL,
		BaseTaxCode	varchar	(10) NULL,
		LocalTaxCode varchar (10) NULL,
		TaxBaseAmountTotal decimal(12,2) NULL,
		TaxBaseBasisTotal decimal (12,2) NULL,
		TaxBaseDiscOffTotal decimal (12,2) NULL,
		TaxBaseTaxDiscTotal decimal (12,2) NULL,
		TotalAmount decimal (12,2) NULL,
		Contract varchar(15) null,
		TaxGroup tinyint null,
		Item varchar(16) null,
		ReportingCode varchar (10) NULL,
		CityId varchar(6) NULL,
		City varchar(50) NULL,
		State varchar(2) NULL
	)

	INSERT INTO #Multilevel (ARCo, Name, BaseTaxCode, ARTrans, Mth, TaxBaseBasisTotal, TaxBaseAmountTotal, TaxBaseDiscOffTotal, TaxBaseTaxDiscTotal, TotalAmount, Contract, TaxGroup, Item)
      	  SELECT ARTL.ARCo, HQCO.Name, TaxCode, ARTL.ARTrans, ARTL.Mth, sum(TaxBasis), sum(TaxAmount), sum(DiscOffered), sum(TaxDisc), sum(Amount), ARTL.Contract, ARTL.TaxGroup, ARTL.Item
      		FROM ARTL  WITH (NOLOCK) 
      		JOIN ARTH  WITH (NOLOCK) on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans
      		JOIN bHQCO HQCO WITH (NOLOCK) on HQCO.HQCo=ARTL.ARCo
      	  WHERE ARTL.ARCo <= 100
			and ARTL.Mth between '1950-01-01 00:00:00' and '2050-12-01 12:00:00'
   			and ARTH.ARTransType IN ('A','C','I','M','W')
      	  GROUP BY ARTL.ARCo, Name, TaxCode, ARTL.ARTrans, ARTL.Mth, ARTL.Contract, ARTL.TaxGroup, ARTL.Item

	UPDATE b
	SET	b.ReportingCode=t.udReportingCode,
		b.CityId=t.udCityId
	FROM #Multilevel b JOIN HQTX t with (nolock) on b.TaxGroup = t.TaxGroup and b.BaseTaxCode = t.TaxCode	

	UPDATE b
	SET	b.ReportingCode=x.udReportingCode
	FROM #Multilevel b
	JOIN HQTL a with (nolock) on a.TaxGroup=b.TaxGroup and a.TaxCode=b.BaseTaxCode
	JOIN HQTX x with (nolock) on x.TaxGroup=a.TaxGroup and x.TaxCode=a.TaxLink
	WHERE x.Description like '% County%'

	UPDATE b
	SET	b.ReportingCode=x.udReportingCode
	FROM #Multilevel b
	JOIN HQTL a with (nolock) on a.TaxGroup=b.TaxGroup and a.TaxCode=b.BaseTaxCode
	JOIN HQTX x with (nolock) on x.TaxGroup=a.TaxGroup and x.TaxCode=a.TaxLink
	WHERE x.TaxCode like '%[_]C%'

	UPDATE b
	SET	b.ReportingCode=x.udReportingCode
	FROM #Multilevel b
	JOIN HQTL a with (nolock) on a.TaxGroup=b.TaxGroup and a.TaxCode=b.BaseTaxCode
	JOIN HQTX x with (nolock) on x.TaxGroup=a.TaxGroup and x.TaxCode=a.TaxLink
	WHERE x.TaxCode like '%[_]P%'

	UPDATE b
	SET	b.State=g.State,
		b.City=g.City
	FROM #Multilevel b JOIN dbo.udGeographicLookup g ON b.CityId=g.McKCityId 

	TRUNCATE TABLE dbo.mckARBOTax
	INSERT INTO dbo.mckARBOTax
	SELECT
			  l.Mth
		,	  l.ARCo
		,     l.Contract
		,     l.ARTrans
		,     d.Instance as GLDept
		,     d.Description AS GLDeptName
		,     ISNULL(d.OperatingUnit, '') AS OperatingUnit
		,	  l.TaxCode
		,	  l.ReportingCode
		,     l.City
		,	  l.State
		,	  CASE WHEN c.Description IS NOT NULL THEN c.Description 
				   ELSE 
						CASE WHEN l.TaxCode like '%X' THEN 'Unidentified Wholesale'
							 WHEN l.TaxCode not like '%X' THEN 'Unidentified Retail'
							 ELSE null
						END
			  END AS BOClass
		,	  l.InvoiceAmount
		,	  l.TaxBasis
		,	  l.TaxAmount
		,	  GETDATE() AS [Processed On]
	FROM (SELECT Mth, ARCo, Contract, Item, ARTrans, TaxGroup, BaseTaxCode AS TaxCode, ReportingCode, City, State,
				 sum(ISNULL(TotalAmount, 0))-sum(ISNULL(TaxBaseAmountTotal, 0)) AS InvoiceAmount,
				 sum(ISNULL(TaxBaseBasisTotal, 0)) as TaxBasis,
				 sum(ISNULL(TaxBaseAmountTotal, 0)) as TaxAmount
		  FROM #Multilevel
		  GROUP BY Mth, ARCo, Contract, Item, ARTrans, TaxGroup, BaseTaxCode, ReportingCode, City, State) l
		 LEFT JOIN (SELECT cm.JCCo, cm.Contract, bo.Description 
					FROM dbo.JCCM cm LEFT JOIN
						 dbo.udBandOClass bo ON 
						 cm.udBOClass = bo.BOClassCode) c
			ON c.JCCo = l.ARCo AND c.Contract = l.Contract
		 LEFT JOIN (SELECT jcci.JCCo, jcci.Contract, jcci.Item, glpi.Instance, glpi.Description, udgldept.OperatingUnit
					FROM dbo.JCCI jcci 
					JOIN dbo.JCDM jcdm ON jcci.JCCo=jcdm.JCCo AND jcci.Department=jcdm.Department 
					JOIN dbo.GLPI glpi ON jcdm.JCCo=glpi.GLCo AND glpi.PartNo=3 AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4) 
					LEFT JOIN dbo.udGLDept udgldept ON glpi.GLCo=udgldept.Co AND glpi.Instance=udgldept.GLDept) d
			ON l.ARCo=d.JCCo AND l.Contract=d.Contract AND l.Item=d.Item
		
	DROP TABLE #Multilevel
END
GO

--Test Script
--EXEC mckrptARBandOTaxRefresh
--SELECT * FROM mckARBOTax where TaxCode = 'WA0091' and ARTrans=75