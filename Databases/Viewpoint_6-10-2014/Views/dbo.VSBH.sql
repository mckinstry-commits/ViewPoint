SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[VSBH] as select a.* From bVSBH a

GO
GRANT SELECT ON  [dbo].[VSBH] TO [public]
GRANT INSERT ON  [dbo].[VSBH] TO [public]
GRANT DELETE ON  [dbo].[VSBH] TO [public]
GRANT UPDATE ON  [dbo].[VSBH] TO [public]
GRANT SELECT ON  [dbo].[VSBH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VSBH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VSBH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VSBH] TO [Viewpoint]
GO
