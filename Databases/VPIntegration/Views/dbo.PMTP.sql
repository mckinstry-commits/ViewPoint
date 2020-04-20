SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMTP] as select a.* From bPMTP a

GO
GRANT SELECT ON  [dbo].[PMTP] TO [public]
GRANT INSERT ON  [dbo].[PMTP] TO [public]
GRANT DELETE ON  [dbo].[PMTP] TO [public]
GRANT UPDATE ON  [dbo].[PMTP] TO [public]
GO
