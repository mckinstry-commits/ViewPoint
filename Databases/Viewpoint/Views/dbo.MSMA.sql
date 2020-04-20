SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSMA] as select a.* From bMSMA a

GO
GRANT SELECT ON  [dbo].[MSMA] TO [public]
GRANT INSERT ON  [dbo].[MSMA] TO [public]
GRANT DELETE ON  [dbo].[MSMA] TO [public]
GRANT UPDATE ON  [dbo].[MSMA] TO [public]
GO
