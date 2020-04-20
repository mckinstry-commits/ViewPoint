SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PMJCProjects]

as
select a.* from dbo.JCJM a where JobStatus in (0,1)

GO
GRANT SELECT ON  [dbo].[PMJCProjects] TO [public]
GRANT INSERT ON  [dbo].[PMJCProjects] TO [public]
GRANT DELETE ON  [dbo].[PMJCProjects] TO [public]
GRANT UPDATE ON  [dbo].[PMJCProjects] TO [public]
GO
