IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[mers].[mckrptContractClosePO]'))
	DROP PROCEDURE [mers].[mckrptContractClosePO]
GO

/**********************************************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- ---------------------------------------------------------------------------
** 3/18/2015 Amit Mody			Authored
** 4/02/2015 Amit Mody			Added Job Status
** 4/27/2015 Amit Mody			Swapped contract number by POC, 
**								Rolled back Sales/VAT tax update applied after 4/2/2015,
**								Added Open Amount Remaining, Amount Unpaid and Jobs PO Status columns
***********************************************************************************************************/
SET ANSI_WARNINGS OFF;
GO

CREATE PROCEDURE [mers].[mckrptContractClosePO]
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
	
	SELECT	 jccm.JCCo
			,jccm.Contract
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
			,ISNULL(s.JobPOStatus, 'Unknown') AS [PO Status (Jobs)]
			,ISNULL(s.JobPOAmt, 0.0) AS [PO Amount (Jobs)]
			,ISNULL(s.JobInvAmt, 0.0) AS [Invoiced Amount (Jobs)]
			,ISNULL(s.JobPaidAmt, 0.0) AS [Paid Amount (Jobs)]
			,ISNULL(s.JobPOAmt, 0.0) - ISNULL(s.JobInvAmt, 0.0) AS [Open Amount Remaining (Jobs)]
			,ISNULL(s.JobInvAmt, 0.0) - ISNULL(s.JobPaidAmt, 0.0) AS [Amount Unpaid (Jobs)]
			,ISNULL(s.WOPOAmt, 0.0) AS [PO Amount (Workorders)]
			,ISNULL(s.WOInvAmt, 0.0) AS [Invoiced Amount (Workorders)]
			,ISNULL(s.WOPaidAmt, 0.0) AS [Paid Amount (Workorders)]
			,ISNULL(s.WOPOAmt, 0.0) - ISNULL(s.WOInvAmt, 0.0) AS [Open Amount Remaining (Workorders)]
			,ISNULL(s.WOInvAmt, 0.0) - ISNULL(s.WOPaidAmt, 0.0) AS [Amount Unpaid (Workorders)]
		 FROM   (SELECT	ISNULL(c.JCCo, d.JCCo) AS JCCo
					,	ISNULL(c.Job, d.Job) AS Job
					,	ISNULL(c.JobPOAmt, 0.0) as JobPOAmt
					,	ISNULL(c.JobInvAmt, 0.0) as JobInvAmt
					,	ISNULL(c.JobPaidAmt, 0.0) as JobPaidAmt
					,	ISNULL(c.JobPOStatus, 'Unknown') as JobPOStatus
					,	ISNULL(d.WOPOAmt, 0.0) as WOPOAmt
					,	ISNULL(d.WOInvAmt, 0.0) as WOInvAmt
					,	ISNULL(d.WOPaidAmt, 0.0) as WOPaidAmt
				 FROM		(SELECT JCCo, Job,
									CASE WHEN (SUM(ISNULL(Status, 2)) = 2 * count(*)) THEN 'All Closed' ELSE 'PO(s) Open' END AS JobPOStatus,
									SUM(ISNULL(CurCost, 0.0)-ISNULL(CurTax, 0.0)) AS JobPOAmt, 
									SUM(ISNULL(InvCost, 0.0)-ISNULL(InvCostTax, 0.0)) AS JobInvAmt, 
									SUM(ISNULL(APPaidAmt, 0.0)-ISNULL(APTotTaxAmount, 0.0)) AS JobPaidAmt
							 FROM	dbo.mrvPOCurCostByVendor
							 WHERE	JCCo < 100 AND (@company IS NULL OR JCCo = @company)
							 GROUP BY JCCo, Job) c 
						FULL OUTER JOIN
							(SELECT	COALESCE(poit.JCCo,smsite.SMCo) AS JCCo
								,	COALESCE(poit.Job,smsite.Job) AS Job
								,	SUM(ISNULL(poit.CurCost, 0.0)) AS WOPOAmt
								,	SUM(ISNULL(poit.InvCost, 0.0)) AS WOInvAmt
								,	SUM(CASE WHEN ISNULL(a.Status, 0) > 2 THEN ISNULL(a.Amount, 0.0) ELSE 0.0 END) AS WOPaidAmt
							 FROM	POHD pohd
									INNER JOIN POIT poit ON pohd.POCo=poit.POCo AND pohd.PO=poit.PO
									INNER JOIN SMWorkCompleted smwo_wc ON poit.SMCo=smwo_wc.SMCo AND poit.SMWorkOrder=smwo_wc.WorkOrder AND poit.SMScope=smwo_wc.Scope AND poit.POItem=smwo_wc.POItem AND poit.POCo=smwo_wc.POCo AND poit.PO=smwo_wc.PO
									INNER JOIN SMWorkOrder smwo ON smwo_wc.SMCo=smwo.SMCo AND smwo_wc.WorkOrder=smwo.WorkOrder 
									INNER JOIN SMServiceSite smsite ON smwo.SMCo=smsite.SMCo AND smwo.ServiceSite=smsite.ServiceSite
									LEFT JOIN 
										(SELECT APTL.APCo, APTL.PO, APTD.Status, APTD.Amount
											FROM APTL INNER JOIN APTD ON APTL.APCo=APTD.APCo AND APTL.Mth=APTD.Mth AND APTL.APTrans=APTD.APTrans AND APTL.APLine=APTD.APLine 
											WHERE APTL.APCo<100 AND (@company IS NULL OR APTL.APCo=@company)
										) a ON pohd.POCo=a.APCo AND pohd.PO=a.PO
							 WHERE	pohd.POCo<100 AND (@company IS NULL OR pohd.POCo=@company) AND poit.ItemType=6 AND smsite.Type='Job'
							 GROUP BY poit.JCCo, smsite.SMCo, poit.Job, smsite.Job
							) d
						ON c.JCCo = d.JCCo AND c.Job = d.Job
				  ) s 
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
    ON OBJECT::[mers].[mckrptContractClosePO] TO [MCKINSTRY\ViewpointUsers];
GO

--Test script
--EXEC mers.mckrptContractClosePO
--EXEC mers.mckrptContractClosePO 1, '0000'
--EXEC mers.mckrptContractClosePO 1, '0000', null, 2
--EXEC mers.mckrptContractClosePO 1, null, 56028
--EXEC mers.mckrptContractClosePO 1, null, null, 1, '1/1/2015', '3/31/2015'
--EXEC mers.mckrptContractClosePO 1, '9999'