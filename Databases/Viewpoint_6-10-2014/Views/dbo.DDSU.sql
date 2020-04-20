SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[DDSU] as select * from vDDSU

GO
GRANT SELECT ON  [dbo].[DDSU] TO [public]
GRANT INSERT ON  [dbo].[DDSU] TO [public]
GRANT DELETE ON  [dbo].[DDSU] TO [public]
GRANT UPDATE ON  [dbo].[DDSU] TO [public]
GRANT SELECT ON  [dbo].[DDSU] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDSU] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDSU] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDSU] TO [Viewpoint]
GO
