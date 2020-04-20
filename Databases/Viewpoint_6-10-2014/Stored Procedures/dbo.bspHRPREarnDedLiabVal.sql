SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRPREarnDedLiabVal]
   /************************************************************************
   * CREATED:  MH 7/3/03    
   * MODIFIED: MV 08/21/2012 - TK-17317 added NULL output param to bspPREarnDedLiabVal   
   *
   * Purpose of Stored Procedure
   *
   *    Validates PR Earn Code against PREC or PR Dedn Code against PRDL
   *           
   * Notes about Stored Procedure
   * 
   *	If PRCo is not passed in, get the PRCo form HRCO.
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   	(@hrco bCompany, @prco bCompany, @edltype char(1) = null, @edlcode bEDLCode = null,
   	@edltypeout char(1) output, @method varchar(10) output, @rate bUnitCost output,
   	@autoap bYN output, @factor bRate output, @msg varchar(60) output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @hrco is null
   	begin
   		select @msg = 'Missing HRCo', @rcode = 1
   		goto bspexit
   	end
   
     	if not exists(select 1 from HRCO where HRCo = @hrco)
   	begin
   	    select @msg = 'Invalid HR Company', @rcode = 1
   		goto bspexit
   	end
   
   	if @prco is null
   		select @prco = PRCo from HRCO where HRCo = @hrco
   
   	if @prco is null
   	begin
   		select @msg = 'Missing PR Company', @rcode = 1
   		goto bspexit
   	end
   
   	exec @rcode = bspPREarnDedLiabVal @prco, @edltype, @edlcode,
   	@edltypeout output, @method output, @rate output,
   	@autoap output, @factor output, null, NULL, @msg output
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRPREarnDedLiabVal] TO [public]
GO
