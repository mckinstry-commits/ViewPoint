SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[UDTM] as select a.* From bUDTM a

GO
GRANT SELECT ON  [dbo].[UDTM] TO [public]
GRANT INSERT ON  [dbo].[UDTM] TO [public]
GRANT DELETE ON  [dbo].[UDTM] TO [public]
GRANT UPDATE ON  [dbo].[UDTM] TO [public]
GO
