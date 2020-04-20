SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRRaceVal    Script Date: 8/28/99 9:33:34 AM ******/
   CREATE  proc [dbo].[bspPRRaceVal]
   /***********************************************************
    * CREATED BY: EN 7/21/98
    * MODIFIED By : EN 7/21/98
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR Race from PRRC
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   @PRCo   PR Co to validate agains 
    *   @Race   PR Race to validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Race
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@PRCo bCompany = 0, @Race char(2) = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
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
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRaceVal] TO [public]
GO
