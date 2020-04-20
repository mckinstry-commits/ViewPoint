
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMLaborCode] as select a.* From vSMLaborCode a
GO

GRANT SELECT ON  [dbo].[SMLaborCode] TO [public]
GRANT INSERT ON  [dbo].[SMLaborCode] TO [public]
GRANT DELETE ON  [dbo].[SMLaborCode] TO [public]
GRANT UPDATE ON  [dbo].[SMLaborCode] TO [public]
GO
