SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRDLCodeVal    Script Date: 5/6/2003 11:00:05 AM ******/
    
    
    /****** Object:  Stored Procedure dbo.bspHRDLCodeVal    Script Date: 2/4/2003 6:53:01 AM ******/
    /****** Object:  Stored Procedure dbo.bspHRDLCodeVal    Script Date: 8/28/99 9:33:16 AM ******/
    CREATE   procedure [dbo].[bspHRDLCodeVal]
    /*************************************
    * Created by:  ae 5/20/99
    *				mh 5/6/03 issue 21212
    * validates  Code given code, type and method
    *
    * Pass:
    *   PRCo - Human Resources Company
    *   Code - Code to be Validated
    *   DLType  - Deduction or Liability?
    *  Method -
    *
    * Returns:
    *   Description or error in @msg if invalid.
    * Error returns:
    *	1 and error message
    **************************************/
    	(@PRCo bCompany = null, @DLCode bEDLCode, @DLType char(1) ,  @Method  varchar(10),
        @msg varchar(60) output)
    as
    	set nocount on
    	declare @rcode int
       	select @rcode = 0
    
    if @PRCo is null
    	begin
    	select @msg = 'Missing PR Company', @rcode = 1
    	goto bspexit
    	end
    
    if @DLCode is null
    	begin
    	select @msg = 'Missing Code', @rcode = 1
    	goto bspexit
    	end
    
    if @DLType is null
    	begin
    	select @msg = 'Missing D/L Type',@rcode = 1
    	goto bspexit
    	end
    
    
    if @Method is null
    	begin
    	select @msg = 'Missing Method',@rcode = 1
    	goto bspexit
    	end
   
   /* 
    select *  from PRDL where PRCo = @PRCo and DLCode = @DLCode and DLType = @DLType and Method = @Method
    	if @@rowcount = 0
   */
   	if not exists(select PRCo from PRDL where PRCo = @PRCo and DLCode = @DLCode and DLType = @DLType and Method = @Method)
    		begin
    		select @msg = 'Not a valid D/L Code.', @rcode = 1
   			goto bspexit
          	end
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRDLCodeVal] TO [public]
GO
