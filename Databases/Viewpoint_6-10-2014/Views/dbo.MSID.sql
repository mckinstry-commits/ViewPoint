SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSID] as select a.* From bMSID a
GO
GRANT SELECT ON  [dbo].[MSID] TO [public]
GRANT INSERT ON  [dbo].[MSID] TO [public]
GRANT DELETE ON  [dbo].[MSID] TO [public]
GRANT UPDATE ON  [dbo].[MSID] TO [public]
GRANT SELECT ON  [dbo].[MSID] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSID] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSID] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSID] TO [Viewpoint]
GO
