IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[mers].[mckrptContractCloseSC]'))
	DROP PROCEDURE [mers].[mckrptContractCloseSC]
GO

/**********************************************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- ---------------------------------------------------------------------------
** 3/24/2015 Amit Mody			Authored
** 4/27/2015 Amit Mody			Swapped contract number by POC, 
**								Rolled back Sales/VAT tax update applied after 4/2/2015
**								Added Open Amount Remaining and Amount Unpaid columns
***********************************************************************************************************/
SET ANSI_WARNINGS OFF;
GO

CREATE PROCEDURE [mers].[mckrptContractCloseSC]
	@company	tinyint = NULL,
	@dept		varchar(4) = NULL,
	@poc		int = NULL,
	@status		tinyint = NULL,
	@closefrom	smalldatetime = NULL,
	@closeto	smalldatetime = NULL
AS
BEGIN
	IF @closefrom IS NULL
		SELECT @closefrom = MIN(ProjCloseDate) FROM JCCM

	IF @closeto IS NULL
		SELECT @closeto = MAX(ProjCloseDate) FROM JCCM
	
	SELECT	 jccm.JCCo AS JCCo
			,jccm.Contract AS Contract
			,jccm.Description AS [Contract Description]
			,SUBSTRING(jcdm.OpenRevAcct,10,4) AS [Contract GL Dept]
			,j.Job
			,CASE WHEN j.JobStatus IS NULL THEN ''
				  WHEN j.JobStatus = 0 THEN '0-Pending'
				  WHEN j.JobStatus = 1 THEN '1-Open'
				  WHEN j.JobStatus = 2 THEN '2-Soft Closed'
				  WHEN j.JobStatus = 3 THEN '3-Closed'
			 END AS [Job Status]
			,j.[PM]
			,s.CurrContract AS [SubContract Amount]
			,s.CurrBilledAmt AS [Invoiced Amount]
			,s.PaidAmt AS [Paid Amount]
			,s.CurrContract - s.CurrBilledAmt AS [Open Amount Remaining]
			,s.CurrBilledAmt - s.PaidAmt AS [Amount Unpaid]
		 FROM   (SELECT "brvSLSubContrByJob"."Job"
					  , "brvSLSubContrByJob"."JCCo"
					  , ISNULL(SUM(
							CASE WHEN brvSLSubContrByJob.Mth <= GETDATE() 
								 THEN (ISNULL(brvSLSubContrByJob.OrigItemCost, 0.0) + ISNULL(brvSLSubContrByJob.ChangeOrderCost, 0.00)) --OrigItemCost + ChangeOrderCost
								 ELSE ISNULL(brvSLSubContrByJob.OrigItemCost, 0.0)
							END
						), 0.00) AS CurrContract
					  , ISNULL(SUM(
							CASE WHEN brvSLSubContrByJob.Mth <= GETDATE()
								  THEN 
									CASE WHEN brvSLSubContrByJob.TaxType IN (0,2) THEN ISNULL(brvSLSubContrByJob.APTDAmt, 0.0)
										 WHEN brvSLSubContrByJob.TaxType IN (1,3) THEN ISNULL(brvSLSubContrByJob.APTDAmt,0.0) - ISNULL(brvSLSubContrByJob.APTDTaxAmt,0.0)
										 ELSE ISNULL(brvSLSubContrByJob.APTDAmt,0.0)
									END
								  ELSE 0
							 END
						 ), 0.00) AS CurrBilledAmt
					   , ISNULL(SUM(
							 CASE WHEN (brvSLSubContrByJob.APTDStatus > 2 and brvSLSubContrByJob.Mth <= GETDATE() and (brvSLSubContrByJob.APPaidMth <= GETDATE() or brvSLSubContrByJob.APPaidMth = '1/1/1950'))
								  THEN
										CASE WHEN (brvSLSubContrByJob.TaxType IN (0,2)) THEN ISNULL(brvSLSubContrByJob.APTDAmt, 0.0)
											 WHEN (brvSLSubContrByJob.TaxType IN (1,3)) THEN ISNULL(brvSLSubContrByJob.APTDAmt,0.0) - ISNULL(brvSLSubContrByJob.APTDTaxAmt,0.0)
											 ELSE ISNULL(brvSLSubContrByJob.APTDAmt,0.0)
										END
								  ELSE 0
							END
						 ), 0.00) AS PaidAmt
				 FROM   "Viewpoint"."dbo"."brvSLSubContrByJob" "brvSLSubContrByJob" 
						 INNER JOIN "Viewpoint"."dbo"."JCJM" "JCJM" ON ("brvSLSubContrByJob"."JCCo"="JCJM"."JCCo") AND ("brvSLSubContrByJob"."Job"="JCJM"."Job")
				 WHERE  "brvSLSubContrByJob"."SLCo"<100 AND
						--("brvSLSubContrByJob"."Job"=' 20676-001') AND
					    "brvSLSubContrByJob"."Mth"<{ts '2050-12-02 00:00:00'} AND
					    "brvSLSubContrByJob"."ItemType"<>3
				 GROUP BY 
						"brvSLSubContrByJob"."Job"
					  , "brvSLSubContrByJob"."JCCo") s
				 INNER JOIN 
					 (SELECT distinct jcci.JCCo, jcci.Contract, jcjm.Job, jcjm.JobStatus, ISNULL(jcmp.Name, '') AS [PM]
					  FROM dbo.JCJM jcjm
						INNER JOIN dbo.JCJP jcjp ON jcjp.JCCo=jcjm.JCCo AND jcjp.Job=jcjm.Job 
						INNER JOIN dbo.JCCI jcci ON jcci.JCCo=jcjp.JCCo and jcci.Contract=jcjp.Contract and jcci.Item=jcjp.Item	
						LEFT JOIN dbo.JCMP jcmp ON jcjm.JCCo=jcmp.JCCo AND jcjm.ProjectMgr=jcmp.ProjectMgr
					  ) j ON s.JCCo=j.JCCo AND s.Job=j.Job
				  INNER JOIN dbo.JCCM jccm ON j.JCCo=jccm.JCCo AND j.Contract=jccm.Contract 
				  INNER JOIN dbo.JCDM jcdm ON jccm.JCCo=jcdm.JCCo AND jccm.Department=jcdm.Department
	WHERE	(@company IS NULL OR jccm.JCCo = @company)
		AND (@poc IS NULL OR jccm.udPOC = @poc)
		AND (@dept IS NULL OR SUBSTRING(jcdm.OpenRevAcct,10,4) = @dept)
		AND (@status IS NULL OR jccm.ContractStatus = @status)
		AND (jccm.ProjCloseDate IS NULL OR jccm.ProjCloseDate BETWEEN @closefrom AND @closeto)
	ORDER BY 1, 2, 4, 5

END
GO

GRANT EXECUTE
    ON OBJECT::[mers].[mckrptContractCloseSC] TO [MCKINSTRY\ViewpointUsers];
GO

--Test script
--EXEC mers.mckrptContractCloseSC
--EXEC mers.mckrptContractCloseSC 1, '0000'
--EXEC mers.mckrptContractCloseSC 1, '0000', null, 2
--EXEC mers.mckrptContractCloseSC 1, null, 56028
--EXEC mers.mckrptContractCloseSC 1, null, null, 1, '1/1/2015', '3/31/2015'
--EXEC mers.mckrptContractCloseSC 20
--EXEC mers.mckrptContractCloseSC 20, null, 78431
--EXEC mers.mckrptContractCloseSC 1, '9999'