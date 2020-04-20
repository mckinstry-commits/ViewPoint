SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*****************************
* Created By:	GF 11/09/2011 TK-00000
* Modified By:	
*
*
******************************/
 
CREATE VIEW [dbo].[pvPMCCMethod]
AS
SELECT     'N' AS CCMethod, 'None' AS 'Description'
UNION
SELECT     'C' AS CCMethod, 'Cc' AS 'Description'
UNION
SELECT     'B' AS CCMethod, 'Bcc' AS 'Description'





GO
GRANT SELECT ON  [dbo].[pvPMCCMethod] TO [public]
GRANT INSERT ON  [dbo].[pvPMCCMethod] TO [public]
GRANT DELETE ON  [dbo].[pvPMCCMethod] TO [public]
GRANT UPDATE ON  [dbo].[pvPMCCMethod] TO [public]
GRANT SELECT ON  [dbo].[pvPMCCMethod] TO [VCSPortal]
GO
