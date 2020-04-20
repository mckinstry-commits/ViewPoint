SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRClaimContactDeleteVal]
	/******************************************************
	* CREATED BY:	MarkH 4/1/2008 
	* MODIFIED By: 
	*
	* Usage:	Prevent delete of Claim Contact if in use by HRAC or HRAI
	*	
	*
	* Input params:
	*	
	*	@hrco - Company
	*	@claimcontact - Contact to validate
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@hrco bCompany, @claimcontact varchar(10), @msg varchar(250) output
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company.', @rcode = 1
		goto vspexit
	end

	if @claimcontact is null
	begin
		select @msg = 'Missing Claim Contact.', @rcode = 1
		goto vspexit
	end

	if exists(select 1 from bHRAC h join bHRCC d on h.HRCo = d.HRCo and h.ClaimContact = d.ClaimContact
	where h.HRCo = @hrco and h.ClaimContact = @claimcontact) 
	begin
		select @msg = 'Contact assigned as a Claim Contact in HR Accident Contacts.', @rcode = 1
		goto vspexit
	end

	if exists(select 1 from bHRAI h join bHRCC d on h.HRCo = d.HRCo and h.AttendingPhysician = d.ClaimContact
	where h.HRCo = @hrco and h.AttendingPhysician = @claimcontact) 
	begin
		select @msg = 'Contact assigned as an Attending Physician in HR Accident Detail.', @rcode = 1
		goto vspexit
	end	

	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRClaimContactDeleteVal] TO [public]
GO
