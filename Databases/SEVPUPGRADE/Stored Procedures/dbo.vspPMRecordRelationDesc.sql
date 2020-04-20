SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspPMRecordRelationDesc]
/************************************************************************
* CREATED By:	GF 12/10/2010
* MODIFIED: 
*
* Purpose of Stored Procedure is to return the from form record description
* to display in the record association form. Called as a validation procedure
* in DDFI for PM Record Association.
*
*    
* 
* Inputs
* @PMCo				- PM Company
* @FromFormName		- From Form Name (DD form name)
* @FromFormKeyID	- From Form Key ID (used to find record in table)
*
* Outputs
* @rcode		- 0 = successfull - 1 = error
* @errmsg		- Error Message
*
*************************************************************************/
(@PMCo bCompany = NULL, @FromFormName NVARCHAR(128) = NULL, @FromFormKeyID BIGINT = NULL,
 @msg varchar(255) = '' output)
 
--with execute as 'viewpointcs'
	
AS
SET NOCOUNT ON

DECLARE @rcode	int, @SQL NVARCHAR(2000), @FromFormTable NVARCHAR(128),
		@DescColumn1 NVARCHAR(128), @ParamDef nvarchar(500), @Description NVARCHAR(100)

------------------
-- PRIME VALUES --
------------------
SET @rcode = 0	

-------------------------------
-- CHECK INCOMING PARAMETERS --	
-------------------------------
IF @PMCo IS NULL
	BEGIN
		SET @msg = 'Missing Company!'
		SET @rcode = 1
		GOTO vspExit
	END

IF @FromFormName IS NULL
	BEGIN
		SET @msg = 'Missing Form Form Name!'
		SET @rcode = 1
		GOTO vspExit
	END
	
IF @FromFormKeyID IS NULL
	BEGIN
		SET @msg = 'Missing Form Form Key ID!'
		SET @rcode = 1
		GOTO vspExit
	END


---- execute SP to get the from form table
EXEC @rcode = dbo.vspPMRecordRelationGetFormTable @FromFormName, @FromFormTable output, @msg output

---- must have a form name
IF @FromFormTable IS NULL
	BEGIN
	SELECT @msg = 'Missing From Form Table for related records!', @rcode = 1
	GOTO vspExit
	END


---- get the description column from DDFormRelatedInfo
SELECT @DescColumn1 = i.DescColumn1
FROM dbo.vDDFormRelatedInfo i
WHERE i.Form = @FromFormName
---- if no record found return without error
IF @@rowcount <> 1
	BEGIN
	SET @msg = ''
	GOTO vspExit
	END

---- if no description column then return without error
IF @DescColumn1 IS NULL
	BEGIN
	SET @msg = ''
	GOTO vspExit
	end



---- build query statement to search
SET @SQL = NULL
SET @ParamDef = N'@Description NVARCHAR(100) OUTPUT'
SET @SQL = N'SELECT @Description = CAST(r.' + @DescColumn1 + ' AS NVARCHAR(100)) '
---- from statement
SET @SQL = @SQL + 'FROM dbo.' + @FromFormTable + ' r WITH (NOLOCK) '
	
---- build where clause using from form key id
SET @SQL = @SQL + 'WHERE r.KeyID = '  + + CONVERT(VARCHAR(10),@FromFormKeyID)

---- execute query
EXECUTE sp_executesql @SQL, @ParamDef, @Description OUTPUT

---- set return value
SET @msg = ISNULL(@Description,'')






vspExit:
     RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[vspPMRecordRelationDesc] TO [public]
GO
