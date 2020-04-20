SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APUR] as select a.* From bAPUR a
GO
GRANT SELECT ON  [dbo].[APUR] TO [public]
GRANT INSERT ON  [dbo].[APUR] TO [public]
GRANT DELETE ON  [dbo].[APUR] TO [public]
GRANT UPDATE ON  [dbo].[APUR] TO [public]
GRANT SELECT ON  [dbo].[APUR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APUR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APUR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APUR] TO [Viewpoint]
GO
