SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POCO] as select a.* From bPOCO a
GO
GRANT SELECT ON  [dbo].[POCO] TO [public]
GRANT INSERT ON  [dbo].[POCO] TO [public]
GRANT DELETE ON  [dbo].[POCO] TO [public]
GRANT UPDATE ON  [dbo].[POCO] TO [public]
GRANT SELECT ON  [dbo].[POCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POCO] TO [Viewpoint]
GO
