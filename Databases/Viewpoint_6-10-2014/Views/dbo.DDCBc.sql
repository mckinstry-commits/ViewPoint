SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  VIEW dbo.DDCBc
AS SELECT  * FROM  dbo.vDDCBc






GO
GRANT SELECT ON  [dbo].[DDCBc] TO [public]
GRANT INSERT ON  [dbo].[DDCBc] TO [public]
GRANT DELETE ON  [dbo].[DDCBc] TO [public]
GRANT UPDATE ON  [dbo].[DDCBc] TO [public]
GRANT SELECT ON  [dbo].[DDCBc] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDCBc] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDCBc] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDCBc] TO [Viewpoint]
GO
