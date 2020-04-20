SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].[vspPRDeleteDeductionGroupVal]    Script Date: 10/20/10 ******/
   CREATE  proc [dbo].[vspPRDeleteDeductionGroupVal]
   /***********************************************************
    * CREATED BY: MCP 10/20/10 
	*						 
    * MODIFIED By : 
    *
    * USAGE:
    * Verifies that the PR Deduction Group that is being deleted is not used in bPRDL
    * 
    *
    * INPUT PARAMETERS
    *   @PRCo		PR Co to validate agains 
    *   @dedngroup  PR Deduction Group to validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/  
   
   (@PRCo bCompany = 0, @dedngroup tinyint = null, @msg varchar(100) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @PRCo is null
   	begin
   		select @msg = 'Missing PR Company!', @rcode = 1
   		goto bspexit
   	end
   
   if @dedngroup is null
   	begin
   		select @msg = 'Missing Deduction Group code!', @rcode = 1
   		goto bspexit
   	end

	if (select count(*) from dbo.bPRDL a (nolock) where a.PRCo = @PRCo and a.PreTaxGroup = @dedngroup) > 0
	begin
		select @msg= 'PR Deduction group has been assigned to a Pre-Tax Deduction and cannot be deleted', @rcode = 1
		goto bspexit
	end
	
   bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRDeleteDeductionGroupVal] TO [public]
GO
