SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[SMLaborCode]
AS
SELECT a.* FROM dbo.vSMLaborCode a


GO
GRANT SELECT ON  [dbo].[SMLaborCode] TO [public]
GRANT INSERT ON  [dbo].[SMLaborCode] TO [public]
GRANT DELETE ON  [dbo].[SMLaborCode] TO [public]
GRANT UPDATE ON  [dbo].[SMLaborCode] TO [public]
GO
