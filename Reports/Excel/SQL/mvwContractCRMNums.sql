IF OBJECT_ID ('dbo.mvwContractCRMNums', 'view') IS NOT NULL
	DROP VIEW dbo.mvwContractCRMNums;
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 04/23/2015 Amit Mody			Authored
** 
******************************************************************************/

CREATE VIEW dbo.mvwContractCRMNums
AS
  WITH ContractCRMNums (Contract, CRMNum)
      AS
      (
		SELECT	DISTINCT jcci.Contract AS Contract, jcjm.udCRMNum AS CRMNum
		FROM	dbo.JCJM jcjm
				INNER JOIN dbo.JCJP jcjp ON jcjp.JCCo=jcjm.JCCo AND jcjp.Job=jcjm.Job 
				INNER JOIN dbo.JCCI jcci ON jcci.JCCo=jcjp.JCCo and jcci.Contract=jcjp.Contract and jcci.Item=jcjp.Item 
		WHERE	jcjm.udCRMNum IS NOT NULL
	  )
	  SELECT LTRIM(RTRIM(Contract)) AS [Contract]
		   , Left([CRM#],Len([CRM#])-1) AS [CRMNums]
		FROM (SELECT p1.Contract,
				(SELECT CRMNum + ', '
					FROM ContractCRMNums p2
					WHERE p2.Contract = p1.Contract
					ORDER BY CRMNum
					FOR XML PATH('')
				) AS [CRM#]
			 FROM ContractCRMNums p1
			 GROUP BY p1.Contract) c
GO

-- Test Script
-- SELECT * FROM dbo.mvwContractCRMNums