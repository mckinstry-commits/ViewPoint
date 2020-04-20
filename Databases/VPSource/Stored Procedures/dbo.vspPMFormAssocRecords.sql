SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************/
CREATE procedure [dbo].[vspPMFormAssocRecords]
/************************************************************************
* CREATED By:	GF 11/15/2010
* MODIFIED By:	
*
* Returns a result set of associated records for the form and KeyID.
*
* Inputs
* @FormName		Form Name from DDFH
* @FormKeyID	Current Record KeyID
*
* Outputs
* @rcode	- 0 = successfull - 1 = error
* @msg		- Error Message
*
*************************************************************************/
(@FormName NVARCHAR(128) = NULL, @FormKeyID BIGINT = NULL, @msg varchar(255) output)
	
AS
SET NOCOUNT ON

DECLARE @rcode INT, @SQL NVARCHAR(2000)

SET @rcode = 0

---- check for needed values
IF @FormKeyID IS NULL GOTO vspExit
IF ISNULL(@FormName,'') = '' GOTO vspExit

---- create temp table
IF OBJECT_ID('tempdb..#FormAssocInfo') IS NOT NULL
	BEGIN
	DROP TABLE #FormAssocInfo
	END
	
---- verify ##SearchResults temp table exists
If Object_Id('tempdb..#FormAssocInfo') IS NULL
	BEGIN
	CREATE TABLE #FormAssocInfo
(
	FormKeyID		BIGINT			NOT NULL,
	FormName		NVARCHAR(30)	NOT NULL,
	JunctionTable	NVARCHAR(128)	NOT NULL,
	BaseTable		NVARCHAR(128)	NOT NULL,
	JunctionKeyID	NVARCHAR(128)	NULL
)
	END


---- insert into table using DDFormAssoc tables
--SET @SQL = 'INSERT INTO #FormAssocInfo (FormKeyID, FormName, JunctionTable, BaseTable, JunctionKeyID)'
--		+  ' SELECT ' + CONVERT(NVARCHAR, @FormKeyID) + ', f.Form, f.JunctionTable, f.BaseTable, NULL'
--		+  ' FROM dbo.vDDFormAssocRecord f'
--		+  ' INNER JOIN f.JunctionTable j ON j.RFIID = ' + CONVERT(NVARCHAR,@FormKeyID)
--		+  ' WHERE f.Form= ' + CHAR(39) + @FormName + CHAR(39) + ' AND f.Active= ' + CHAR(39) + 'Y' + CHAR(39)

--EXEC (@SQL)

INSERT INTO #FormAssocInfo (FormKeyID, FormName, JunctionTable, BaseTable, JunctionKeyID)
SELECT @FormKeyID, f.Form, f.JunctionTable, f.BaseTable, NULL
FROM dbo.vDDFormAssocRecord f
WHERE f.Form=@FormName AND f.Active = 'Y'

---- load junction table key id and column values if there are any

SELECT * FROM #FormAssocInfo



vspExit:
     RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMFormAssocRecords] TO [public]
GO
