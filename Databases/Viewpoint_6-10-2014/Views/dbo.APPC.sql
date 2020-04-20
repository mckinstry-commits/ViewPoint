SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APPC] as select a.* From bAPPC a
GO
GRANT SELECT ON  [dbo].[APPC] TO [public]
GRANT INSERT ON  [dbo].[APPC] TO [public]
GRANT DELETE ON  [dbo].[APPC] TO [public]
GRANT UPDATE ON  [dbo].[APPC] TO [public]
GRANT SELECT ON  [dbo].[APPC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APPC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APPC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APPC] TO [Viewpoint]
GO
