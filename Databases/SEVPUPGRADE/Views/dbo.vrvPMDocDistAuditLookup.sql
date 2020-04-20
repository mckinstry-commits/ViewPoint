SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[vrvPMDocDistAuditLookup] as
/**********************************************
This view is used to the DocTypeforReports Lookup 
which is being used in the PM Distribution Audit Report


***********************************************/

select distinct(Sort), DocTypeDesc from vrvPMDocDistAudit
Group by Sort, DocTypeDesc
GO
GRANT SELECT ON  [dbo].[vrvPMDocDistAuditLookup] TO [public]
GRANT INSERT ON  [dbo].[vrvPMDocDistAuditLookup] TO [public]
GRANT DELETE ON  [dbo].[vrvPMDocDistAuditLookup] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMDocDistAuditLookup] TO [public]
GO
