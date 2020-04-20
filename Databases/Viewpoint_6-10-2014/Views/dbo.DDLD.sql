SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[DDLD] as select * from vDDLD

GO
GRANT SELECT ON  [dbo].[DDLD] TO [public]
GRANT INSERT ON  [dbo].[DDLD] TO [public]
GRANT DELETE ON  [dbo].[DDLD] TO [public]
GRANT UPDATE ON  [dbo].[DDLD] TO [public]
GRANT SELECT ON  [dbo].[DDLD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDLD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDLD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDLD] TO [Viewpoint]
GO
