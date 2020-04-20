SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMAT] as select a.* From bEMAT a
GO
GRANT SELECT ON  [dbo].[EMAT] TO [public]
GRANT INSERT ON  [dbo].[EMAT] TO [public]
GRANT DELETE ON  [dbo].[EMAT] TO [public]
GRANT UPDATE ON  [dbo].[EMAT] TO [public]
GRANT SELECT ON  [dbo].[EMAT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMAT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMAT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMAT] TO [Viewpoint]
GO
