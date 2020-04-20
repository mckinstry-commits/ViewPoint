SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBAddonSeqSelect    Script Date: ******/
CREATE proc [dbo].[vspJBAddonSeqSelect]
/***********************************************************
* CREATED BY:  TJL 04/17/06 - Issue #28215, 6x Rewrite JBTemplate
* MODIFIED By:  
*
* USAGE:
*	Inserts Addon Sequences into JBTA. (Sequences using this Addon) Tab.  
*   After user has selected Sequences that the current AddonSeq will be
*   applied against, this procedures actually does the insert into the 
*   JBTA table.
*
* INPUT PARAMETERS
*	JBCo, Template, AddonSeq, Sequence String
*
* OUTPUT PARAMETERS
*   @msg      Description or error message
*
* RETURN VALUE
*   0         success
*   1         msg & failure
*****************************************************/
(@jbco bCompany, @template varchar(10), @addonseq int, @seqstring varchar(500),@msg varchar(255) output)
as
set nocount on
   
declare @rcode integer, @findid int, @seq int, @len int
   
select @rcode = 0, @findid = 0, @seq = 0, @len = 0
  
if @jbco is null
	begin
	select @msg = 'JBCo is missing.' 
	select @rcode = 1
	goto vspexit
	end 
if @template is null
	begin
	select @msg = 'Template is missing.' 
	select @rcode = 1
	goto vspexit
	end 
if @addonseq is null
	begin
	select @msg = 'Addon Sequence is missing.' 
	select @rcode = 1
	goto vspexit
	end 

/* Initially remove all existing Sequences for this Addon Sequence. */
if exists(select 1 from bJBTA with (nolock) 
				where JBCo = @jbco and Template = @template and AddonSeq = @addonseq)
	begin
	delete bJBTA
	where JBCo = @jbco and Template = @template and AddonSeq = @addonseq

	if exists(select 1 from bJBTA with (nolock) 
				where JBCo = @jbco and Template = @template and AddonSeq = @addonseq)
		begin	
		select @msg = 'Clearing table in preparation for inserting new Addon Sequences has failed.', @rcode = 1
		goto vspexit
		end
	end

/* Begin inserting selected sequences for this Addon sequence. */
if isnull(@seqstring, '') <> ''
	begin
	select @seqstring = isnull(ltrim(rtrim(@seqstring)),'')
	while (@seqstring <> '')
		begin
		/* Parse input SeqString value into individual Seq # */
		select @findid = charindex('/',@seqstring)
		if @findid = 0
   			begin
   			select @seq = @seqstring
   			select @seqstring = ''
   			end
		else
			begin
   			select @seq = substring(@seqstring, 1, @findid - 1)
   			select @seqstring = substring(@seqstring, @findid + 1, 500)
   			end

		if @seq > 0
			begin
			if not exists(select 1 from bJBTA with (nolock) 
						where JBCo = @jbco and Template = @template and Seq = @seq and AddonSeq = @addonseq)
				begin
				/* Insert each Seq # passed in. */
				insert into bJBTA(JBCo, Template, Seq, AddonSeq)
				values(@jbco, @template, @seq, @addonseq)
				if @@rowcount = 0
					begin	
					select @msg = 'Inserting Sequence #' + Convert(varchar(10),@seq) + ' has failed.', @rcode = 1
					goto vspexit
					end
				end
			end
		end
	end
   
vspexit:
if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[vspJBAddonSeqSelect]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBAddonSeqSelect] TO [public]
GO
