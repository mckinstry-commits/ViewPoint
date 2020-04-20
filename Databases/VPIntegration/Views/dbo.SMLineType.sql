SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[SMLineType]
AS
SELECT *
FROM dbo.vSMLineType



GO
GRANT SELECT ON  [dbo].[SMLineType] TO [public]
GRANT INSERT ON  [dbo].[SMLineType] TO [public]
GRANT DELETE ON  [dbo].[SMLineType] TO [public]
GRANT UPDATE ON  [dbo].[SMLineType] TO [public]
GO
