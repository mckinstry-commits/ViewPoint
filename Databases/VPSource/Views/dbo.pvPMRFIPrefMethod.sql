SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************
* Created By:	??
* Modified By:	GF 11/09/2011 TK-00000
*
*
******************************/
 
CREATE VIEW [dbo].[pvPMRFIPrefMethod]
AS
SELECT     'M' AS PrefMethod, 'Print' AS 'Description'
UNION
SELECT     'E' AS PrefMethod, 'Email' AS 'Description'
----TK-00000
----UNION
----SELECT     'T' AS PrefMethod, 'Email - Text Only' AS 'Description'
UNION
SELECT     'F' AS PrefMethod, 'Fax' AS 'Description'




GO
GRANT SELECT ON  [dbo].[pvPMRFIPrefMethod] TO [public]
GRANT INSERT ON  [dbo].[pvPMRFIPrefMethod] TO [public]
GRANT DELETE ON  [dbo].[pvPMRFIPrefMethod] TO [public]
GRANT UPDATE ON  [dbo].[pvPMRFIPrefMethod] TO [public]
GRANT SELECT ON  [dbo].[pvPMRFIPrefMethod] TO [VCSPortal]
GO
