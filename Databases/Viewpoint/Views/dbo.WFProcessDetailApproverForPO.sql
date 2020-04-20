SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









/*****************************************
 * Created By:	GF 04/21/2012 TK-14088 B-08882
 * Modfied By:	
 *
 *
 * Provides a view of PO Pending PO Item Work Flow Reviewers
 *
 *****************************************/

CREATE view [dbo].[WFProcessDetailApproverForPO] as 
SELECT a.*
		,b.Step		AS [ApproverStep]
		,c.POCo		AS [POCo]
		,c.PO		AS [PO]
		,c.POItem	AS [POItem]
FROM [dbo].[WFProcessDetailApprover] a
INNER JOIN [dbo].[WFProcessDetailStep] b ON b.KeyID = a.DetailStepID
INNER JOIN [dbo].[WFProcessDetailForPO] c ON c.KeyID = b.ProcessDetailID













GO
GRANT SELECT ON  [dbo].[WFProcessDetailApproverForPO] TO [public]
GRANT INSERT ON  [dbo].[WFProcessDetailApproverForPO] TO [public]
GRANT DELETE ON  [dbo].[WFProcessDetailApproverForPO] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessDetailApproverForPO] TO [public]
GO