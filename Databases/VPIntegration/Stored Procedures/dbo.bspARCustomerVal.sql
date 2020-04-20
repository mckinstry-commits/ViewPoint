SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARCustomerVal    Script Date: 8/28/99 9:34:10 AM ******/
   CREATE PROC [dbo].[bspARCustomerVal]
   /***********************************************************
   * CREATED BY: JRE   10/20/96
   * MODIFIED By : CJW 5/27/97
   *   	CMW 07/30/02 - added ISNULL to @@rowcount check.
   *		GF 06/18/03 - issue #21568 - deadlocks occuring when posting MS Invoice Batch. Added (nolocks)
   *		TJL 10/02/03 - Issue #22352, Corrected Approximate SortName Error reporting
   *		TJL 06/01/04:  Issue #24633, Avoid Arithmetic Overflow errors
   *
   * USAGE:
   * validates Customer to make sure you can post to it
   * If customer is not found using ARCM.Customer then will try to find match using ARCM.Sortname
   * an error is returned if any of the following occurs
   *     Customer not found
   *
   * INPUT PARAMETERS
   *   CustGroup  Customer Group
   *   Customer# Customer to validate
   *   Option   null = any customer
   *            'A' = Active Only	(Will only error when Customer is InActive)
   *            'H' = Not on Hold	(Will only error when Customer is On Hold)
   *            'X' = Active and Not on hold	(Will error when Customer is InActive or On Hold)
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs, otherwise Name of customer
   * RETURN VALUE
   *   0         Success
   *   1         Failure
   *****************************************************/
   (@CustGroup tinyint = null, @Customer bSortName, @Option char(1)=null,  
   	@CustomerOutput bCustomer output, @msg varchar(255) output)
   as
   set nocount on

   declare @rcode int, @Status char(1), @SortNameChk bSortName
   
   select @rcode = 0, @CustomerOutput = null

   if @CustGroup is null
     	begin
   	select @msg = 'Missing Customer Group!', @rcode = 1
   	goto bspexit
   	end
   if @Customer is null
   	begin
   	select @msg = 'Missing Customer!', @rcode = 1
   	goto bspexit
   	end
 
   /* If @Customer input by user is numeric and is also the correct length allowed
      by bCustomer Mask (max 6), then check for existing record in ARCM.  No sense checking
      otherwise. */
   if isnumeric((@Customer))<> 0	-- If IsNumeric is True
   	and len(@Customer) < 7		-- Maximum allowed by bCustomer Mask #####0
      	begin
      	/* Validate Customer to make sure it is valid to post entries to */
      	select @CustomerOutput = Customer, @Status=Status, @msg=Name
   	from bARCM with (nolock)
   	where CustGroup = @CustGroup and Customer = convert(int,convert(float, @Customer))
   	end

   /* If @CustomerOutput is null, then it was not looked for or found above.  We now
      will treat the Customer input as a SortName and look for it as such. */
   if @CustomerOutput is null
      	begin	/* Begin SortName Check */
   	select @SortNameChk = @Customer
   
   	select @msg=Name, @CustomerOutput = Customer, @Status=Status
   	from bARCM with (nolock)
   	where CustGroup = @CustGroup and SortName = @SortNameChk
   	if @@rowcount = 0
       	begin	/* Begin Approximate SortName Check */		
   		/* Approximate SortName Check.  Input is neither numeric or an exact SortName match. */
   		/* If not an exact SortName then bring back the first one that is close to a match.  */
   	   	select @SortNameChk = @SortNameChk + '%'
   
   	   	select top 1 @CustomerOutput = Customer, @Status=Status, @msg=Name 
   		from bARCM with (nolock)
   		where CustGroup = @CustGroup and SortName like @SortNameChk
   		order by Customer	
   	   	if @@rowcount = 0   /* if there is not a match then display message */
   	   		begin
   	     	select @msg = 'Customer is not valid!', @rcode = 1
   			goto bspexit
   			end
   	 	end		/* End Approximate SortName Check */
      	end		/* End SortName Check */
   
   /* This is a valid Customer, Now do a Status Check */
   if @Option in ('A','X') and @Status='I'
     	begin
       select @msg = 'Customer is not active!', @rcode = 1
       goto bspexit
      	end
   if @Option in ('H','X') and @Status='H'
     	begin
       select @msg = 'Customer is on hold!', @rcode = 1
       goto bspexit
      	end
   
   bspexit:
   	if @rcode<>0 select @msg=@msg			--+ char(13) + char(10) + '[bspARCustomerVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARCustomerVal] TO [public]
GO
