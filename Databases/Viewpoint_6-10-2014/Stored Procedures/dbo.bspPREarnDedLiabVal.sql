SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREarnDedLiabVal    Script Date: 8/28/99 9:33:18 AM ******/
   CREATE  proc [dbo].[bspPREarnDedLiabVal]
   /***********************************************************
    * CREATED BY: kb 1/23/98
    * MODIFIED By : GG 02/07/98
    * MODIFIED BY: EN 7/21/99
    *				EN 10/8/02 - issue 18877 change double quotes to single
	*				EN 5/22/07 - issue 120307 include PREC_IncludSalaryDist flag in return params
    *				TL 7/05/12 TK-16109 added JC Cost Type has output parameter for SM
    * USAGE:
    * validates PR Earn Code from PREC or PR Dedn Code from PRDL
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   @prco   	PR Company
    *   @edltype	Code type to validate ('E', 'D', 'L', 'X' (can be dedn or liab))
    *   @edlcode   	Code to validate
    *
    * OUTPUT PARAMETERS
    *   @edltypeout	Code type ('E', 'D', or 'L')
    *   @method	Method
    *   @rate	Rate Amount 1
    *   @autoap	Automatic AP - dedns/liabs only
    *   @factor	Factor -earnings only
	*	@incldsalarydist	Include in Salary Distributions flag
    *   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ******************************************************************/
   	(@prco bCompany = 0, @edltype char(1) = null, @edlcode bEDLCode = null,
   	@edltypeout char(1) output, @method varchar(10) output, @rate bUnitCost output,
   	@autoap bYN output, @factor bRate output, @incldsalarydist bYN output, @jccosttype bJCCType output, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int, @PRedtype char(1), @PRDLdltype char(1)
   select @rcode = 0
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   if @edltype is null
   	begin
   	select @msg = 'Missing Earnings/Deduction/Liability Type!', @rcode = 1
   	goto bspexit
   	end
   if @edlcode is null
   	begin
   	if @edltype='D'
   		begin
   		select @msg = 'Missing PR Deduction Code!', @rcode = 1
   		goto bspexit
   		end
   	if @edltype='E'
   		begin
   		select @msg = 'Missing PR Earnings Code!', @rcode = 1
   		goto bspexit
   		end
   	if @edltype='L'
   		begin
   		select @msg = 'Missing PR Liability Code!', @rcode = 1
   		goto bspexit
   		end
   	if @edltype='X'
   		begin
   		select @msg = 'Missing PR Deduction/Liability Code!', @rcode = 1
   		goto bspexit
   		end
   	end
   if @edltype='E'
   	begin
   	select @msg = Description, @method=Method, @factor = Factor, @incldsalarydist = IncldSalaryDist, @jccosttype=JCCostType
   		from PREC
   		where PRCo = @prco and EarnCode=@edlcode
   	if @@rowcount = 0
   		begin
   		select @msg = 'PR Earnings Code not on file!', @rcode = 1
   		goto bspexit
   		end
   	select @edltypeout=@edltype
   	end
   if @edltype='D' or @edltype='L' or @edltype='X'
   	begin
   	select @msg=Description, @PRDLdltype=DLType, @method=Method, @rate=RateAmt1, @autoap=AutoAP
   		from PRDL
   		where PRCo=@prco and DLCode=@edlcode
   	if @@rowcount = 0
   		begin
   		if @edltype='D'
   			begin
   			select @msg = 'PR Deduction Code not on file!', @rcode = 1
   			goto bspexit
   			end
   		if @edltype='L'
   			begin
   			select @msg = 'PR Liability Code not on file!', @rcode = 1
   			goto bspexit
   			end
   		if @edltype='X'
   			begin
   			select @msg = 'PR Deduction/Liability Code not on file!', @rcode = 1
   			goto bspexit
   			end
   		end
   	if @edltype<>@PRDLdltype and @edltype<>'X'
   		begin
   		if @edltype='D'
   			begin
   			select @msg = 'This is not a deduction code!', @rcode=1
   			goto bspexit
   			end
   		if @edltype='L'
   			begin
   			select @msg = 'This is not a liability code!', @rcode=1
   			goto bspexit
   			end
   		end
   
   	if @edltype='X' select @edltypeout=@PRDLdltype
   	end
   bspexit:
   	select @factor = isnull(@factor,0)
   	--select @factor = null
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREarnDedLiabVal] TO [public]
GO
