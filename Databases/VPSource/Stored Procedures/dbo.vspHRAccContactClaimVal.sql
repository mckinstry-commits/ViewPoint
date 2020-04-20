SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRAccContactClaimVal]
	/******************************************************
	* CREATED BY:	MarkH 10/27/2008 
	* MODIFIED By: 
	*
	* Usage:	Validates Claim Seq against HRAC 
	*	
	*
	* Input params:
	*	
	*	@hrco - HR Company
	*	@accident - Accident
	*	@seq - Accident Seq
	*	@claimseq - Claims Seq
	*
	* Output params:
	*
	*	@claimcontact - Claim Contact
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@hrco bCompany, @accident varchar(10), @seq int, @claimseq int, @claimcontact varchar(10) output, @msg varchar(100) output)
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
		select @msg = 'Missing Seq.', @rcode = 1
		goto vspexit
	end

--	if @claimseq is null
--	begin
--		select @msg = 'Missing Claim Sequence.', @rcode = 1
--		goto vspexit
--	end

	if @claimseq is not null
	begin
		if exists(select 1 from dbo.HRAC (nolock) where HRCo = @hrco and Accident = @accident and Seq = @seq and
		ClaimSeq = @claimseq) 
		begin
			select @claimcontact = ClaimContact from dbo.HRAC (nolock) where HRCo = @hrco and Accident = @accident and Seq = @seq and
			ClaimSeq = @claimseq
		end
		else
		begin
			select @msg = 'Invalid Claim Sequence', @rcode = 1
			goto vspexit
		end
	end

	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRAccContactClaimVal] TO [public]
GO
