SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[vrvPMOH] as 
select a.*, (select IssueNumbers From vf_rptPMRelatedDocs('bPMOH', 'bPMIM', a.KeyID)) as [RelatedIssueNumbers]	  
From bPMOH a

GO
GRANT SELECT ON  [dbo].[vrvPMOH] TO [public]
GRANT INSERT ON  [dbo].[vrvPMOH] TO [public]
GRANT DELETE ON  [dbo].[vrvPMOH] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMOH] TO [public]
GRANT SELECT ON  [dbo].[vrvPMOH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMOH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMOH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMOH] TO [Viewpoint]
GO
