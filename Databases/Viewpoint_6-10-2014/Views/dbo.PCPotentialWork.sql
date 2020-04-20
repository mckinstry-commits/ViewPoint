SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PCPotentialWork] as select a.* From vPCPotentialWork a
GO
GRANT SELECT ON  [dbo].[PCPotentialWork] TO [public]
GRANT INSERT ON  [dbo].[PCPotentialWork] TO [public]
GRANT DELETE ON  [dbo].[PCPotentialWork] TO [public]
GRANT UPDATE ON  [dbo].[PCPotentialWork] TO [public]
GRANT SELECT ON  [dbo].[PCPotentialWork] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCPotentialWork] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCPotentialWork] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCPotentialWork] TO [Viewpoint]
GO
