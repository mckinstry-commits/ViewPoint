SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRGI] as select a.* From bHRGI a

GO
GRANT SELECT ON  [dbo].[HRGI] TO [public]
GRANT INSERT ON  [dbo].[HRGI] TO [public]
GRANT DELETE ON  [dbo].[HRGI] TO [public]
GRANT UPDATE ON  [dbo].[HRGI] TO [public]
GO
