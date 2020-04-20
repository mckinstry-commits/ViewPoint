SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSIG] as select a.* From bMSIG a

GO
GRANT SELECT ON  [dbo].[MSIG] TO [public]
GRANT INSERT ON  [dbo].[MSIG] TO [public]
GRANT DELETE ON  [dbo].[MSIG] TO [public]
GRANT UPDATE ON  [dbo].[MSIG] TO [public]
GO
