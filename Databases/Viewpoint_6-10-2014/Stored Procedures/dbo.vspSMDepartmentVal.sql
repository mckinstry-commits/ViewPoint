SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspSMDepartmentVal]
	/******************************************************
	* CREATED BY:	MarkH 
	* MODIFIED By: 
	*
	* Usage:  Validate SM Department setup
	*	
	*
	* Input params:
	*	
	*	@SMCo - SM Company
	*	@Department - Department 
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@SMCo bCompany, @Department bDept, @msg varchar(100) output)
   	
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company.'
		RETURN 1
	END

	DECLARE @IsActive bYN
	
	SELECT @msg = [Description]
	FROM dbo.SMDepartment
	WHERE SMCo = @SMCo AND Department = @Department
	
	IF @@rowcount = 0
    BEGIN
		SET @msg = 'Department has not been setup.'
		RETURN 1
    END
    	
	 
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspSMDepartmentVal] TO [public]
GO
