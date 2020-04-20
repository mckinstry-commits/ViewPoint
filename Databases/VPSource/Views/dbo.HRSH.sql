SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRSH] as select a.* From bHRSH a

GO
GRANT SELECT ON  [dbo].[HRSH] TO [public]
GRANT INSERT ON  [dbo].[HRSH] TO [public]
GRANT DELETE ON  [dbo].[HRSH] TO [public]
GRANT UPDATE ON  [dbo].[HRSH] TO [public]
GO
