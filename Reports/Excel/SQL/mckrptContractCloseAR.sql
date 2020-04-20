IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[mers].[mckrptContractCloseAR]'))
	DROP PROCEDURE [mers].[mckrptContractCloseAR]
GO

/**********************************************************************************************************
** Change History
** Date       Author		Description
** ---------- ------------- ---------------------------------------------------------------------------
** 3/24/2015 Amit Mody		Authored
** 4/02/2015 Amit Mody		Updated column name from Contract Close Date to Projected Close Date
** 4/27/2015 Amit Mody		Swapped Contract with POC as a parameter
**							Added Open Contract amount and Uncollected AR columns
***********************************************************************************************************/

CREATE PROCEDURE [mers].[mckrptContractCloseAR]
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

	SELECT	s.JCCo, 
			s.Contract, 
			jccm.Description AS [Contract Description],  
			glpi.Instance AS [Contract GL Dept],
			jcmp.Name as [POC],
			CASE WHEN jccm.ContractStatus IS NULL THEN ''
				 WHEN jccm.ContractStatus = 0 THEN '0-Pending'
				 WHEN jccm.ContractStatus = 1 THEN '1-Open'
				 WHEN jccm.ContractStatus = 2 THEN '2-Soft Closed'
				 WHEN jccm.ContractStatus = 3 THEN '3-Hard Closed'
				 ELSE ''
			END AS [Contract Status],
			ISNULL(CONVERT(VARCHAR(10), jccm.ProjCloseDate, 101), '') AS [Projected Close Date],
			s.ContractAmt AS [Current Contract Amount],
			s.BilledAmt AS [Billed Amount], 
			s.ReceivedAmt AS [Amount Received],
			s.BilledTax AS [Billed Tax],
			ISNULL(CONVERT(VARCHAR(20), b.LatestBilling, 101), '') AS [Last Billing Date],
			s.ContractAmt - s.BilledAmt AS [Open Contract amount],
			s.ReceivedAmt - s.BilledAmt - s.BilledTax AS [Uncollected AR]
	FROM	(SELECT JCCo, Contract, 
					MAX(Mth) AS LastBillingDate,
					SUM(ISNULL(ContractAmt, 0)) AS ContractAmt,		
					SUM(ISNULL(BilledAmt,0)) AS BilledAmt, 
					SUM(ISNULL(ReceivedAmt,0)) AS ReceivedAmt,
					SUM(ISNULL(BilledTax, 0)) AS BilledTax
			 FROM	dbo.brvJCContStat
			 WHERE	JCCo <= 100
			 GROUP BY JCCo, Contract) s 
			JOIN dbo.JCCM jccm ON s.JCCo=jccm.JCCo AND s.Contract=jccm.Contract
			JOIN dbo.JCDM jcdm ON jccm.JCCo=jcdm.JCCo AND jccm.Department=jcdm.Department
			JOIN dbo.GLPI glpi ON jcdm.GLCo=glpi.GLCo AND glpi.PartNo=3 AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4)
			LEFT JOIN (SELECT JBCo, Contract, MAX(InvDate) AS LatestBilling FROM JBIN GROUP BY JBCo, Contract) b ON s.JCCo=b.JBCo AND s.Contract=b.Contract
			LEFT JOIN dbo.JCMP jcmp ON jccm.JCCo=jcmp.JCCo AND jccm.udPOC=jcmp.ProjectMgr
	WHERE	(@company IS NULL OR s.JCCo = @company)
		AND (@poc IS NULL OR jccm.udPOC = @poc)
		AND (@dept IS NULL OR glpi.Instance = @dept)
		AND (@status IS NULL OR jccm.ContractStatus = @status)
		AND (jccm.ProjCloseDate IS NULL OR jccm.ProjCloseDate BETWEEN @closefrom AND @closeto)
	ORDER BY 1, 2
END
GO

GRANT EXECUTE
    ON OBJECT::[mers].[mckrptContractCloseAR] TO [MCKINSTRY\ViewpointUsers];
GO

--Test script
--EXEC mers.mckrptContractCloseAR
--EXEC mers.mckrptContractCloseAR 1, '0000'
--EXEC mers.mckrptContractCloseAR 1, '0000', null, 2
--EXEC mers.mckrptContractCloseAR 1, null, 56028
--EXEC mers.mckrptContractCloseAR 1, null, null, 1, '1/1/2015', '3/31/2015'
--EXEC mers.mckrptContractCloseAR 1, '9999'