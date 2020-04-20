SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PCPotentialProjectTeam] as select a.* From vPCPotentialProjectTeam a
GO
GRANT SELECT ON  [dbo].[PCPotentialProjectTeam] TO [public]
GRANT INSERT ON  [dbo].[PCPotentialProjectTeam] TO [public]
GRANT DELETE ON  [dbo].[PCPotentialProjectTeam] TO [public]
GRANT UPDATE ON  [dbo].[PCPotentialProjectTeam] TO [public]
GO
