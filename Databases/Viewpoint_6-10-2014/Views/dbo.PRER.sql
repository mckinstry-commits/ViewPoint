SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRER] as select a.* From bPRER a
GO
GRANT SELECT ON  [dbo].[PRER] TO [public]
GRANT INSERT ON  [dbo].[PRER] TO [public]
GRANT DELETE ON  [dbo].[PRER] TO [public]
GRANT UPDATE ON  [dbo].[PRER] TO [public]
GRANT SELECT ON  [dbo].[PRER] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRER] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRER] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRER] TO [Viewpoint]
GO
