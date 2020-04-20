SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMED] as select a.* From bPMED a

GO
GRANT SELECT ON  [dbo].[PMED] TO [public]
GRANT INSERT ON  [dbo].[PMED] TO [public]
GRANT DELETE ON  [dbo].[PMED] TO [public]
GRANT UPDATE ON  [dbo].[PMED] TO [public]
GRANT SELECT ON  [dbo].[PMED] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMED] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMED] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMED] TO [Viewpoint]
GO
