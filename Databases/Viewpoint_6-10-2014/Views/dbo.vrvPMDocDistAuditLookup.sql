SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[vrvPMDocDistAuditLookup] as
/**********************************************
This view is used to the DocTypeforReports Lookup 
which is being used in the PM Distribution Audit Report

* Modified:
*	AJW TFS 70345 modified to not show null doctypes to reflect change in vrvPMDocDistAudit for work centers


***********************************************/

select distinct(Sort), DocTypeDesc from vrvPMDocDistAudit where DocTypeDesc is not null
Group by Sort, DocTypeDesc
GO
GRANT SELECT ON  [dbo].[vrvPMDocDistAuditLookup] TO [public]
GRANT INSERT ON  [dbo].[vrvPMDocDistAuditLookup] TO [public]
GRANT DELETE ON  [dbo].[vrvPMDocDistAuditLookup] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMDocDistAuditLookup] TO [public]
GO
