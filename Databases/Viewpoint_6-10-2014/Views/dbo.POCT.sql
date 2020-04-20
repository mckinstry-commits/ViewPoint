SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POCT] as select a.* From bPOCT a
GO
GRANT SELECT ON  [dbo].[POCT] TO [public]
GRANT INSERT ON  [dbo].[POCT] TO [public]
GRANT DELETE ON  [dbo].[POCT] TO [public]
GRANT UPDATE ON  [dbo].[POCT] TO [public]
GRANT SELECT ON  [dbo].[POCT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[POCT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[POCT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[POCT] TO [Viewpoint]
GO
