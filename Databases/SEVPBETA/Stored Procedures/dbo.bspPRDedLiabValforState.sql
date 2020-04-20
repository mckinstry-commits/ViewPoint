SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPRDedLiabValforState]
   /***********************************************************
    * Created: GG 02/21/03 - #20325 - PRSI.TaxDedn and SUTALiab need special validation
    * Modified: EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
    *
    * USAGE:
    * Validates TaxDedn and SUTALiab codes for PR State Information
    *
    * INPUTS
    *  @prco   	PR Company
    *	@state		State
    *  @dltype		Code type to validate 'D' = deduction, 'L' = liability
    *  @dlcode   	Code to validate
    *
    * OUTPUTS
    *   @msg      error message or DL Description 
   
    * RETURN 
    *   @rcode		0 = success, 1 = error
    ******************************************************************/
   	(@prco bCompany = 0, @state varchar(4) = null, @dltype char(1) = null,
   	 @dlcode bEDLCode = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @prdltype char(1), @calccategory char(1), @xstate varchar(4)
   select @rcode = 0
   
   if @state is null
   	begin
   	select @msg = 'Missing State, cannot validation code', @rcode = 1
   	goto bspexit
   	end
   if @dltype is null or @dltype not in ('D','L')
   	begin
   	select @msg = 'Missing D/L type, cannot validate code', @rcode = 1
   	goto bspexit
   	end
   
   -- validate D/L code
   select @msg = Description, @prdltype = DLType, @calccategory = CalcCategory
   from PRDL
   where PRCo = @prco and DLCode = @dlcode
   if @@rowcount = 0
   	begin
   	select @msg = case @dltype when 'D' then 'Deduction ' when 'L' then 'Liability ' end
   	select @msg = @msg + 'not on file', @rcode = 1
   	goto bspexit
   	end
   if @dltype <> @prdltype
   	begin
   	select @msg = 'Must be a '
   	select @msg = @msg + case @dltype when 'D' then 'Deduction' when 'L' then 'Liability' end, @rcode = 1
   	goto bspexit
   	end
   if @calccategory not in ('S','A')
   	begin
   	select @msg = 'Calculation category must be ''S'' or ''A''', @rcode = 1
   	goto bspexit
   	end
   -- check TaxDedn for uniqueness
   if @dltype = 'D'
   	begin
   	select @xstate = State 
   	from bPRSI
   	where PRCo = @prco and TaxDedn = @dlcode and State <> @state
   	if @@rowcount > 0
   		begin
   		select @msg = 'Already assigned to ' + @xstate, @rcode = 1
   		goto bspexit
   		end
   	end
   -- check SUTALiab for uniqueness
   if @dltype = 'L'
   	begin
   	select @xstate = State 
   	from bPRSI
   	where PRCo = @prco and SUTALiab = @dlcode and State <> @state
   	if @@rowcount > 0
   		begin
   		select @msg = 'Already assigned to ' + @xstate, @rcode = 1
   		goto bspexit
   		end
   	end
   	
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDedLiabValforState] TO [public]
GO
