SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RQRH] as select a.* From bRQRH a

GO
GRANT SELECT ON  [dbo].[RQRH] TO [public]
GRANT INSERT ON  [dbo].[RQRH] TO [public]
GRANT DELETE ON  [dbo].[RQRH] TO [public]
GRANT UPDATE ON  [dbo].[RQRH] TO [public]
GO
