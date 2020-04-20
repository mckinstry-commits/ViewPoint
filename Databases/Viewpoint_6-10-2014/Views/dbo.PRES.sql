SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRES] as select a.* From bPRES a

GO
GRANT SELECT ON  [dbo].[PRES] TO [public]
GRANT INSERT ON  [dbo].[PRES] TO [public]
GRANT DELETE ON  [dbo].[PRES] TO [public]
GRANT UPDATE ON  [dbo].[PRES] TO [public]
GRANT SELECT ON  [dbo].[PRES] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRES] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRES] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRES] TO [Viewpoint]
GO
