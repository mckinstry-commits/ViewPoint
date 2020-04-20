SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INPG] as select a.* From bINPG a
GO
GRANT SELECT ON  [dbo].[INPG] TO [public]
GRANT INSERT ON  [dbo].[INPG] TO [public]
GRANT DELETE ON  [dbo].[INPG] TO [public]
GRANT UPDATE ON  [dbo].[INPG] TO [public]
GRANT SELECT ON  [dbo].[INPG] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INPG] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INPG] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INPG] TO [Viewpoint]
GO
