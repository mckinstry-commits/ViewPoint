SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************
* Created: Chris G 3/16/11 (TK-02695)
* Modified: 
*
* Validates the Lookup value for the VPQueryParams form.  Lookups cannot have
* paramters.
*
* Inputs:
*	@lookup		Lookup name from DDLH
*	
* Outputs:
*	@lookup			Lookup used on forms
*	@msg			error message
*
* Return code:
*	0 = success, 1 = failure
*
**************************************/
CREATE PROCEDURE [dbo].[vspVPQueryParamsLookupVal] 
	@lookup varchar(30), @msg varchar(60) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    if @lookup is null
	begin
		select @msg = 'Missing lookup parameter'
		return 1
	end
	
	DECLARE @retcode as int
	SET @retcode = 0
	SET @msg = ''
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM DDLH WHERE Lookup = @lookup)
	BEGIN
		select @msg = 'Lookup not found'
		return 1
	END
	
	SELECT @retcode = 1 FROM DDLH WHERE Lookup = @lookup and WhereClause like '%?%'
	
	IF @retcode = 1
		SET @msg = 'Cannot use a lookup that takes parameters.'
	
	RETURN @retcode
END

GO
GRANT EXECUTE ON  [dbo].[vspVPQueryParamsLookupVal] TO [public]
GO
