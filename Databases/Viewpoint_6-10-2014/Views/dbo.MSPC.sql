SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSPC] as select a.* From bMSPC a
GO
GRANT SELECT ON  [dbo].[MSPC] TO [public]
GRANT INSERT ON  [dbo].[MSPC] TO [public]
GRANT DELETE ON  [dbo].[MSPC] TO [public]
GRANT UPDATE ON  [dbo].[MSPC] TO [public]
GRANT SELECT ON  [dbo].[MSPC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSPC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSPC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSPC] TO [Viewpoint]
GO
