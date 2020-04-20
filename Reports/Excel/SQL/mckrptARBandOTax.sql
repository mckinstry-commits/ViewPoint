IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptARBandOTax]'))
	DROP PROCEDURE [dbo].[mckrptARBandOTax]
GO

-- =================================================================================================================================
-- Author:		Eric Shafer
-- Create date: 8/8/2014
-- Description:	Reporting proc for AR B and O Tax Report.  
-- Performs PIVOT on the data to dynamically produce columns and aggregates tax values from AR Invoices (ARTH)
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 09/05/2014 Amit Mody			Updated
-- 09/15/2014 Amit Mody			Updated query for location columns and breakdown of tax amount
-- 12/29/2014 Amit Mody			Removed 'Sales Tax as Reported by AR’ field and appended AR transactions without associated contract
-- 01/20/2015 Amit Mody			Rectified join with dbo.udGLDept to fix un-necessarily excluded AR transactions
-- 02/05/2015 Amit Mody			Filtered resultset by ARTransactionTypes A, C, I, M, W
-- 03/02/2015 Amit Mody			Based processing on dbo.mrptARSalesTaxV2 stored procedure (MCK AR Sales Tax Report)
-- ==================================================================================================================================

CREATE PROCEDURE [dbo].[mckrptARBandOTax] 
	@StartDate datetime = null,
	@EndDate datetime = null
AS
BEGIN
	IF ((@StartDate IS NULL) OR (@StartDate > GETDATE()))
	BEGIN
		SET @StartDate = DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)
	END

	IF ((@EndDate IS NULL) OR (@EndDate < @StartDate) OR (@EndDate > GETDATE()))
	BEGIN
		SET @EndDate = GETDATE()
	END
	
	SELECT	  ARCo
		,     Contract
		,     ARTrans
		,     GLDept
		,     GLDeptName
		,     OperatingUnit
		,	  TaxCode
		,	  ReportingCode
		,     City
		,	  State
		,	  BOClass
		,	  InvoiceAmount
		,	  TaxBasis
		,	  TaxAmount
	FROM	  mckARBOTax
	WHERE	  Mth BETWEEN @StartDate AND @EndDate
	ORDER BY  ARCo, ARTrans

END
GO

--Test Script
--EXEC mckrptARBandOTax
--EXEC mckrptARBandOTax '1/1/2001'
--EXEC mckrptARBandOTax '6/1/2013', '3/31/2014'
--EXEC mckrptARBandOTax '1/1/2015', '3/31/2015'