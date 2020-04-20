SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspHRBLTransDescVal]
    /************************************************************************
    * CREATED:  MH 11/4/02    
    * MODIFIED: MH 8/7/03 Issue 22077 - Using HRCo as PRCo
    *				mh 3/17/04 - 23061   
    *
    * Purpose of Stored Procedure
    *
    *	Validate AP Trans Desc entered in HRResourceBenefits Deductions and
    *	Liabilities.  AP Trans Desc must be null if Dedn/Liab not set up for
    *	Auto updates to AP.  
    *    
    *           
    * Notes about Stored Procedure
    * 
    *
    * returns 0 if successfull 
    * returns 1 and error msg if failed
    *
    *************************************************************************/
    
        (@co bCompany, @prco bCompany, @edlcode bEDLCode, @msg varchar(100) = '' output)
    
    as
    set nocount on
    
        declare @rcode int, @autoap bYN
    
        select @rcode = 0
   
   	if @co is null
   	begin
   		select @msg = 'Missing HR Company.', @rcode = 1
   		goto bspexit
   	end
   
   	if @edlcode is null
   	begin
   		select @msg = 'Missing EDLCode.', @rcode = 1
   		goto bspexit
   	end
   
   	--if prco is null then fall back to the PRCo in HRCO 
    	if @prco is null
    	begin
   
   		select @prco = PRCo from HRCO where HRCo = @co
   
   		if @prco is null
   		begin
   	 		select @msg = 'PR Company must be defined in HR Company', @rcode = 1
    			goto bspexit
   		end
    	end
    
    /*
    	select @autoap = AutoAP 
    	from PRDL 
    	where PRCo = @co and DLCode = @edlcode
    */
    
    	select @autoap = AutoAP 
    	from PRDL 
    	where PRCo = @prco and DLCode = @edlcode
    
    	if @autoap <> 'Y'
    	begin
    		select @msg = 'Dedn/Liab Code ' + 
    		convert(varchar(4), @edlcode) + ' is not set up for Auto updates to AP - AP Transaction Description must be null.',
    		@rcode = 1
    	end
    
    bspexit:
    
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRBLTransDescVal] TO [public]
GO
