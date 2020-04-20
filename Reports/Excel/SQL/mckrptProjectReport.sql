IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptProjectReport]'))
	DROP PROCEDURE [dbo].[mckrptProjectReport]
GO

-- =======================================================================================================================
-- Author:		Amit Mody
-- Create date: 10/06/2014
-- Date       Author            Description
-- ---------- ----------------- ------------------------------------------------------------------------------------------
-- 10/08/2014 Amit Mody			Updated
-- 11/03/2014 Amit Mody			Added filtering ability by Company, Department, Contract and PoC
-- 11/11/2014 Amit Mody			Aggregating WIP numbers by contract, updated parameters
-- 11/18/2014 Amit Mody			Added net cash position and AR aged amount calculations
-- 12/08/2014 Amit Mody			Adding date parameter
-- 1/8/2015   Amit Mody			Performance tuning for mitigating table locks
-- 1/20/2015  Amit Mody			Adding Department to selection
-- 1/22/2015  Amit Mody			Attempting elimination of table locks by employing a temp table in lieu of complex joins
-- 1/29/2015  Amit Mody			As Excel/VBA throws error 1004, removing temp table and moving to scheduled processing
-- 2/18/2015  Amit Mody			Added a parameter for generating report for revenue vs. non-revenue contracts
-- 3/09/2015  Amit Mody			Change request (OnTime # 98613)
-- 4/17/2015  Amit Mody			Updating labels from JTD to CTD
-- =======================================================================================================================

CREATE PROCEDURE [dbo].[mckrptProjectReport] 
	@reportMonth datetime = null
,	@company tinyint = null
,	@dept varchar(10) = null
,	@revType varchar(10) = null
,	@contract varchar(10) = null
AS
BEGIN

DECLARE @thisMonth DateTime
SELECT @thisMonth=dbo.mfnFirstOfMonth(@reportMonth)

SELECT	
--	[Month],
	[JCCo]
,	[Contract]
, 	[Contract Description]
,	[GL Department]
,	[GL Department Name]
,	[POC]
,	CASE [Revenue Type] WHEN 'A' THEN 'Straight Line' WHEN 'C' THEN 'Cost-to-Cost' WHEN 'M' THEN 'Cost+Markup' WHEN 'N' THEN 'Non-Revenue' ELSE '' END AS [Revenue Type]
,	CASE [Contract Status] WHEN 1 THEN '1-Open' WHEN 2 THEN '2-Soft Closed' ELSE CAST([Contract Status] AS VARCHAR(20)) END AS [Contract Status] 
,	CONVERT(VARCHAR(10), [Completion Date], 101) as [Contract Completion Date]
--,	[Revenue Type] [varchar](10) NULL
,	RIGHT(CONVERT(VARCHAR(10), [Last Revenue Projection], 103), 7)  as [Last Revenue Projection Month]
,	RIGHT(CONVERT(VARCHAR(10), [Last Cost Projection], 103), 7) as [Last Cost Projection Month]
,	[Original Gross Margin]
,	[Original Gross Margin %]
--,	[Projected Final Billing]
,	[Sales Person]
,	[Customer #] 
,	[Customer Name] 
,	[Customer Contact Name] 
,	[Customer Phone Number]
,	[Customer Email Address]
,   [Current Contract Value]
,	[Projected Final Contract Amount]
,	[Projected COs]
,	[Previous Month Projected Final Contract Amount]
,	[JTD Costs Previous Month] AS [CTD Costs Previous Month]
,	[Previous Month Projected Final Cost]
,	[% Complete Previous Month]
,	[Current JTD Costs] AS [CTD Actual cost]
,	[Current Remaining Committed Cost] AS [CommittedCostAmount]
,	[Current JTD Amount Billed] AS [CTD Billed]
,	[Current JTD Revenue Earned] AS [Current CTD Revenue Earned]
,	[Current JTD Net Under Over Billed] AS [Current CTD Net (Under) Over Billed]
,	[JTD Net Cash Position] AS [CTD Net Cash Position]
,	[Current Retention Unbilled]
,	[Unpaid A/R Balance]
,	[AR Current Amount] AS [AR 1-30 Days Amount]
,	[AR 31-60 Days Amount]
,	[AR 61-90 Days Amount]
,	[AR Over 90 Amount]
,	[Current Projected Final Cost]
,	[Current Projected Final Gross Margin]
,	[Current Projected Final Gross Margin %]
,	[MOM Variance of Projected Final Contract Amount]
,	[MOM Variance of Projected Final Cost]
,	[MOM Variance of Projected Final Gross Margin]
,	[MOM Variance of Projected Final Gross Margin %] 
FROM	dbo.mckProjectReport 
WHERE	Month=@thisMonth 
	AND (@company IS NULL OR JCCo=@company) 
	AND (@dept IS NULL OR [GL Department]=@dept) 
		-- @revType = null (all contracts), 'R' (revenue contracts), 'N' (non-revenue contracts) or 'A'/'C'/'M' (revenue type)
	AND (@revType IS NULL OR (@revType='R' AND [Revenue Type] <> 'N') OR [Revenue Type]=@revType)
	AND (@contract IS NULL OR Contract=@contract)

END
GO

--Test Script
--EXEC [dbo].[mckrptProjectReport]
--EXECUTE [dbo].[mckrptProjectReport]  N'11/1/2014', 1
--EXEC [dbo].[mckrptProjectReport] N'11/1/2014', 1, N'0000'
--EXEC [dbo].[mckrptProjectReport] N'11/1/2014', 1, N'0000', 'N'

--EXEC [dbo].[mckrptProjectReport] N'12/1/2014', 1, null, 'R'
--EXEC [dbo].[mckrptProjectReport] N'12/1/2014', 1, null, 'N'
--EXEC [dbo].[mckrptProjectReport] N'12/1/2014', 1, null, 'C'
--EXEC [dbo].[mckrptProjectReport] N'12/1/2014', 1, null, 'A'
--EXEC [dbo].[mckrptProjectReport] N'12/1/2014', 1, null, 'M'