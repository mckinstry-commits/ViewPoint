SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************************
* Created By:	NH 03/26/2012
* Modfied By:    
*
*
* Provides a view of JC Job Approval Process for PM
* returns alias columns form PMCo, Project
*
***************************************************/
CREATE VIEW [dbo].[PMProjectApprovalProcess]
AS

select a.*, a.JCCo as [PMCo], a.Job as [Project]
from dbo.vJCJobApprovalProcess a
GO
GRANT SELECT ON  [dbo].[PMProjectApprovalProcess] TO [public]
GRANT INSERT ON  [dbo].[PMProjectApprovalProcess] TO [public]
GRANT DELETE ON  [dbo].[PMProjectApprovalProcess] TO [public]
GRANT UPDATE ON  [dbo].[PMProjectApprovalProcess] TO [public]
GO
