SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspARCustomerValForARCM]
/***********************************************************
* CREATED BY: TJL   12/10/04
* MODIFIED By :  TJL 10/28/08 - Issue #130622, Auto sequence next Customer number.
* 
*
* USAGE:
*  Validates Customer to make sure you can post to it
*  If customer is not found using ARCM.Customer then will try to find match using ARCM.Sortname
* 
*
* INPUT PARAMETERS
*   CustGroup  Customer Group
*   Customer# Customer to validate
*   
*           
* OUTPUT PARAMETERS
*   @msg      error message if error occurs, otherwise Name of customer
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/
(@CustGroup tinyint = null, @Customer bSortName, @CustomerOutput bCustomer output, 
	@msg varchar(150) output)
as
set nocount on

declare @rcode int, @Status char(1), @SortNameChk bSortName
select @rcode = 0

if @CustGroup is null
	begin
  	select @msg = 'Missing Customer Group!', @rcode = 1
  	goto vspexit
  	end
if @Customer is null
	begin
	select @msg = 'Missing Customer!', @rcode = 1
	goto vspexit
	end

/* Auto Numbering for new Customer */
if substring(@Customer,1,1) = char(39) and  substring(@Customer,2,1) = '+'		--'+
	begin
	if len(convert(varchar, (select isnull(Max(Customer), 0) + 1
		from ARCM with (nolock) where CustGroup = @CustGroup))) > 6
		begin
		select @msg = 'Next Customer value exceeds the maximum value allowed for this input.'
		select @msg = @msg +'  You must enter a specific Customer value less than 999999.', @rcode = 1
		end
	else
		begin
		select @CustomerOutput = isnull(Max(Customer), 0) + 1
		from ARCM with (nolock)
		where CustGroup = @CustGroup
		end

	goto vspexit
	end

/* If @Customer is numeric then look for Customer number match first. */
if dbo.bfIsInteger((@Customer)) <> 0	-- If IsInteger is True
	and len(@Customer) < 7				-- Maximum allowed by bCustomer Mask #####0
	begin
	/* Validate Customer to make sure it is valid to post entries to */
	select @CustomerOutput = Customer, @Status=Status, @msg=Name
	from ARCM with (nolock) 
	where CustGroup = @CustGroup and Customer = convert(int,convert(float, @Customer))
	end
  
/* If match not found by Customer number, then check if customer entered is actually a sort name. */
if @@rowcount = 0
	begin
    select @SortNameChk = @Customer

    select @msg=Name, @CustomerOutput = Customer
    from ARCM with (nolock) 
	where CustGroup = @CustGroup and SortName = @SortNameChk
    if @@rowcount = 0
    	begin	/* If not an exact sortname match then bring back the first one that is close to a match. */
	 	set rowcount 1
		select @SortNameChk = @SortNameChk + '%'

	 	select @msg=Name, @CustomerOutput = Customer, @Status=Status
		from ARCM with (nolock) 
		where CustGroup = @CustGroup and SortName like @SortNameChk
		if @@rowcount = 0   /* If there is not a match at all */
	   		begin
			if dbo.bfIsInteger(@Customer) <> 0
				and len(@Customer) < 7
				/* No matching customer was found, the input is numeric, so begin new record using inputted Customer #. */
				begin
				select @CustomerOutput = convert(int, convert(float,@Customer))
				goto vspexit
				end
			else
				/* No matching customer was found, the input is a SortName, give error. */
				begin
	     		select @msg = 'Customer not valid!', @rcode = 1
	     		goto vspexit
	   			end
			end
	   	 set rowcount 0
	 	 end
 	end

vspexit:
select @CustomerOutput = convert(int, convert(float,@CustomerOutput))

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARCustomerValForARCM] TO [public]
GO
