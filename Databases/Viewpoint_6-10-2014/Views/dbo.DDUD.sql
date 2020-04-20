SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      view [dbo].[DDUD] as select a.* From bDDUD a

GO
GRANT SELECT ON  [dbo].[DDUD] TO [public]
GRANT INSERT ON  [dbo].[DDUD] TO [public]
GRANT DELETE ON  [dbo].[DDUD] TO [public]
GRANT UPDATE ON  [dbo].[DDUD] TO [public]
GRANT SELECT ON  [dbo].[DDUD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDUD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDUD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDUD] TO [Viewpoint]
GO
