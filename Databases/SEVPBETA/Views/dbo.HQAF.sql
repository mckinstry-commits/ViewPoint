SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQAF] as select a.* From bHQAF a

GO
GRANT SELECT ON  [dbo].[HQAF] TO [public]
GRANT INSERT ON  [dbo].[HQAF] TO [public]
GRANT DELETE ON  [dbo].[HQAF] TO [public]
GRANT UPDATE ON  [dbo].[HQAF] TO [public]
GO
