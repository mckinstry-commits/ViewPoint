use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckfnRetainSum' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION dbo.mckfnRetainSum'
	DROP FUNCTION dbo.mckfnRetainSum
end
go

print 'CREATE FUNCTION dbo.mckfnRetainSum'
go

CREATE FUNCTION [dbo].[mckfnRetainSum]
(
	  @JCCo			bCompany
    , @Dept			bDept
	, @Contract		bContract
	, @Customer		bCustomer  
)
-- ========================================================================
-- Object Name: dbo.mckfnRetainSum
-- Author:		Ziebell, Jonathan
-- Create date: 05/26/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	05/26/2017 Initial Build
-- ========================================================================

--RETURNS @retTable TABLE
--(
--	[PO Req #] [varchar](30) NOT NULL,
--	[McK PO] [varchar](30) NULL,
--	[Description] [dbo].[bItemDesc] NULL,
--	[Vendor] [dbo].[bVendor] NOT NULL,
--	[Vendor Name] [varchar](60) NULL,
--	[PO Status] [varchar](13) NULL,
--	[PO Amount] [dbo].[bDollar] NOT NULL,
--	[Invoiced] [dbo].[bDollar] NOT NULL,
--	[Paid] [dbo].[bDollar] NOT NULL,
--	[Current Due] [dbo].[bDollar] NOT NULL,
--	[Remaining Committed] [dbo].[bDollar] NULL,
--	[Phase Code] [dbo].[bPhase] NULL,
--	[Phase Code Description] [dbo].[bItemDesc] NULL,
--	[WO #] [int] NULL,
--	[Work Order Description] [varchar](50) NULL,
--	[Ordered By] [int] NULL,
--	[Ordered By Name] [varchar](62) NULL,
--	[Order Date] [dbo].[bDate] NULL
--	)
RETURNS TABLE
AS RETURN
--BEGIN
	WITH JBIT_SUM AS (SELECT	  IT.JBCo
								, IT.Contract
								--, IT.Item
								--, IT.Description  --Get from JCCI?
								, MAX(IT.BillMonth) As MaxMonth
								, SUM(IT.AmtBilled) as AmtBilled
								, SUM(IT.RetgBilled) as RetgBilled
								, SUM(IT.RetgRel) AS RetgRel
								--, SUM(IT.WC) AS WC
								--, SUM(IT.WCRetg) AS WCRetg
								, SUM(IT.TaxAmount) As TaxAmount
						FROM JBIT IT
						WHERE IT.JBCo = @JCCo
							AND ISNULL(@Contract,IT.Contract) = IT.Contract
						GROUP BY IT.JBCo
								, IT.Contract
								/*, IT.Item
								, IT.Description*/),
	ARTL_SUM AS (SELECT	  AR.JCCo
								, AR.Contract
								--, AR.Item
								, SUM(AR.Retainage) as ARRetainage
						FROM ARTL AR
						WHERE AR.JCCo = @JCCo
							AND ISNULL(@Contract,AR.Contract) = AR.Contract
						GROUP BY AR.JCCo
								, AR.Contract)
								--, AR.Item)
	--INSERT @retTable
 --        ([PO Req #] 
 --        ,[McK PO]
	--	   ,[Description]
 --        ,[Vendor]
 --        ,[Vendor Name]
	--	   ,[PO Status]
	--	   ,[PO Amount]
	--	   ,[Invoiced] 
	--	   ,[Paid]
	--	   ,[Current Due] 
	--	   ,[Remaining Committed]
	--	   ,[Phase Code]
 --        ,[Phase Code Description]
	--	   ,[WO #] 
	--	   ,[Work Order Description]
 --        ,[Ordered By]
 --        ,[Ordered By Name]
 --        ,[Order Date]
	--	   )
	SELECT	--CM.JCCo
		 CM.Contract
		, CM.Description AS 'Contract Description'
		--, CI.Item
		--, CI.Description AS 'Item Description'
		, CM.Department AS 'JC Department'
		, DM.udGLDept AS 'GL Department'
		, LP.Description AS 'GL Department Name'
		, CM.Customer
		, AR.Name AS 'Customer Name'
		, CM.udPOC AS 'POC'
		, MP.Name AS 'POC Name'
		, vddci.DisplayValue AS 'Contract Status'
		--, CM.ContractStatus
		, CM.MonthClosed AS 'Date Closed'
		, CM.ProjCloseDate As 'Projected Completion Date'
		, JS.MaxMonth AS 'Last Invoice Month'
		, CM.ContractAmt 
		, JS.AmtBilled
		, CASE WHEN CM.ContractAmt <= 0 THEN 0
				ELSE (JS.AmtBilled/CM.ContractAmt) END AS 'Percent Billed'
		, CM.RetainagePCT AS 'Contract Retainage %'
		, CASE WHEN JS.AmtBilled <= 0 THEN 0
				ELSE (JS.RetgBilled/JS.AmtBilled) END AS 'Invoiced Retainage %'
		, JS.RetgBilled AS 'Retainage Held'
		, JS.RetgRel AS 'Retainage Released JB'
		, (JS.RetgBilled - JS.RetgRel) AS 'Outstanding Retainage JB'
		, ARS.ARRetainage AS 'Outstanding Retainage AR'
		, (JS.RetgBilled - JS.RetgRel - ARS.ARRetainage) AS 'Outstanding JB - AR'
		, JS.TaxAmount
FROM JCCM CM
	--INNER JOIN JCCI CI
	--	ON CM.JCCo = CI.JCCo
	--	AND CM.Contract = CI.Contract
	INNER JOIN JCDM DM
		ON CM.JCCo = DM.JCCo
		AND CM.Department = DM.Department
	LEFT OUTER JOIN JBIT_SUM JS
		ON CM.JCCo = JS.JBCo
		AND CM.Contract = JS.Contract
		--AND CI.Item = JS.Item
	LEFT OUTER JOIN ARTL_SUM ARS
		ON CM.JCCo = ARS.JCCo
		AND CM.Contract = ARS.Contract
		--AND CI.Item = ARS.Item
	LEFT OUTER JOIN GLPI LP
		ON CM.JCCo = LP.GLCo
		AND DM.udGLDept = LP.Instance
		AND LP.PartNo = 3
	LEFT OUTER JOIN ARCM AR
		ON CM.CustGroup = AR.CustGroup
			AND CM.Customer = AR.Customer
	LEFT OUTER JOIN JCMP MP
		ON CM.JCCo = MP.JCCo
			AND CM.udPOC = MP.ProjectMgr
	LEFT OUTER JOIN  vDDCI vddci 
		ON vddci.ComboType='JCContractStatus'
			AND vddci.DatabaseValue = CM.ContractStatus
WHERE CM.JCCo =  @JCCo
	AND ISNULL(@Contract,CM.Contract) = CM.Contract 
	AND ISNULL(@Customer,CM.Customer) = CM.Customer
	AND ISNULL(@Dept,DM.udGLDept) = DM.udGLDept
	AND CM.ContractStatus in (1,2)
	AND CM.ContractAmt > 0 
	AND CM.CurrentRetainAmt <> 0

--RETURN

--END

GO

Grant select on dbo.mckfnRetainSum  to [MCKINSTRY\Viewpoint Users]


