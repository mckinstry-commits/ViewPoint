SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSZD] as select a.* From bMSZD a
GO
GRANT SELECT ON  [dbo].[MSZD] TO [public]
GRANT INSERT ON  [dbo].[MSZD] TO [public]
GRANT DELETE ON  [dbo].[MSZD] TO [public]
GRANT UPDATE ON  [dbo].[MSZD] TO [public]
GO
