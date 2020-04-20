SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRDLVal    Script Date: 1/22/03 9:45:18 AM ******/
   CREATE   proc [dbo].[bspPRDLVal]
   /***********************************************************
    * CREATED BY: EN 1/22/03
    * MODIFIED By : 
    *
    * USAGE:
    * validates PR Dedn or Liab Code from PRDL
    *
    * This routine was developed for issue 17918 (rel. 5.8) specifically for use
    * by form PRPurge which prior to this used bspPREarnDedLiabVal.
    * Return params are PRDL_LimitBasis and PRDL_LimitPeriod values.
    *
    * INPUT PARAMETERS
    *   @prco   	PR Company
    *   @dlcode   	Code to validate
    *
    * OUTPUT PARAMETERS
    *   @limitbasis	from PRDL_LimitBasis
    *   @limitperiod	from PRDL_LimitPeriod
    *   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ******************************************************************/
   	(@prco bCompany = 0, @dlcode bEDLCode = null,
   	@limitbasis char(1) output, @limitperiod char(1) output, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   if @dlcode is null
   	begin
   	select @msg = 'Missing PR Deduction/Liability Code!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg=Description, @limitbasis=LimitBasis, @limitperiod=LimitPeriod
   	from PRDL
   	where PRCo=@prco and DLCode=@dlcode
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Deduction/Liability Code not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDLVal] TO [public]
GO
