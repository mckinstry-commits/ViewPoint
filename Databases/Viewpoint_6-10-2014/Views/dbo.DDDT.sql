SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[DDDT] as select * from vDDDT

GO
GRANT SELECT ON  [dbo].[DDDT] TO [public]
GRANT INSERT ON  [dbo].[DDDT] TO [public]
GRANT DELETE ON  [dbo].[DDDT] TO [public]
GRANT UPDATE ON  [dbo].[DDDT] TO [public]
GRANT SELECT ON  [dbo].[DDDT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDDT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDDT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDDT] TO [Viewpoint]
GO
