SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRHD] as select a.* From bPRHD a
GO
GRANT SELECT ON  [dbo].[PRHD] TO [public]
GRANT INSERT ON  [dbo].[PRHD] TO [public]
GRANT DELETE ON  [dbo].[PRHD] TO [public]
GRANT UPDATE ON  [dbo].[PRHD] TO [public]
GRANT SELECT ON  [dbo].[PRHD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRHD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRHD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRHD] TO [Viewpoint]
GO
