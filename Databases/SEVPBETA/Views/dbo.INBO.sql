SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INBO] as select a.* From bINBO a

GO
GRANT SELECT ON  [dbo].[INBO] TO [public]
GRANT INSERT ON  [dbo].[INBO] TO [public]
GRANT DELETE ON  [dbo].[INBO] TO [public]
GRANT UPDATE ON  [dbo].[INBO] TO [public]
GO
