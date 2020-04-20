use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME='mers')
BEGIN
	print 'SCHEMA ''mers'' already exists  -- McKinstry Enterprise Reporting Schema'
END
ELSE
BEGIN
	print 'CREATE SCHEMA ''mers'' -- McKinstry Enterprise Reporting Schema'
	EXEC sp_executesql N'CREATE SCHEMA mers AUTHORIZATION dbo'
END
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnARDetail')
begin
	print 'DROP FUNCTION mers.mfnARDetail'
	DROP FUNCTION mers.mfnARDetail
end
go

print 'CREATE FUNCTION mers.mfnARDetail'
GO


CREATE FUNCTION mers.mfnARDetail 
(	
	-- Declare Input Parameters
	@ARCo bCompany = null
,	@AgeDate bDate = NULL
,	@Month bMonth = NULL
,	@IncludeInvoicesThrough bDate = NULL
,	@IncludeAdjPayThrough bDate = null
)
RETURNS @rettable TABLE
(
	[ARCo]					[dbo].[bCompany] NOT NULL,
	[ARMth]					[dbo].[bMonth] NOT NULL,
	[ARTrans]				[dbo].[bTrans] NOT NULL,
	[CustGroup]				[dbo].[bGroup] NULL,
	[Customer]				[dbo].[bCustomer] NULL,
	[CustomerName]			[varchar](60) NULL,
	[ARInvoiceDesc]			[dbo].[bItemDesc] NULL,
	[ARTransType]			[char](1) NOT NULL,
	[AmountDue]				[dbo].[bDollar] NOT NULL,
	[ARLine]				[smallint] NOT NULL,
	[ARInvoiceLineDesc]		[dbo].[bItemDesc] NULL,
	[GLDepartment]			[char](20) NULL,
	[GLDepartmentName]		[dbo].[bDesc] NULL,
	[AgeDate]				[dbo].[bDate] NOT NULL,
	[DaysFromAge]			[int] NULL,
	[AgeAmount]				bDollar		NOT NULL DEFAULT (0.00),
	[Amount]				bDollar		NOT NULL DEFAULT (0.00),
	[Retainage]				bDollar		NOT NULL DEFAULT (0.00),
	[DiscOffered]			bDollar		NOT NULL DEFAULT (0.00),
	[DueCurrent]			bDollar		NOT NULL DEFAULT (0.00),
	[Due30to60]				bDollar		NOT NULL DEFAULT (0.00),
	[Due60to90]				bDollar		NOT NULL DEFAULT (0.00),
	[Due60to120]			bDollar		NOT NULL DEFAULT (0.00),
	[Due120Plus]			bDollar		NOT NULL DEFAULT (0.00),
	[ApplyMth]				[dbo].[bMonth] NOT NULL,
	[ApplyTrans]			[dbo].[bTrans] NOT NULL,
	[GLCo]					[dbo].[bCompany] NULL,
	[GLAcct]				[dbo].[bGLAcct] NULL,
	[JCCo]					[dbo].[bCompany] NULL,
	[Contract]				[dbo].[bContract] NULL,
	[ContractDesc]			[dbo].[bItemDesc] NULL,
	[ContractPOC]			[varchar](30) NULL,
	[ContractItem]			[dbo].[bContractItem] NULL,
	[ContractItemDesc]		[dbo].[bItemDesc] NULL,
	[SMWOType]				[varchar](10) NULL,
	[SMWOTypeDesc]			[varchar](8) NULL,
	[SMCo]					[dbo].[bCompany] NULL,
	[SMWorkOrder]			[int] NULL,
	[SMServiceSite]			[varchar](60) NULL,
	[Job]					[dbo].[bJob] NULL
)
/*
	2015.03.03 LWO - Created

	Full enumeration of all outstanding Accounts Receivable showing related information for Jobs, Contracts, Service Work Orders and GL associations.
	
*/
BEGIN


	IF @AgeDate IS  NULL
		SELECT @AgeDate = CAST(GETDATE() AS SMALLDATETIME);

	IF @Month IS NULL
		SELECT @Month = CAST(CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS SMALLDATETIME);

	IF @IncludeInvoicesThrough IS NULL
		SELECT @IncludeInvoicesThrough=@AgeDate;
	
	IF @IncludeAdjPayThrough IS NULL
		SELECT @IncludeAdjPayThrough=@AgeDate;

WITH ardata as
(
Select ARTL.ARCo, ApplyMth, ApplyTrans 
From 
	ARTL     
Join ARTH on 
	ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans    
Where 
	ARTL.ARCo < 100
and (ARTL.ARCo=@ARCo OR @ARCo IS NULL )
and	ARTL.Mth<=@Month 
and ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end    
Group By 
	ARTL.ARCo, ApplyMth, ApplyTrans 
having 
	--( SUM(isnull(ARTL.Amount,0))-SUM(isnull(ARTL.DiscOffered,0))-SUM(isnull(ARTL.Retainage,0)) ) <> 0
	--SUM(isnull(ARTL.Amount,0)-isnull(ARTL.DiscOffered,0)-isnull(ARTL.Retainage,0)) <> 0
	sum(ARTL.Retainage)<>0 or sum(ARTL.Amount)<>0    
)
INSERT @rettable
(
	 [ARCo]					--[dbo].[bCompany] NOT NULL,
	,[ARMth]					--[dbo].[bMonth] NOT NULL,
	,[ARTrans]				--[dbo].[bTrans] NOT NULL,
	,[CustGroup]				--[dbo].[bGroup] NULL,
	,[Customer]				--[dbo].[bCustomer] NULL,
	,[CustomerName]			--[varchar](60) NULL,
	,[ARInvoiceDesc]			--[dbo].[bDesc] NULL,
	,[ARTransType]			--[char](1) NOT NULL,
	,[AmountDue]				--[dbo].[bDollar] NOT NULL,
	,[ARLine]				--[smallint] NOT NULL,
	,[ARInvoiceLineDesc]		--[dbo].[bDesc] NULL,
	,[GLDepartment]			--[char](20) NULL,
	,[GLDepartmentName]		--[dbo].[bDesc] NULL,
	,[AgeDate]				--[dbo].[bDate] NOT NULL,
	,[DaysFromAge]			--[int] NULL,
	,[AgeAmount]				--bDollar		NOT NULL DEFAULT (0.00),
	,[Amount]				--bDollar		NOT NULL DEFAULT (0.00),
	,[Retainage]				--bDollar		NOT NULL DEFAULT (0.00),
	,[DiscOffered]			--bDollar		NOT NULL DEFAULT (0.00),
	,[DueCurrent]			--bDollar		NOT NULL DEFAULT (0.00),
	,[Due30to60]				--bDollar		NOT NULL DEFAULT (0.00),
	,[Due60to90]				--bDollar		NOT NULL DEFAULT (0.00),
	,[Due60to120]			--bDollar		NOT NULL DEFAULT (0.00),
	,[Due120Plus]			--bDollar		NOT NULL DEFAULT (0.00),
	,[ApplyMth]				--[dbo].[bMonth] NOT NULL,
	,[ApplyTrans]			--[dbo].[bTrans] NOT NULL,
	,[GLCo]					--[dbo].[bCompany] NULL,
	,[GLAcct]				--[dbo].[bGLAcct] NULL,
	,[JCCo]					--[dbo].[bCompany] NULL,
	,[Contract]				--[dbo].[bContract] NULL,
	,[ContractDesc]			--[dbo].[bItemDesc] NULL,
	,[ContractPOC]			--[varchar](30) NULL,
	,[ContractItem]			--[dbo].[bContractItem] NULL,
	,[ContractItemDesc]		--[dbo].[bItemDesc] NULL,
	,[SMCo]					--[dbo].[bCompany] NULL,
	,[SMWorkOrder]			--[int] NULL,
	,[SMServiceSite]			--[varchar](60) NULL,
	,[SMWOType]				--[varchar](10) NULL,
	,[SMWOTypeDesc]			--[varchar](8) NULL,
	,[Job]					--[dbo].[bJob] NULL
)
SELECT
	artl.ARCo
,	artl.Mth
,	artl.ARTrans
,	COALESCE(arth.CustGroup,jccm.CustGroup,smsite.CustGroup) AS CustGroup
,	COALESCE(arth.Customer, jccm.Customer, smsite.Customer) AS Customer
,	arcm.Name AS CustomerName
,	COALESCE(arth.Description, jcci.Description, jccm.Description,smwo.Description) AS ARInvoiceDesc
,	arth.ARTransType
,	arth.AmountDue
,	artl.ARLine
,	COALESCE(artl.Description,arth.Description, jcci.Description, jccm.Description,smwo.Description) AS ARInvoiceLineDesc
,	COALESCE(glpi.Instance, glpi_g.Instance) AS GLDepartment
,	COALESCE(glpi.Description, glpi_g.Description) AS GLDepartmentName
,	isnull(arth.DueDate,arth.TransDate) AS AgeDate
,	DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) AS DaysFromAge
,	isnull(artl.Amount,0)-isnull(artl.DiscOffered,0)-isnull(artl.Retainage,0)  AS AgeAmount    
,	isnull(artl.Amount,0)-0 AS Amount
,	isnull(artl.Retainage,0)-0 AS Retainage
,	isnull(artl.DiscOffered,0)-0 AS DiscOffered
,	CASE 
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) < 30 THEN isnull(artl.Amount,0)-isnull(artl.DiscOffered,0)-isnull(artl.Retainage,0) 
		ELSE 0
	END AS DueCurrent
,	CASE
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) between 30 and 60 THEN isnull(artl.Amount,0)-isnull(artl.DiscOffered,0)-isnull(artl.Retainage,0) 
		ELSE 0
	END AS Due30to60
,	CASE 
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) between 60 and 90  THEN isnull(artl.Amount,0)-isnull(artl.DiscOffered,0)-isnull(artl.Retainage,0) 
		ELSE 0
	END AS Due60to90
,	CASE 
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) between 90 and 120  THEN isnull(artl.Amount,0)-isnull(artl.DiscOffered,0)-isnull(artl.Retainage,0) 
		ELSE 0
	END AS Due60to120
,	CASE 
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) > 120  THEN isnull(artl.Amount,0)-isnull(artl.DiscOffered,0)-isnull(artl.Retainage,0) 
		ELSE 0
	END AS Due120Plus
,	artl.ApplyMth
,	artl.ApplyTrans
,	artl.GLCo
,	artl.GLAcct
,	artl.JCCo
,	artl.Contract
,	jccm.Description AS ContractDesc
,	jcmp.Name AS ContractPOC
,	artl.Item AS ContractItem
,	jcci.Description AS ContractItemDesc
--,	artl.Job
--,	artl.PhaseGroup
--,	artl.Phase
--,	artl.CostType
,	artl.udSMCo AS SMCo
,	artl.udWorkOrder AS SMWorkOrder
,	smsite.Description AS SMServiceSite
,	smsite.Type AS SMWOType
,	CASE 
		WHEN artl.udWorkOrder IS NOT NULL AND smsite.Type='Job' THEN 'PM/SPG'
		WHEN artl.udWorkOrder IS NOT NULL AND smsite.Type<>'Job' THEN 'BreakFix'
		ELSE NULL
    END AS SMWOTypeDesc
,	smsite.Job
FROM 
		HQCO hqco
JOIN ARTL artl ON
	hqco.HQCo=artl.ARCo
AND hqco.udTESTCo <> 'Y'
JOIN ARTH arth ON
	artl.ARCo=arth.ARCo
AND artl.Mth=arth.Mth
AND artl.ARTrans=arth.ARTrans
JOIN ardata ardata ON
	ardata.ARCo=artl.ARCo 
and ardata.ApplyMth=artl.ApplyMth 
and ardata.ApplyTrans=artl.ApplyTrans
LEFT OUTER JOIN ARCM arcm ON
	arth.CustGroup=arcm.CustGroup
AND arth.Customer=arcm.Customer
LEFT OUTER JOIN JCCI jcci ON
	artl.JCCo=jcci.JCCo
AND artl.Contract=jcci.Contract
AND artl.Item=jcci.Item
LEFT OUTER JOIN JCCM jccm ON
	jccm.JCCo=jcci.JCCo
AND jccm.Contract=jcci.Contract
LEFT OUTER JOIN ARCM arcm_c ON
	jccm.CustGroup=arcm_c.CustGroup
AND jccm.Customer=arcm_c.Customer
LEFT OUTER JOIN JCDM jcdm ON
	jcci.JCCo=jcdm.JCCo
AND jcci.Department=jcdm.Department
LEFT OUTER JOIN GLPI glpi ON
	jcdm.GLCo=glpi.GLCo
AND glpi.PartNo=3
AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4)
LEFT OUTER JOIN GLPI glpi_g ON
	artl.GLCo=glpi_g.GLCo
AND glpi_g.PartNo=3
AND glpi_g.Instance=SUBSTRING(artl.GLAcct,10,4)
LEFT OUTER JOIN SMWorkOrder smwo ON
	artl.udSMCo=smwo.SMCo
AND artl.udWorkOrder=smwo.WorkOrder
LEFT OUTER JOIN SMServiceSite smsite ON
	smwo.SMCo=smsite.SMCo
AND smwo.ServiceSite=smsite.ServiceSite
LEFT OUTER JOIN JCMP jcmp ON
	jccm.JCCo=jcmp.JCCo
AND jccm.udPOC=jcmp.ProjectMgr
WHERE
	( artl.ARCo=@ARCo OR @ARCo IS NULL )
AND artl.Mth<=@Month
AND (arth.TransDate <= case when arth.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end)   


RETURN

END 
go

GRANT SELECT ON mers.mfnARDetail TO PUBLIC
go


--DECLARE @ARCo bCompany
--DECLARE @AgeDate bDate
--DECLARE @Month bMonth
--DECLARE @IncludeInvoicesThrough bDate
--DECLARE @IncludeAdjPayThrough bDate

--select 
--	@ARCo=null
--,	@AgeDate=CAST(GETDATE() AS SMALLDATETIME)
--,	@Month='3/1/2015'
--,	@IncludeInvoicesThrough=@AgeDate
--,	@IncludeAdjPayThrough=@AgeDate;

--SELECT * FROM mers.mfnARDetail(@ARCo,@AgeDate,@Month,@IncludeInvoicesThrough,@IncludeAdjPayThrough) 
GO

SELECT * FROM mers.mfnARDetail(1,'3/1/2015','3/1/2015',NULL,NULL) 