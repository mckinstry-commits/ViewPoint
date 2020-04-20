SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARUpdateARCMNotes Script Date: ******/
CREATE  proc [dbo].[vspARUpdateARCMNotes]
/********************************************************************************************************
* CREATED BY:	TJL 06/21/06 - Issue #28040, 6x recode.  Update ARCM.Notes from ARCreditNotes
* MODIFIED BY:  
*
*
* USED IN:
*	ARCreditNotes Form
*
* USAGE:
*	Special update for ARCM Notes attached to each ARCN Credit Note record.  This is separate from
*	the actual ARCN CreditNotes Notes and must be coded for special.
*
*
* INPUT PARAMETERS
*	@custgroup		AR CustGroup
*	@customer		Customer
*	@arcmnote		ARCM Note passed in from form
*	
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
*********************************************************************************************************/
    
(@custgroup bGroup, @customer bCustomer, @arcmnote varchar(8000) = '', @msg varchar(255) output)

as

set nocount on

declare	@rcode int

select @rcode = 0
   
if @custgroup is null
	begin
	select @msg = 'CustGroup is missing.', @rcode = 1
	goto vspexit
	end
if @customer is null
	begin
	select @msg = 'Customer is missing.', @rcode = 1
	goto vspexit
	end
if @arcmnote is null
	begin
	select @arcmnote = ''
	end

/* Update ARCM Note - Customer record already exists. */
if @arcmnote is not null
	begin
	update bARCM
	set Notes = @arcmnote
	where CustGroup = @custgroup and Customer = @customer
	if @@rowcount = 0
		begin
		select @msg = 'Customer Notes did not update successfully.', @rcode = 1
		goto vspexit
		end
	end
   
vspexit:
   
if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[vspARUpdateARCMNotes]'
   
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARUpdateARCMNotes] TO [public]
GO
