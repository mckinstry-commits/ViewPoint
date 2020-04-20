SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[vrvPMIL] as 
select a.*, (select IssueNumbers From vf_rptPMRelatedDocs('bPMIL', 'bPMIM', a.KeyID)) as [RelatedIssueNumbers]	  
From bPMIL a

GO
GRANT SELECT ON  [dbo].[vrvPMIL] TO [public]
GRANT INSERT ON  [dbo].[vrvPMIL] TO [public]
GRANT DELETE ON  [dbo].[vrvPMIL] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMIL] TO [public]
GRANT SELECT ON  [dbo].[vrvPMIL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMIL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMIL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMIL] TO [Viewpoint]
GO
