SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMPI] as select a.* From bPMPI a
GO
GRANT SELECT ON  [dbo].[PMPI] TO [public]
GRANT INSERT ON  [dbo].[PMPI] TO [public]
GRANT DELETE ON  [dbo].[PMPI] TO [public]
GRANT UPDATE ON  [dbo].[PMPI] TO [public]
GRANT SELECT ON  [dbo].[PMPI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMPI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMPI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMPI] TO [Viewpoint]
GO
