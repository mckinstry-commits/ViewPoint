SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspPRDedLiabCalcCategoryVal]
   /***********************************************************
    * CREATED BY: MV 1/22/02
    * MODIFIED By : GG 07/09/02 - cleanup
    * 				EN 3/21/03 - issue 11030 added limitbasis to return params
    *				DAN SO 08/08/12 - TK-16689 - Need to return SubjToArrearsPayback flag
    *
    * USAGE:
    * validates PR Dedn/Liab Code 
    *
    * INPUT 
    *   @prco   		PR Company
    *   @edltype		Code type to validate (D,L, or X if either)
    *   @edlcode   	    DL Code to validate
    *   @calccategory 	Calculation Category restriction (F,S,L,I,C,E, or A if any)
    *
    * OUTPUT 
    *   @edltypeout		Code type (D or L)
    *   @method			Calculation Method
    *   @rate			Rate/Amount 1
    *   @autoap			Automatic AP flag (Y or N)
    *   @factor			Factor - not used
    *	@calcctgryout 	Calculation Category
    *	@SubjArrPayYN	Subject To Arrears/Payback
    *   @msg      		Code description or error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ******************************************************************/
   	(@prco bCompany = 0, @edltype char(1) = null, @edlcode bEDLCode = null, @calccategory varchar (1) = 'A',
   	 @edltypeout char(1) output, @method varchar(10) output, @rate bUnitCost output,
   	 @autoap bYN output, @factor bRate output, @calcctgryout varchar(1) output, 
   	 @limitbasis char(1) output, @ATOCategory varchar(4) output, @SubjArrPayYN bYN output,
   	 @msg varchar(250) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @factor = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   if @edltype is null or @edltype not in ('D','L','X')
   	begin
   	select @msg = 'Missing or invalid Deduction/Liability Type!', @rcode = 1
   	goto bspexit
   	end
   if @edlcode is null
   	begin
   	select @msg = case @edltype when 'D' then 'Missing Deduction Code!'
   								when 'L' then 'Missing Liability Code!'
   								else 'Missing Dedn/Liab Code!' end, @rcode = 1
   	goto bspexit
   	end
   
   -- validate Dedn/Liab code
   select @msg = Description, @edltypeout = DLType, @method = Method, @rate = RateAmt1,
   	@autoap = AutoAP, @calcctgryout = CalcCategory, @limitbasis = LimitBasis, @ATOCategory = ATOCategory,
   	@SubjArrPayYN = SubjToArrearsPayback -- TK-16689
   from PRDL
   where PRCo = @prco and DLCode = @edlcode and (DLType = @edltype or @edltype = 'X')
   if @@rowcount = 0
   	begin
   	select @msg = case @edltype when 'D' then 'Invalid Deduction Code!'
   								when 'L' then 'Invalid Liability Code!'
   								else 'Invalid Dedn/Liab Code!' end, @rcode = 1
   	goto bspexit
   	end
   -- validate Calculation Category
   if @calccategory <> 'A'
   	begin
   	if @calcctgryout not in (@calccategory, 'A') 
   		begin
   		select @msg = 'Invalid Calculation Category for Ded/Liab code.' + char(13)
   		select @msg = @msg + 'Calculation Category must be '
   		select @msg = @msg + case @calccategory when 'C' then 'Craft'
   			when 'F' then 'Fed' 
   			when 'S' then 'State'
   			when 'L' then 'Local' 
   			when 'I' then 'Insurance'
   			when 'E' then 'Employee' end
   		select @msg = @msg + ' or Any. ', @rcode = 1
   		goto bspexit
   		end
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDedLiabCalcCategoryVal] TO [public]
GO
