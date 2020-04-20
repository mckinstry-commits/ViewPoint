SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARBJ] as select a.* From bARBJ a

GO
GRANT SELECT ON  [dbo].[ARBJ] TO [public]
GRANT INSERT ON  [dbo].[ARBJ] TO [public]
GRANT DELETE ON  [dbo].[ARBJ] TO [public]
GRANT UPDATE ON  [dbo].[ARBJ] TO [public]
GO
