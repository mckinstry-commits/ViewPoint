SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************/
CREATE procedure [dbo].[vspPMRecordRelationGetFormTable]
/************************************************************************
* Created By:	GF 11/30/2010 
* Modified By:	GF 04/05/2011 TK-03569 TK-04796
*				GF 06/21/2011 D-02339 use views not tables
*
* Return table name based on input string
*
* Inputs
*	@FormName	- Form Name
*
* Outputs
*	@rcode		- 0 = successfull - 1 = error
*	@msg		- Table name or error
*
*************************************************************************/
(@FormName NVARCHAR(128) = NULL, @TableName NVARCHAR(128) = NULL OUTPUT,
 @msg varchar(255) output)

--with execute as 'viewpointcs'

AS
SET NOCOUNT ON

DECLARE @rcode INT, @ViewName NVARCHAR(128), @ViewRefreshed tinyint

SET @rcode = 0
SET @ViewRefreshed = 0

-------------------------------
-- CHECK INCOMING PARAMETERS --
-------------------------------
IF @FormName IS NULL
	BEGIN
		SET @msg = 'Missing Form Name!'
		SET @rcode = 1
		GOTO vspExit
	END

---- when related form is APEntryDetail then the table will be bAPTL
IF @FormName = 'APEntryDetail'
	BEGIN
	SET @TableName = 'APTL'
	GOTO vspExit
	END

---- validate from form name to DDFH and get the view name
SELECT @ViewName = ViewName
FROM dbo.vDDFH WHERE Form = @FormName
IF @@rowcount = 0
	BEGIN
	SELECT @msg = 'From Form Name ' + ISNULL(@FormName,'') + ' is missing in DDFH!', @rcode = 1
	GOTO vspExit
	END





---- GET table from view using information_schema
SET @TableName = NULL
SELECT @TableName = v.VIEW_NAME ----v.TABLE_NAME
FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE v
WHERE v.VIEW_NAME = @ViewName
----AND (SUBSTRING(v.TABLE_NAME,1,1) = 'b' OR SUBSTRING(v.TABLE_NAME,1,1) = 'v')
AND (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE x
				WHERE x.VIEW_NAME = v.VIEW_NAME) = 1

------ 2nd try possible that the table name is another view
--IF @TableName IS NOT NULL AND SUBSTRING(@TableName,1,1) NOT IN ('b','v')
--	BEGIN
--	SET @ViewName=@TableName
--	SELECT @TableName = v.TABLE_NAME
--	FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE v
--	WHERE v.VIEW_NAME = @ViewName
--	----AND (SUBSTRING(v.TABLE_NAME,1,1) = 'b' OR SUBSTRING(v.TABLE_NAME,1,1) = 'v')
--	AND (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE x
--					WHERE x.VIEW_NAME = v.VIEW_NAME) = 1
--	END

------ 3rd try possible that the table name is another view
--IF @TableName IS NOT NULL AND SUBSTRING(@TableName,1,1) NOT IN ('b','v')
--	BEGIN
--	SET @ViewName=@TableName
--	SELECT @TableName = v.TABLE_NAME
--	FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE v
--	WHERE v.VIEW_NAME = @ViewName
--	AND (SUBSTRING(v.TABLE_NAME,1,1) = 'b' OR SUBSTRING(v.TABLE_NAME,1,1) = 'v')
--	AND (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE x
--					WHERE x.VIEW_NAME = v.VIEW_NAME) = 1
--	END
	
	
---- if we do not have a table name, possible that the view
---- needs to be refreshed. Refresh view, then loop back and
---- try to get table name one more time only.
--IF ISNULL(@TableName,'') = '' AND @ViewRefreshed = 0
--	BEGIN
--	EXEC sys.sp_refreshview @ViewName
--	SET @ViewRefreshed = 1
--	GOTO get_table_name
--	END

SET @TableName = @ViewName

	IF @FormName = 'PMSLHeader' SET @TableName = 'SLHD'
	IF @FormName = 'PMPOHeader' SET @TableName = 'POHD'
	IF @FormName = 'PMMOHeader' SET @TableName = 'INMO'
	IF @FormName = 'PMChangeOrderRequest' SET @TableName = 'PMChangeOrderRequest'
	IF @FormName = 'PMContractChangeOrder'	SET @TableName = 'PMContractChangeOrder'
	IF @FormName = 'PMSubcontractCO' SET @TableName = 'PMSubcontractCO'
	IF @FormName = 'PMPOCO' SET @TableName = 'PMPOCO'
	IF @FormName = 'APEntryDetail' SET @TableName = 'APTL'
	IF @FormName = 'PMContractItem' SET @TableName = 'JCCI'
	
---- conditional views - we can always manually set table name if we have too.
--IF ISNULL(@TableName,'') = ''
--	BEGIN
--	IF @FormName = 'PMSLHeader' SET @TableName = 'SLHD'
--	IF @FormName = 'PMPOHeader' SET @TableName = 'POHD'
--	IF @FormName = 'PMMOHeader' SET @TableName = 'INMO'
--	IF @FormName = 'PMChangeOrderRequest' SET @TableName = 'PMChangeOrderRequest'
--	IF @FormName = 'PMContractChangeOrder'	SET @TableName = 'PMContractChangeorder'
--	IF @FormName = 'PMSubcontractCO' SET @TableName = 'PMSubcontractCO'
--	IF @FormName = 'PMPOCO' SET @TableName = 'PMPOCO'
--	END

--IF SUBSTRING(@TableName,1,1) IN ('b','v')
--	BEGIN
--	SET @TableName = LEFT(@TableName,2)
--	END
	

vspExit:
     RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMRecordRelationGetFormTable] TO [public]
GO
