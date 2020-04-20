SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   CREATE proc [dbo].[vpspPRBeginningPayPeriods]
   /***********************************************************
    * CREATED BY: DW 04/13/2012
    * MODIFIED By : 
    *
    * USAGE:
    * Returns beginning pay periods ... used by connects TimeSheets 
    *
    * INPUT PARAMETERS
    *   PRCo   PR Co to validate agains 
    *   employee  PR Employee to validate
    * OUTPUT PARAMETERS
	*	@BeginDate - Beginning Pay periods
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@PRCo tinyint, @employee int, @msg varchar(60) output, @current_date datetime)
   as
   
   set nocount on
   
   declare @rcode int
   declare @prgroup tinyint
   select @rcode = 0
   
   if @PRCo is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @employee is null
   	begin
   	select @msg = 'Missing PR Employee!', @rcode = 1
   	goto bspexit
   	end
   
   declare @rows int
   select @prgroup = PRGroup
   	from dbo.PREH (nolock)
   	where PRCo = @PRCo and Employee = @employee
   set @rows = @@rowcount
   if @rows = 0
   	begin
   	select @msg = 'PR Group not on file!', @rcode = 1
   	goto bspexit
   	end
   if @rows > 0
    begin
    select BeginDate
    from PRPC
    where PRCo=@PRCo AND PRGroup=@prgroup AND Status=0
    end
   
   bspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vpspPRBeginningPayPeriods] TO [VCSPortal]
GO
