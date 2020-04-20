SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBTemplateSeqAddonsVal]
/****************************************************************************
* CREATED BY:  TJL 09/22/06 - Issue #28215 - 6x Recode
* MODIFIED By : 
*
*
* Usage:
*	JBTemplate, SeqAddons AddonSeq# Validation.  
*
*
*****************************************************************************/
@jbco bCompany, @template varchar(10), @seq int, @addonseqinput int,  @inputtype char(1) output, @templateseqdesc varchar(128) output, 
	@groupnum int output, @markupopt char(1) output, @markuprate bUnitCost output, @addonamt bDollar output,
	@msg varchar(255) output

as
set nocount on

declare @rcode int, @seqtype char(1)

select @rcode = 0

if @jbco is null
	begin
	select @msg = 'Missing JB Company.', @rcode = 1
	goto vspexit
	end

/* Check that this is not a change being made to Standard Templates. */
if @template is null
	begin
	select @msg = 'Missing JB Template.', @rcode = 1
	goto vspexit
	end

/* Must be run from form code otherwise JOIN columns get cleared when moving thru records */
--if @template in ('STD ACTDT','STD CONT','STD PHASE','STD SEQ') 
--	and SUSER_SNAME() <> 'bidtek' and SUSER_SNAME() <> 'viewpointcs'
--	begin
--	select @msg = 'Cannot edit Standard templates.', @rcode = 1
--	goto vspexit
--	end

/* Check that sequence type allows Addons to be applied. */
select @seqtype = Type
from JBTS with (nolock)
where JBCo = @jbco and Template = @template and Seq = @seq
if @@rowcount = 0
	begin
	select @msg = 'Missing JB Template Sequence.', @rcode = 1
	goto vspexit
	end

if @seqtype not in ('S', 'A', 'D', 'T', 'N')
	begin
	select @msg = 'Addons may not be applied to this sequence type.', @rcode = 1
	goto vspexit
	end

/* Check for valid Template Seq. */
select @inputtype = Type, @templateseqdesc = Description, @groupnum = GroupNum,
	@markupopt = MarkupOpt, @markuprate = MarkupRate, @addonamt = AddonAmt
from JBTS with (nolock)
where JBCo = @jbco and Template = @template and Seq = @addonseqinput
if @@rowcount = 0
	begin
	select @msg = 'Invalid template sequence.', @rcode = 1
	goto vspexit
	end

/* Check that AddonSeq being added may not be smaller then the Seq itself. */
if @addonseqinput <= @seq
	begin
	select @msg = 'AddonSeq# that is to be an Addon to this Seq may not be'
	select @msg = @msg + ' the same as or less than the Seq currently selected.', @rcode = 1
	goto vspexit
	end

/* Check that AddonSeq is not a duplicate entry. */
if exists(select 1 from JBTA with (nolock)
	where JBCo = @jbco and Template = @template and Seq = @seq and AddonSeq = @addonseqinput)
	begin
	select @msg = 'AddonSeq# has already been applied to this Seq.', @rcode = 1
	goto vspexit
	end

/* Check that the Type of sequence being added is that of an Addon type. */
if @inputtype not in ('D', 'T')
	begin
	select @msg = 'Invalid sequence type.  Must be an Addon type sequence (D) or (T).', @rcode = 1
	goto vspexit
	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBTemplateSeqAddonsVal] TO [public]
GO
