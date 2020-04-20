SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRHRDeleteW4   Script Date: 07/19/2006 2:02:49 PM ******/
    
	CREATE procedure [dbo].[vspPRHRDeleteW4] 
    /************************************************************************
    * CREATED:	EN 7/19/06   
    * MODIFIED: 
    *
    * Purpose of Stored Procedure
    *
    *	Delete a record from HRWI W4 info table.    
    *           
    * Input params:
    *	@prco		PR company
    *	@employee	Employee number
    *	@dedncode	Deduction code to delete from HRWI
    *
    * Output params:
    *	@errmsg		Error message 
    *
    * Return code:
    *	0 = success, 1 = failure
    *	
    *************************************************************************/
    (@prco bCompany, @employee bEmployee, @dedncode bEDLCode, @errmsg varchar(80) = '' output)
    
    as
    set nocount on
    
   	declare @hrco bCompany, @hrref bEmployee, @rcode int
   
   	select @rcode = 0
   
	select @hrco = HRCo, @hrref = HRRef
	from dbo.bHRRM with (nolock)
	where PRCo = @prco and PREmp = @employee
  
    if exists (select 1 from bHRWI with (nolock) 
		where HRCo = @hrco and HRRef = @hrref and DednCode = @dedncode)
            
	delete from dbo.bHRWI where HRCo = @hrco and HRRef = @hrref and DednCode = @dedncode

    
    bspexit:
	   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRHRDeleteW4] TO [public]
GO
