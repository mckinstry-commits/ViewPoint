SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PORJ] as select a.* From bPORJ a

GO
GRANT SELECT ON  [dbo].[PORJ] TO [public]
GRANT INSERT ON  [dbo].[PORJ] TO [public]
GRANT DELETE ON  [dbo].[PORJ] TO [public]
GRANT UPDATE ON  [dbo].[PORJ] TO [public]
GO
