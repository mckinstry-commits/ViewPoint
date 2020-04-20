SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE  procedure [dbo].[vspVAGridQueryTypeVal]
/******************************************************
* CREATED BY:  HH 
* MODIFIED By: JayR  TK-14356 Getting ride of double quotes as it causes problems.
*
* Usage:  Validates a VA Inquiry Type
*	
*
* Input params:
*
*	@QueryType - Query Type
*	@Sql - SQL Object / Query
*	
*	
*
* Output params:
*	@msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/

@QueryType tinyint, @Sql varchar(max), @msg varchar(100) OUTPUT   	
   	
AS
BEGIN
	SET NOCOUNT ON
   	
	IF @QueryType IS NULL OR LTRIM(RTRIM(@Sql)) = ''
	BEGIN
		SET @msg = @QueryType + ' not a valid Query Type.'
		RETURN 1
	END
	
	IF @Sql IS NULL
	BEGIN
		SET @msg = 'Missing SQL.'
		RETURN 1
	END
	
	-- No validation on Type Query
	IF @QueryType = 0
	BEGIN
		RETURN 0
	END
	
	-- Validation on Type View
	IF @QueryType = 1
	BEGIN
		SELECT @msg = name
		FROM  sys.views
		WHERE name = LTRIM(RTRIM(@Sql))
	END
	
	IF @@rowcount = 0
    BEGIN
		SET @msg = LTRIM(RTRIM(@Sql)) + ' is not a View.'
		RETURN 1
    END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspVAGridQueryTypeVal] TO [public]
GO
