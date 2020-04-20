SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[vspPRRaceVal]    Script Date: 10/09/2007 11:32:15 ******/
   CREATE  proc [dbo].[vspPRRaceVal]
   /***********************************************************
    * CREATED BY: EN 10/9/07 created based on bspPRRaceVal for issue 120322 to return YN flag indicating
	*						 if race code is in use in bPREH
    * MODIFIED By : 
    *
    * USAGE:
    * validates PR Race from PRRC
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   @PRCo   PR Co to validate agains 
    *   @Race   PR Race to validate
    * OUTPUT PARAMETERS
	*	@raceinpreh	equals Y if there are any entries in PREH containing this race code
    *   @msg      error message if error occurs otherwise Description of Race
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@PRCo bCompany = 0, @Race char(2) = null, @raceinpreh bYN output, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @raceinpreh = 'N'
   
   if @PRCo is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @Race is null
   	begin
   	select @msg = 'Missing race code!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from PRRC
   	where PRCo = @PRCo and Race=@Race
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Race not on file!', @rcode = 1
   	goto bspexit
   	end

	--issue 120322 check PREH for existence of race code
	if (select count(*) from bPREH (nolock) where PRCo = @PRCo and Race = @Race) > 0
		select @raceinpreh = 'Y'

   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRRaceVal] TO [public]
GO
