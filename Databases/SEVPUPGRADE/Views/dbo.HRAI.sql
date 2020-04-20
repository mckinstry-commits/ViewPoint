SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRAI] as select a.* From bHRAI a
GO
GRANT SELECT ON  [dbo].[HRAI] TO [public]
GRANT INSERT ON  [dbo].[HRAI] TO [public]
GRANT DELETE ON  [dbo].[HRAI] TO [public]
GRANT UPDATE ON  [dbo].[HRAI] TO [public]
GO
