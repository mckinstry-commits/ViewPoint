USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mckfnMcKQuoteContacts' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
Begin
	Print 'DROP FUNCTION dbo.mckfnMcKQuoteContacts'
	DROP FUNCTION dbo.mckfnMcKQuoteContacts
End
GO

Print 'CREATE FUNCTION dbo.mckfnMcKQuoteContacts'
GO


CREATE FUNCTION [dbo].mckfnMcKQuoteContacts()
RETURNS TABLE
AS
 /* 
	Purpose:	Get McK SM Quotes contacts
	Author:		Leo Gurdian
	Created:	11.30.2018	
	HISTORY:

	11.30.18 LG - Get McK SM Quote contacts
*/
RETURN
(
	SELECT 
	  Alias	
	, FullName
	, CAST(Alias	+ '@McKinstry.com' AS VARCHAR(125))	AS Email
	, Phone
	FROM dbo.udxrefQuoteContacts
)

GO

Grant SELECT ON dbo.mckfnMcKQuoteContacts TO [MCKINSTRY\Viewpoint Users]


--SELECT Alias, FullName, Email, Phone FROM dbo.mckfnMcKQuoteContacts()