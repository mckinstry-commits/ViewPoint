SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[DDLH] as
  Select * from vDDLH

GO
GRANT SELECT ON  [dbo].[DDLH] TO [public]
GRANT INSERT ON  [dbo].[DDLH] TO [public]
GRANT DELETE ON  [dbo].[DDLH] TO [public]
GRANT UPDATE ON  [dbo].[DDLH] TO [public]
GRANT SELECT ON  [dbo].[DDLH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDLH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDLH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDLH] TO [Viewpoint]
GO
