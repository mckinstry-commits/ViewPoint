SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSIX] as select a.* From bMSIX a
GO
GRANT SELECT ON  [dbo].[MSIX] TO [public]
GRANT INSERT ON  [dbo].[MSIX] TO [public]
GRANT DELETE ON  [dbo].[MSIX] TO [public]
GRANT UPDATE ON  [dbo].[MSIX] TO [public]
GRANT SELECT ON  [dbo].[MSIX] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSIX] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSIX] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSIX] TO [Viewpoint]
GO
