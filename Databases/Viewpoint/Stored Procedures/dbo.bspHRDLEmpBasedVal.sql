SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRDLEmpBasedVal]
   /************************************************************************
   * CREATED:    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
          
       (@hrco bCompany, @hrref bHRRef, @dlcode bEDLCode, @emplbasedyn bYN, @msg varchar(100) = '' output)
   
   as
   set nocount on
   
       declare @prco bCompany, @calccategory varchar(1), @rcode int
   
       select @rcode = 0
   
   	if @hrco is null
   	begin
   		select @msg = 'Missing HR Company', @rcode = 1
   		goto bspexit
   	end
   
   	if @hrref is null
   	begin
   		select @msg = 'Missing HR Reference number', @rcode = 1
   		goto bspexit
   	end
   
   	if @dlcode is null
   	begin
   		select @msg = 'Missing Deduction/Liability code', @rcode = 1
   		goto bspexit
   	end
   
   	if @emplbasedyn is null
   	begin
   		select @msg = 'Missing EmplbasedYN', @rcode = 1
   		goto bspexit
   	end
   
   	if @emplbasedyn = 'Y'
   	begin
   		select @prco = PRCo from HRRM where HRCo = @hrco and HRRef = @hrref
   
   		select CalcCategory 
   		from PRDL 
   		where PRCo = @prco and DLCode = @dlcode
   
   		select @calccategory = CalcCategory 
   		from PRDL 
   		where PRCo = @prco and DLCode = @dlcode
   
   		if @calccategory not in ('E','A')
   		begin
   			select @msg = 'Calculation Category must be A (Any) or E (Employee) in Payroll when Employee Based = ''Y'''
   			select @rcode = 1
   		end
   	end
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRDLEmpBasedVal] TO [public]
GO
