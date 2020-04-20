SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCapEarnLiabVal    Script Date: 8/28/99 9:33:14 AM ******/
   CREATE     proc [dbo].[bspPRCapEarnLiabVal]
   /***********************************************************
   * CREATED BY: kb 11/18/97
   * MODIFIED By : kb 11/18/97
   * 	    	 MV 1/22/02 Issue 15711 validate calc category
   *				GG 04/10/02 #16860 - allow non-craft liabs in capped basis
   *				EN 10/7/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * validates PR Earn Code  and Liability codes from from PRCI
   * an error is returned if any of the following occurs
   *
   * INPUT PARAMETERS
   *   @prco			PR Co#
   *   @craft			Craft
   *   @eltype			'L' = Liability code, 'E' = Earnings code
   *   @elcode			Liab or Earnings Code  
   *	@source			'C' = Capped Code, 'B' = Capped Code Basis 
   *		
   * OUTPUT PARAMETERS
   *   @msg      		Code description or error message
   *
   * RETURN VALUE
   *   @rcode			0 = success, 1 = error
   *   
   ******************************************************************/ 
   
   	(@prco bCompany = 0, @craft bCraft = null, @eltype char(1) = null, 
   		@elcode bEDLCode = null, @source char(1) = null, @msg varchar(90) output)
   as
   
   set nocount on
   
   declare @rcode int, @method varchar(10), @dltype char(1), @calccategory varchar (1)
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   if @craft is null
   	begin
   	select @msg = 'Missing PR Craft!', @rcode = 1
   	goto bspexit
   	end
   if @eltype is null or @eltype not in ('E','L')
   	begin
   	select @msg = 'Code type must be ''E'' or ''L''!', @rcode = 1
   	goto bspexit
   	end
   if @elcode is null
   	begin
   	if @eltype='E' select @msg = 'Missing PR Earnings Code!'
   	if @eltype='L' select @msg = 'Missing PR Liability Code!'
   	select @rcode = 1
   	goto bspexit
   	end
   
   -- validate Earnings Code 
   if @eltype = 'E'
   	begin
   	select @msg = Description, @method = Method
   	from PREC where PRCo = @prco and EarnCode = @elcode
   	if @@rowcount = 0
   		begin
   		select @msg = 'PR Earnings Code not on file!', @rcode = 1
   		goto bspexit
   		end
   	if @method <> 'H' and @source = 'C'	-- capped codes must be rate/hr
   		begin
   		select @msg = 'Capped Earnings must be ''Rate per Hour''.', @rcode = 1
   		goto bspexit
   		end
   	end
    
   -- validate Liability Code
   if @eltype = 'L'
   	begin
   	select @msg = Description, @method = Method, @dltype = DLType, @calccategory = CalcCategory
   	from PRDL where PRCo = @prco and DLCode = @elcode
   	if @@rowcount = 0
   		begin
   		select @msg = 'Liability Code not on file!', @rcode = 1
   		goto bspexit
   		end
    	if @dltype <> 'L'
    		begin
    		select @msg = 'This is not a liability code', @rcode=1
    		goto bspexit
    		end
    	if @method <> 'H'
    		begin
    		select @msg = 'Liability must be ''Rate per Hour''.', @rcode = 1
    		goto bspexit
    		end
    	if @calccategory not in ('C', 'A') and @source = 'C'	-- capped code is restricted, capped basis is not
    		begin
    		select @msg = 'Calculation Category must be ''Craft'' or ''Any''.', @rcode=1
    		goto bspexit
    		end
    	end
    
   bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCapEarnLiabVal] TO [public]
GO
