SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBProgUpdateJCCINotes Script Date: ******/
CREATE  proc [dbo].[vspJBProgUpdateJCCINotes]
/********************************************************************************************************
* CREATED BY:	TJL 02/28/06 - Issue #28051, 6x recode.  Update JCCI.Notes from JBProgress SM/Tax tab Notes
* MODIFIED BY:  
*
*
* USED IN:
*	JBProgBillItemSMAndTax Form
*
* USAGE:
*	Special update for JCCI Notes attached to each JBIT Bill Items record.  This is separate from
*	the actual JBIT Bill Item Notes and must be coded for special.
*
*
* INPUT PARAMETERS
*	@jbco			JB Company
*	@contract		Contract
*	@contractitem	ContractItem
*	@jccinote		JCCI Note passed in from form
*	
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
*********************************************************************************************************/
    
(@jbco bCompany, @contract bContract, @contractitem bContractItem, @jccinote varchar(8000) = '', @msg varchar(255) output)

as

set nocount on

declare	@rcode int

select @rcode = 0
   
if @jbco is null
	begin
	select @msg = 'JB Company missing.', @rcode = 1
	goto vspexit
	end
if @contract is null
	begin
	select @msg = 'Contract is missing.', @rcode = 1
	goto vspexit
	end
if @contractitem is null
	begin
	select @msg = 'ContractItem is missing.', @rcode = 1
	goto vspexit
	end
if @jccinote is null
	begin
	select @jccinote = ''
	end

/* Update JCCI Note - Contract Item already exists. */
if @jccinote is not null
	begin
	update bJCCI
	set Notes = @jccinote
	where JCCo = @jbco and Contract = @contract and Item = @contractitem
	if @@rowcount = 0
		begin
		select @msg = 'ContractItem Notes did not update successfully.', @rcode = 1
		goto vspexit
		end
	end
   
vspexit:
   
if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[vspJBProgUpdateJCCINotes]'
   
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBProgUpdateJCCINotes] TO [public]
GO
