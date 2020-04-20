SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSAP] as select a.* From bMSAP a

GO
GRANT SELECT ON  [dbo].[MSAP] TO [public]
GRANT INSERT ON  [dbo].[MSAP] TO [public]
GRANT DELETE ON  [dbo].[MSAP] TO [public]
GRANT UPDATE ON  [dbo].[MSAP] TO [public]
GO
