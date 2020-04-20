SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[HQBASReasonCodes]
AS
SELECT     dbo.vHQBASReasonCodes.*
FROM         dbo.vHQBASReasonCodes




GO
GRANT SELECT ON  [dbo].[HQBASReasonCodes] TO [public]
GRANT INSERT ON  [dbo].[HQBASReasonCodes] TO [public]
GRANT DELETE ON  [dbo].[HQBASReasonCodes] TO [public]
GRANT UPDATE ON  [dbo].[HQBASReasonCodes] TO [public]
GO
