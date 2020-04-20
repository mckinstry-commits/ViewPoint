SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[vspPMListViewSetupVal]

  /*************************************
  * CREATED BY:		GP 05/19/2009
  * Modified By:
  *
  *		Validates table name for PM ListView Setup.
  *
  *		Input Parameters:
  *			Table Name
  *  
  *		Output Parameters:
  *			rcode - 0 Success
  *					1 Failure
  *			msg - Return Message
  *		
  **************************************/
	(@TableName varchar(50) = null, @ColumnName varchar(50) = null, @msg varchar(256) output)
	as
	SET nocount on

	DECLARE @rcode int
	SET @rcode = 0

	IF @TableName is null
	BEGIN
		SELECT @msg = 'Missing table name.', @rcode = 1
		GOTO vspexit
	END

	--Make sure table is allowed
	IF @TableName not in ('PMFM','PMPF','PMPM')
	BEGIN
		SELECT @msg = 'Table name must be PMFM, PMPF, or PMPM.', @rcode = 1
		GOTO vspexit
	END
	
	--Make sure column exists in table
	IF @TableName is not null and @ColumnName is not null
	BEGIN
		SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS with (nolock) WHERE TABLE_NAME = @TableName
			and COLUMN_NAME = @ColumnName
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @msg = 'Column does not exist in specified table.', @rcode = 1
			GOTO vspexit
		END	
	END
	
	vspexit:
   	RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMListViewSetupVal] TO [public]
GO
