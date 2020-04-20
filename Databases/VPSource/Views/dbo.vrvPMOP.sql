SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[vrvPMOP] as
select a.*, (select IssueNumbers From vf_rptPMRelatedDocs('bPMOP', 'bPMIM', a.KeyID)) as [RelatedIssueNumbers]	  
From bPMOP a

GO
GRANT SELECT ON  [dbo].[vrvPMOP] TO [public]
GRANT INSERT ON  [dbo].[vrvPMOP] TO [public]
GRANT DELETE ON  [dbo].[vrvPMOP] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMOP] TO [public]
GO
