SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMIssueHistory] as select a.* From vPMIssueHistory a
GO
GRANT SELECT ON  [dbo].[PMIssueHistory] TO [public]
GRANT INSERT ON  [dbo].[PMIssueHistory] TO [public]
GRANT DELETE ON  [dbo].[PMIssueHistory] TO [public]
GRANT UPDATE ON  [dbo].[PMIssueHistory] TO [public]
GO
