SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSIN] as select a.* From bMSIN a

GO
GRANT SELECT ON  [dbo].[MSIN] TO [public]
GRANT INSERT ON  [dbo].[MSIN] TO [public]
GRANT DELETE ON  [dbo].[MSIN] TO [public]
GRANT UPDATE ON  [dbo].[MSIN] TO [public]
GO
