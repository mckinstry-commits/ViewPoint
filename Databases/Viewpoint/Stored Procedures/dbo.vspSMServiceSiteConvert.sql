SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspSMServiceSiteConvert]
/***********************************************************
* CREATED BY:	GP	1/20/2012 - TK-11894
* MODIFIED BY:	Chris G 7/25/12 - D-05523 - Allow revert to Job if WOs are only Job specific
*				
* USAGE:
* Used in SM Service Site to convert a Job site to a Customer site or
* convert back to the previous Job site.
*
* INPUT PARAMETERS
*   SMServiceSiteID - Primary key for vSMServiceSite   
*   Customer Group - Group for customers
*	Customer - New customer for site
*	JCCo - Previous JC company to revert to
*	Job - Previous job to revert to
*	ConvertTo - The type to convert the site to (Customer or Job)
*
* OUTPUT PARAMETERS
*   @msg	Error message if found
*
* RETURN VALUE
*   0		Success
*   1		Failure
*****************************************************/ 

(@SMServiceSiteID int, @CustomerGroup bGroup, @Customer bCustomer, @JCCo bCompany, @Job bJob, @ConvertTo varchar(10), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @SMCo bCompany, @ServiceSite varchar(20)
select @rcode = 0


--Validate
if @SMServiceSiteID is null
begin
	select @msg = 'Missing SMServiceSiteID.', @rcode = 1
	goto vspexit
end

--Get additional info from service site table
select @SMCo = SMCo, @ServiceSite = ServiceSite
from dbo.vSMServiceSite
where SMServiceSiteID = @SMServiceSiteID
if @@rowcount = 0
begin
	select @msg = 'SM Service Site does not exist.', @rcode = 1
	goto vspexit
end

if @ConvertTo = 'Customer'
begin
	if @CustomerGroup is null
	begin
		select @msg = 'Missing Customer Group.', @rcode = 1
		goto vspexit
	end

	if @Customer is null
	begin
		select @msg = 'Missing Customer.', @rcode = 1
		goto vspexit
	end
	
	--Validate customer against SM Customer
	if not exists (select 1 from dbo.vSMCustomer where SMCo = @SMCo and CustGroup = @CustomerGroup and Customer = @Customer)
	begin
		--Also against AR Customer
		if not exists (select 1 from dbo.bARCM where CustGroup = @CustomerGroup and Customer = @Customer)
		begin
			select @msg = 'Customer must exist in AR Customers.', @rcode = 1
			goto vspexit
		end
		else
		begin
			--Auto add customer if only missing from SM Customer but not AR	
			insert dbo.vSMCustomer (SMCo, CustGroup, Customer, Active)
			values (@SMCo, @CustomerGroup, @Customer, 'Y')
		end
	end

	--Update Service Site
	update dbo.vSMServiceSite
	set [Type] = @ConvertTo,
		CustGroup = @CustomerGroup,
		Customer = @Customer
	where SMServiceSiteID = @SMServiceSiteID
end
else if @ConvertTo = 'Job'
begin
	if @JCCo is null
	begin
		select @msg = 'Missing JC Company.', @rcode = 1
		goto vspexit
	end

	if @Job is null
	begin
		select @msg = 'Missing Job.', @rcode = 1
		goto vspexit
	end
	
	--Check that Job record exists
	if not exists (select 1 from dbo.bJCJM where JCCo = @JCCo and Job = @Job)
	begin
		select @msg = 'Job does not exist in JC Job Master.', @rcode = 1
		goto vspexit	
	end
	
	--Check for existing work orders
	if exists (select 1 from dbo.vSMWorkOrder where SMCo = @SMCo and ServiceSite = @ServiceSite and Job is null)
	begin
		select @msg = 'Customer work orders exist for this site.', @rcode = 1
		goto vspexit
	end
	
	--Update Service Site (revert back to Job)
	update dbo.vSMServiceSite
	set [Type] = @ConvertTo,
		Customer = null
	where SMServiceSiteID = @SMServiceSiteID
end


	
vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspSMServiceSiteConvert] TO [public]
GO
