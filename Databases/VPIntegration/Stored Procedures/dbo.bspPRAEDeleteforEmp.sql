SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRAEDeleteforEmp]
   /************************************************************************
   * CREATED:	mh 3/24/2005    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *   Delete Auto Earnings entries from PRAE for an Employee.  Used
   *	in PR Employee Master when an Employee is inactivated.  Issue 23339
   *    
   *           
   * Notes about Stored Procedure
   * 
   *	@prco - Employee's Payroll Company
   *	@employee - PR Employee number
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@prco bCompany = null, @employee bEmployee = null, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @prco is null
   	begin
   		select @msg = 'Missing Payroll Company.', @rcode = 1
   		goto bspexit
   	end
   
   	if @employee is null
   	begin
   		select @msg = 'Missing Employee number.', @rcode = 1
   		goto bspexit
   	end
   
   	delete dbo.PRAE where PRCo = @prco and Employee = @employee
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAEDeleteforEmp] TO [public]
GO
