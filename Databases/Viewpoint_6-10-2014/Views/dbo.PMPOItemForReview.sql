SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










/*****************************************
* Created By:	GF 05/09/2012 TK-14875 PM PO Item Reviewers
* Modfied By: GF 05/09/2012 TK-14875
*
* Provides a view of PM Material Detail used
* in PM PO Item Reviewers
*
*****************************************/
   
CREATE view [dbo].[PMPOItemForReview] as 
select b.POCo, b.PO, b.POItem, MIN(b.MtlDescription) AS [Description]
from dbo.PMMF b
WHERE b.POCo IS NOT NULL
	AND b.PO IS NOT NULL
	AND b.POItem IS NOT NULL
	AND b.POCONum IS NULL
	AND b.InterfaceDate IS NULL
Group by b.POCo, b.PO, b.POItem










GO
GRANT SELECT ON  [dbo].[PMPOItemForReview] TO [public]
GRANT INSERT ON  [dbo].[PMPOItemForReview] TO [public]
GRANT DELETE ON  [dbo].[PMPOItemForReview] TO [public]
GRANT UPDATE ON  [dbo].[PMPOItemForReview] TO [public]
GRANT SELECT ON  [dbo].[PMPOItemForReview] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMPOItemForReview] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMPOItemForReview] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMPOItemForReview] TO [Viewpoint]
GO
