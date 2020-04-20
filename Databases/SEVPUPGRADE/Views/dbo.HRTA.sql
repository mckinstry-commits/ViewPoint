SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRTA] as select a.* From bHRTA a

GO
GRANT SELECT ON  [dbo].[HRTA] TO [public]
GRANT INSERT ON  [dbo].[HRTA] TO [public]
GRANT DELETE ON  [dbo].[HRTA] TO [public]
GRANT UPDATE ON  [dbo].[HRTA] TO [public]
GO
