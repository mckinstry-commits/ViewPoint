SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMType] 
AS
SELECT *
FROM dbo.vSMType

GO
GRANT SELECT ON  [dbo].[SMType] TO [public]
GRANT INSERT ON  [dbo].[SMType] TO [public]
GRANT DELETE ON  [dbo].[SMType] TO [public]
GRANT UPDATE ON  [dbo].[SMType] TO [public]
GO
