SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspHRBLVendorVal]
   /************************************************************************
   * CREATED:  MH 11/1/02    
   * MODIFIED: MH 8/6/03 - Issue 22077 - Using HRCo as PRCo
   *			MH 8/21/03 - Issue 22249 - @edlcode defined as char(2) when it should
   *							be a bEDLCode.  3 digit edlcodes were getting truncated.
   *			mh 3/17/04 - 23061 - Added checks for missing HRCo and EDLCode
   *
   * Purpose of Stored Procedure
   *
   *	Validate Vendor entered in HRResourceBenefits Deductions and
   *	Liabilities.  Vendor must be null if Dedn/Liab not set up for
   *	Auto updates to AP.    
   *    
   *   First check to see if we can have a Vendor for this Dedn/Liab code.  
   *	If not setup for Auto Updates will set the return code to 1 but continue
   *	validating the vendor.  If vendor is invalid user will get the invalid 
   *	vendor message instead.
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@co bCompany, @prco bCompany, @edlcode bEDLCode,  @vendgroup bGroup = null, 
   	@vendor varchar(15) = null, @vendorout bVendor=null output, @msg varchar(100) = '' output)
   
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
   
   
   	--select @prco = PRCo from HRCO where HRCo = @co
   
   	if @prco is null
   	begin
   		select @msg = 'Resource must be assigned to a PR Company.', @rcode = 1
   		goto bspexit
   	end
   
   	/*First check to see if we can have a Vendor for this Dedn/Liab code.  
   	If not setup for Auto Updates will set the return code to 1 but continue
   	validating the vendor.  If vendor is invalid user will get the invalid 
   	vendor message instead.*/
   
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
   		convert(varchar(4), @edlcode) + ' is not set up for Auto updates to AP - Vendor must be null.',
   		@rcode = 1
   	end
   
   	--Copied this code from APVendorVal
   	/* If @vendor is numeric then try to find Vendor number */
   	if isnumeric(@vendor) = 1  
   		select @vendorout = Vendor
    	from APVM
    	where VendorGroup = @vendgroup and Vendor = convert(int,convert(float, @vendor))
   	
   	/* if not numeric or not found try to find as Sort Name */
   	if @@rowcount = 0
    	begin
        	select @vendorout = Vendor
   	 	from APVM
    		where VendorGroup = @vendgroup and SortName = @vendor
    		/* if not found,  try to find closest */
       	if @@rowcount = 0
           begin
           	set rowcount 1
           	select @vendorout = Vendor
    			from APVM
    			where VendorGroup = @vendgroup and SortName like @vendor + '%'
    			if @@rowcount = 0
     	  		begin
    	    		select @msg = 'Not a valid Vendor', @rcode = 1
    				goto bspexit
    	   		end
    		end
    	end
   
   bspexit:
   
        return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspHRBLVendorVal] TO [public]
GO
