SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvPMPunchListPrintOption
AS
SELECT     'D' AS PrintOption, 'Due Date' AS 'Description'
UNION
SELECT     'F' AS PrintOption, 'Responsible Firm' AS 'Description'
UNION
SELECT     'L' AS PrintOption, 'Location' AS 'Description'


GO
GRANT SELECT ON  [dbo].[pvPMPunchListPrintOption] TO [public]
GRANT INSERT ON  [dbo].[pvPMPunchListPrintOption] TO [public]
GRANT DELETE ON  [dbo].[pvPMPunchListPrintOption] TO [public]
GRANT UPDATE ON  [dbo].[pvPMPunchListPrintOption] TO [public]
GRANT SELECT ON  [dbo].[pvPMPunchListPrintOption] TO [VCSPortal]
GO
