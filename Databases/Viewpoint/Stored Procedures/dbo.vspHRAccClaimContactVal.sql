SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRAccClaimContactVal]
	/******************************************************
	* CREATED BY:	MarkH - 10/28/2008 
	* MODIFIED By: 
	*
	* Usage:	Validates Contact in HR Accident Contacts Log.  If a Claim has
	*			been entered then the Contact must exist.
	*	
	*
	* Input params:
	*	
	*		@hrco - HR Company
	*		@accident - Accident
	*		@seq - Accident Sequence
	*		@claimseq - Claim Sequence
	*		@claimcontact - Claim Contact
	*
	* Output params:
	*
	*		@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@hrco bCompany, @accident varchar(10), @seq int, @claimseq int, @claimcontact varchar(10), @msg varchar(100) output)

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if @hrco is null 
	begin
		select @msg = 'Missing HR Company.', @rcode = 1
		goto vspexit
	end

	if @accident is null
	begin
		select @msg = 'Missing Accident.', @rcode = 1
		goto vspexit
	end

	if @seq is null
	begin
		select @msg = 'Missing Accident Detail Seq.', @rcode = 1
		goto vspexit
	end
	
--	if @claimcontact is null
--	begin
--		select @msg = 'Missing Claim Contact.', @rcode = 1
--		goto vspexit
--	end

	if @claimseq is not null
	begin
		--Claim Seq must exist in HRAC and Contact must be assigned to that Claim.
		if exists(select 1 from dbo.HRAC (nolock) where HRCo = @hrco and Accident = @accident and 
			Seq = @seq and ClaimSeq = @claimseq and ClaimContact = @claimcontact)
		begin
			select @msg = HRCC.Name from dbo.HRAC (nolock) Join dbo.HRCC (nolock) on HRAC.HRCo = HRCC.HRCo and 
			HRAC.ClaimContact = HRCC.ClaimContact where HRAC.HRCo = @hrco and HRAC.Accident = @accident and
			HRAC.Seq = @seq and HRAC.ClaimSeq = @claimseq 
		end
		else
		begin
			--User has entered a Contact not assigned to the claim.  It must exist in HRCC.
			if exists(select 1 from HRCC where HRCo = @hrco and ClaimContact = @claimcontact)
			begin
				select @msg = HRCC.Name from HRCC where HRCC.HRCo = @hrco and HRCC.ClaimContact = @claimcontact
			end
			else
			begin
				select @msg = 'Claim Contact is not assigned to Accident Claim and does not exist in HR Accident Claim Contacts.', @rcode = 1
			end
		end
	end
	 
	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRAccClaimContactVal] TO [public]
GO
