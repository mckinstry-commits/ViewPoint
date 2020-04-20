SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspSMDepartmentGLCoVal]
	/******************************************************
	* CREATED BY:  MarkH 
	* MODIFIED By: 
	*
	* Usage:  Procedure checks for related override records
	*			when changing GL Company.  GL Accounts are dependent on
	*			GL Company.  Changing the GL Company requires GL Accounts
	*			to be re-entered.
	*	
	*
	* Input params:
	*	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@SMCo bCompany, @Department bDept, @GLCo bCompany, @Msg varchar(100) output)
   	
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0
	
	IF @SMCo is null
	BEGIN
		SELECT @Msg = 'Missing SM Company', @rcode = 1
		RETURN @rcode
	END
	
	IF @Department is null
	BEGIN	
		SELECT @Msg = 'Missing Department', @rcode = 1
		RETURN @rcode
	END
	
	IF @GLCo is null
	BEGIN
		SELECT @Msg = 'Missing GL Company', @rcode = 1
		RETURN @rcode
	END
	
	EXEC @rcode = bspGLCompanyVal @GLCo, @Msg output
	
	IF @rcode <> 0
	BEGIN
		RETURN @rcode
	END
		
	
	IF EXISTS(SELECT 1 FROM SMDepartmentOverrides WHERE SMCo = @SMCo and Department = @Department and ISNull(GLCo,-1) <> @GLCo)
	BEGIN
		SELECT @Msg = 'Department overrides must be deleted before changing GL Company.', @rcode = 1
		RETURN @rcode
	END
		
	RETURN @rcode		 


GO
GRANT EXECUTE ON  [dbo].[vspSMDepartmentGLCoVal] TO [public]
GO
