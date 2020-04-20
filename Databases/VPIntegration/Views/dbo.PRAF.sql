SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRAF] as select a.* From bPRAF a

GO
GRANT SELECT ON  [dbo].[PRAF] TO [public]
GRANT INSERT ON  [dbo].[PRAF] TO [public]
GRANT DELETE ON  [dbo].[PRAF] TO [public]
GRANT UPDATE ON  [dbo].[PRAF] TO [public]
GO
