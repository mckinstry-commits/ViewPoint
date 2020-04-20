SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRInsurVal    Script Date: 8/28/99 9:33:24 AM ******/
   CREATE  proc [dbo].[bspPRInsurVal]
   /***********************************************************
    * CREATED BY: kb 1/8/98
    * MODIFIED By : kb 1/8/98
    *				EN 10/8/02 - issue 18877 change double quotes to single
	*				EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
    *
    * USAGE:
    * validates PR Insurance from PRIN
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   PRCo   PR Co to validate against
    *   Insur  PR Insurance to validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Crew
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   	(@prco bCompany = 0, @state varchar(4) = null, @insur bInsCode = null,
   	 @usethreshold bYN = null output, @thresholdrate bUnitCost = 0 output,
   	 @overrideinscode bInsCode = null output, @msg varchar(60) = null output)
   
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @state is null
   	begin
   	select @msg = 'Missing PR Insurance State!', @rcode = 1
   	goto bspexit
   	end
   
   if @insur is null
   	begin
   	select @msg = 'Missing PR Insurance Code!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @usethreshold=UseThreshold,
   @thresholdrate=ThresholdRate, @overrideinscode=OverrideInsCode
   from PRIN
   where PRCo = @prco and State = @state and InsCode = @insur
   
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Insurance not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRInsurVal] TO [public]
GO
