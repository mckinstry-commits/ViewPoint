SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udIssueWkType] as select a.* From budIssueWkType a
GO
GRANT SELECT ON  [dbo].[udIssueWkType] TO [public]
GRANT INSERT ON  [dbo].[udIssueWkType] TO [public]
GRANT DELETE ON  [dbo].[udIssueWkType] TO [public]
GRANT UPDATE ON  [dbo].[udIssueWkType] TO [public]
GO
