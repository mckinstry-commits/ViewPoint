SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW dbo.DDCB
AS SELECT  * FROM  dbo.vDDCB





GO
GRANT SELECT ON  [dbo].[DDCB] TO [public]
GRANT INSERT ON  [dbo].[DDCB] TO [public]
GRANT DELETE ON  [dbo].[DDCB] TO [public]
GRANT UPDATE ON  [dbo].[DDCB] TO [public]
GRANT SELECT ON  [dbo].[DDCB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDCB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDCB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDCB] TO [Viewpoint]
GO
