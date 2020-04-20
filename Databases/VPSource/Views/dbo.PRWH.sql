SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PRWH] as
select a.* From bPRWH a


GO
GRANT SELECT ON  [dbo].[PRWH] TO [public]
GRANT INSERT ON  [dbo].[PRWH] TO [public]
GRANT DELETE ON  [dbo].[PRWH] TO [public]
GRANT UPDATE ON  [dbo].[PRWH] TO [public]
GO
