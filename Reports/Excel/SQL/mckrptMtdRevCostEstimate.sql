IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptMtdRevCostEstimate]'))
	DROP PROCEDURE [dbo].[mckrptMtdRevCostEstimate]
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 11/4/2014 Amit Mody			Authored
** 
******************************************************************************/

CREATE PROCEDURE [dbo].[mckrptMtdRevCostEstimate] 
	@inMonth datetime = NULL
AS
BEGIN
	IF ((@inMonth IS NULL) OR (@inMonth > GETDATE()))
	BEGIN
		SET @inMonth=GETDATE()
	END

	SELECT
		GLDepartment
	,	GLDepartmentName
	,	POC as PocID
	,	POCName as POC
	,	COALESCE(SUM([MTD Earned Revenue]), 0) as [Current MTD Estimated Revenue]
	,	COALESCE(SUM([MTD Actual Cost]), 0) as [Current MTD Actual Costs]
	,	COALESCE(SUM([MTD Earned Gross Margin]), 0) as [Current MTD GM]
	,	CAST(CASE WHEN (COALESCE(SUM([MTD Earned Revenue]), 0) = 0) THEN 0.0
				  ELSE (COALESCE(SUM([MTD Earned Gross Margin]), 0)/SUM([MTD Earned Revenue]))
			 END as numeric(18,8)) as [Current MTD GM %]
	,	COALESCE(SUM([JTD Billed]), 0) as [Current JTD Actual Billing]
	FROM
		dbo.mvwWIPReport
	WHERE 
		ThroughMonth=dbo.mfnFirstOfMonth(@inMonth)
	AND Contract IS NOT NULL
	AND POC IS NOT NULL
	GROUP BY 
		GLDepartment
	,	GLDepartmentName
	,	POC
	,	POCName
	ORDER BY 
		GLDepartmentName
	,	POCName

END
GO

-- Test Scripts
EXEC dbo.mckrptMtdRevCostEstimate
EXEC dbo.mckrptMtdRevCostEstimate '10/31/2014'