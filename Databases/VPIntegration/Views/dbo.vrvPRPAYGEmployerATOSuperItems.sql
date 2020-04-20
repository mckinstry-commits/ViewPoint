SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/**********************************************************
  Purpose:  

	Combine views PRAUEmployerATOItems and PRAUEmployerSuperItems
	into one view so all EDL types and codes can be processed as 
	one view.
			
  Maintenance Log:			Version
	Coder	Date	Issue#	One#	Description of Change
	CWirtz	4/15/11	142504	B-04283	New
********************************************************************/

CREATE  VIEW [dbo].[vrvPRPAYGEmployerATOSuperItems] AS

	SELECT	'ATO  ' AS RecID,PRCo,TaxYear,ItemCode, EDLType, EDLCode 
		FROM dbo.PRAUEmployerATOItems 
		
	UNION ALL
	SELECT	'Super' AS RecID,PRCo,TaxYear,ItemCode, DLType AS [EDLType], DLCode AS [EDLCode] 
		FROM dbo.PRAUEmployerSuperItems 




GO
GRANT SELECT ON  [dbo].[vrvPRPAYGEmployerATOSuperItems] TO [public]
GRANT INSERT ON  [dbo].[vrvPRPAYGEmployerATOSuperItems] TO [public]
GRANT DELETE ON  [dbo].[vrvPRPAYGEmployerATOSuperItems] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRPAYGEmployerATOSuperItems] TO [public]
GO
