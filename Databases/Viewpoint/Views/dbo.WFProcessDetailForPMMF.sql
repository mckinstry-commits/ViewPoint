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

CREATE view [dbo].[WFProcessDetailForPMMF] as 
SELECT a.*
		,b.PMCo		AS [PMCo]
		,b.POCo		AS [POCo]
		,b.PO		AS [PO]
		,b.POItem	AS [POItem]
FROM [dbo].[WFProcessDetail] a
INNER JOIN [dbo].[PMMF] b ON b.KeyID = a.SourceKeyID
WHERE a.SourceView = 'PMMF'









GO
GRANT SELECT ON  [dbo].[WFProcessDetailForPMMF] TO [public]
GRANT INSERT ON  [dbo].[WFProcessDetailForPMMF] TO [public]
GRANT DELETE ON  [dbo].[WFProcessDetailForPMMF] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessDetailForPMMF] TO [public]
GO
