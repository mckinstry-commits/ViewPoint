SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRWT] as select a.* From bPRWT a

GO
GRANT SELECT ON  [dbo].[PRWT] TO [public]
GRANT INSERT ON  [dbo].[PRWT] TO [public]
GRANT DELETE ON  [dbo].[PRWT] TO [public]
GRANT UPDATE ON  [dbo].[PRWT] TO [public]
GO
