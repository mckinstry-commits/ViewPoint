USE Viewpoint
go

/****** Object:  Table [dbo].[mckARBOTax]    Script Date: 4/30/2015 2:40:40 PM ******/
DROP TABLE [dbo].[mckARBOTax]
GO

CREATE TABLE [dbo].[mckARBOTax](
	[Mth] [smalldatetime] NULL,
	[ARCo] [tinyint] NULL,
	[Contract] [varchar](15) NULL,
	[ARTrans] [int] NULL,
	[GLDept] [varchar](4) NULL,
	[GLDeptName] [varchar](60) NULL,
	[OperatingUnit] [varchar](10) NULL,
	[TaxCode] [varchar](10) NULL,
	[ReportingCode] [varchar](10) NULL,
	[City] [varchar](50) NULL,
	[State] [varchar](2) NULL,
	[BOClass] [varchar](60) NULL,
	[InvoiceAmount] [decimal](12, 2) NULL,
	[TaxBasis] [decimal](12, 2) NULL,
	[TaxAmount] [decimal](12, 2) NULL,
	[Processed On] [datetime] NULL,
	[Note]	VARCHAR(255) null
) ON [PRIMARY]

GO

GRANT SELECT ON [mckARBOTax] TO PUBLIC
go


-- =================================================================================================================================
-- Author:		Amit Mody
-- Create date: 3/24/2015
-- Description:	Data refresh procedure for AR B and O Tax Report.  
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 2015.04.30 LWO				Updated to include SM Work Order Related department information.
-- ==================================================================================================================================

DROP PROCEDURE [dbo].[mckrptARBandOTaxRefresh]
go

create PROCEDURE [dbo].[mckrptARBandOTaxRefresh]
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
		State varchar(2) NULL,
		SMCo	tinyint NULL,
		SMWorkOrderID int null
	)

	INSERT INTO #Multilevel (ARCo, Name, BaseTaxCode, ARTrans, Mth, TaxBaseBasisTotal, TaxBaseAmountTotal, TaxBaseDiscOffTotal, TaxBaseTaxDiscTotal, TotalAmount, Contract, TaxGroup, Item, SMCo, SMWorkOrderID)
      	  SELECT ARTL.ARCo, HQCO.Name, TaxCode, ARTL.ARTrans, ARTL.Mth, sum(TaxBasis), sum(TaxAmount), sum(DiscOffered), sum(TaxDisc), sum(Amount), ARTL.Contract, ARTL.TaxGroup, ARTL.Item, ARTL.udSMCo, ARTL.udSMWorkOrderID
      		FROM ARTL  WITH (NOLOCK) 
      		JOIN ARTH  WITH (NOLOCK) on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans
      		JOIN bHQCO HQCO WITH (NOLOCK) on HQCO.HQCo=ARTL.ARCo
      	  WHERE ARTL.ARCo <= 100
			and ARTL.Mth between '1950-01-01 00:00:00' and '2050-12-01 12:00:00'
   			and ARTH.ARTransType IN ('A','C','I','M','W')
			--AND ARTL.udSMWorkOrderID IS not NULL AND dbo.ARTH.Contract IS null
      	  GROUP BY ARTL.ARCo, Name, TaxCode, ARTL.ARTrans, ARTL.Mth, ARTL.Contract, ARTL.TaxGroup, ARTL.Item, ARTL.udSMCo, ARTL.udSMWorkOrderID

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
		,     COALESCE(d.Instance,d2.Instance,'') as GLDept
		,     COALESCE(d.Description, d2.Description,'') AS GLDeptName
		,     COALESCE(d.OperatingUnit,d2.OperatingUnit, '') AS OperatingUnit
		,	  l.TaxCode
		,	  l.ReportingCode
		,     l.City
		,	  l.State
		,	  CASE WHEN c.Description IS NOT NULL THEN c.Description 
				   ELSE 
						CASE WHEN d2.Instance IS NULL AND l.TaxCode like '%X' THEN 'Unidentified Wholesale'
							 WHEN d2.Instance IS NULL AND l.TaxCode not like '%X' THEN 'Unidentified Retail'
							 --WHEN d2.Instance IS NOT NULL AND l.TaxCode like '%X' THEN '(SM) Unidentified Wholesale'
							 --WHEN d2.Instance IS NOT NULL AND l.TaxCode not like '%X' THEN '(SM) Unidentified Retail'
							 ELSE null
						END
			  END AS BOClass
		,	  l.InvoiceAmount
		,	  l.TaxBasis
		,	  l.TaxAmount
		,	  GETDATE() AS [Processed On]
		,	  COALESCE(CAST(d2.SMCo AS VARCHAR(5)),'') + COALESCE('.' + CAST(d2.SMWorkOrderID AS VARCHAR(20)) ,'')
	FROM (SELECT Mth, ARCo, Contract, Item, ARTrans, TaxGroup, BaseTaxCode AS TaxCode, ReportingCode, City, State,
				 sum(ISNULL(TotalAmount, 0))-sum(ISNULL(TaxBaseAmountTotal, 0)) AS InvoiceAmount,
				 sum(ISNULL(TaxBaseBasisTotal, 0)) as TaxBasis,
				 sum(ISNULL(TaxBaseAmountTotal, 0)) as TaxAmount
				 , SMCo, SMWorkOrderID
		  FROM #Multilevel
		  GROUP BY Mth, ARCo, Contract, Item, ARTrans, TaxGroup, BaseTaxCode, ReportingCode, City, State, SMCo, SMWorkOrderID) l
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
		 LEFT JOIN (SELECT smwo.SMCo, smwo.SMWorkOrderID, smwo.ServiceCenter, glpi.Instance, glpi.Description, udgldept.OperatingUnit
					FROM dbo.SMWorkOrder smwo 
					JOIN dbo.SMServiceCenter smctr ON smwo.SMCo=smctr.SMCo AND smwo.ServiceCenter=smctr.ServiceCenter
					JOIN dbo.SMDepartment smdm ON smctr.SMCo=smdm.SMCo AND smctr.Department=smdm.Department 
					JOIN dbo.GLPI glpi ON smdm.GLCo=glpi.GLCo AND glpi.PartNo=3 AND glpi.Instance=SUBSTRING(smdm.MaterialCostGLAcct,10,4) 
					LEFT JOIN dbo.udGLDept udgldept ON glpi.GLCo=udgldept.Co AND glpi.Instance=udgldept.GLDept) d2
			ON l.SMCo=d2.SMCo AND l.SMWorkOrderID=d2.SMWorkOrderID

	DROP TABLE #Multilevel
END

GO

GRANT EXEC ON [mckrptARBandOTaxRefresh] TO PUBLIC
go


EXEC [dbo].[mckrptARBandOTaxRefresh]
go

SELECT * FROM mckARBOTax --WHERE TaxCode IS null