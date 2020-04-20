SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQRV] as select a.* From bHQRV a
GO
GRANT SELECT ON  [dbo].[HQRV] TO [public]
GRANT INSERT ON  [dbo].[HQRV] TO [public]
GRANT DELETE ON  [dbo].[HQRV] TO [public]
GRANT UPDATE ON  [dbo].[HQRV] TO [public]
GRANT SELECT ON  [dbo].[HQRV] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQRV] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQRV] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQRV] TO [Viewpoint]
GO
