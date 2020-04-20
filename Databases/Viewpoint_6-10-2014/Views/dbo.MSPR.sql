SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSPR] as select a.* From bMSPR a
GO
GRANT SELECT ON  [dbo].[MSPR] TO [public]
GRANT INSERT ON  [dbo].[MSPR] TO [public]
GRANT DELETE ON  [dbo].[MSPR] TO [public]
GRANT UPDATE ON  [dbo].[MSPR] TO [public]
GRANT SELECT ON  [dbo].[MSPR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSPR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSPR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSPR] TO [Viewpoint]
GO
