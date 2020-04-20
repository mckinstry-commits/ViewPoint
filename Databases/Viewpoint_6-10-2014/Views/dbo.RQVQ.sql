SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RQVQ] as select a.* From bRQVQ a
GO
GRANT SELECT ON  [dbo].[RQVQ] TO [public]
GRANT INSERT ON  [dbo].[RQVQ] TO [public]
GRANT DELETE ON  [dbo].[RQVQ] TO [public]
GRANT UPDATE ON  [dbo].[RQVQ] TO [public]
GRANT SELECT ON  [dbo].[RQVQ] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RQVQ] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RQVQ] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RQVQ] TO [Viewpoint]
GO
