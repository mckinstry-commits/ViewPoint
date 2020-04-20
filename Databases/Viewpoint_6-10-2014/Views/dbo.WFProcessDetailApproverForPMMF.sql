SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








/*****************************************
 * Created By:	GF 04/21/2012 TK-14088 B-08882
 * Modfied By:	
 *
 *
 * Provides a view of PM PO Item Work Flow Reviewers
 *
 *****************************************/

CREATE view [dbo].[WFProcessDetailApproverForPMMF] as 
SELECT a.*
		,b.Step		AS [ApproverStep]
		,c.PMCo		AS [PMCo]
		,c.POCo		AS [POCo]
		,c.PO		AS [PO]
		,c.POItem	AS [POItem]
FROM [dbo].[WFProcessDetailApprover] a
INNER JOIN [dbo].[WFProcessDetailStep] b ON b.KeyID = a.DetailStepID
INNER JOIN [dbo].[WFProcessDetailForPMMF] c ON c.KeyID = b.ProcessDetailID












GO
GRANT SELECT ON  [dbo].[WFProcessDetailApproverForPMMF] TO [public]
GRANT INSERT ON  [dbo].[WFProcessDetailApproverForPMMF] TO [public]
GRANT DELETE ON  [dbo].[WFProcessDetailApproverForPMMF] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessDetailApproverForPMMF] TO [public]
GRANT SELECT ON  [dbo].[WFProcessDetailApproverForPMMF] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WFProcessDetailApproverForPMMF] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WFProcessDetailApproverForPMMF] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WFProcessDetailApproverForPMMF] TO [Viewpoint]
GO
