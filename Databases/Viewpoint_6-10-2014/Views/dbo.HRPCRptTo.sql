SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.HRPCRptTo
AS
SELECT     dbo.HRPC.*
FROM         dbo.HRPC


GO
GRANT SELECT ON  [dbo].[HRPCRptTo] TO [public]
GRANT INSERT ON  [dbo].[HRPCRptTo] TO [public]
GRANT DELETE ON  [dbo].[HRPCRptTo] TO [public]
GRANT UPDATE ON  [dbo].[HRPCRptTo] TO [public]
GRANT SELECT ON  [dbo].[HRPCRptTo] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRPCRptTo] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRPCRptTo] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRPCRptTo] TO [Viewpoint]
GO
