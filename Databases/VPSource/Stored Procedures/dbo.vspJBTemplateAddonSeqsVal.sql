SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBTemplateAddonSeqsVal]
/****************************************************************************
* CREATED BY:  TJL 09/22/06 - Issue #28215 - 6x Recode
* MODIFIED By : 
*
*
* Usage:
*	JBTemplate, AddonSeqs Seq# Validation.  
*
*
*****************************************************************************/
@jbco bCompany, @template varchar(10), @addonseq int, @seqinput int,  @inputtype char(1) output, @templateseqdesc varchar(128) output, 
	@groupnum int output, @msg varchar(255) output

as
set nocount on

declare @rcode int, @addonseqtype char(1)

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

/* Check that sequence type is a Addon sequence. */
select @addonseqtype = Type
from JBTS with (nolock)
where JBCo = @jbco and Template = @template and Seq = @addonseq
if @@rowcount = 0
	begin
	select @msg = 'Missing JB Template Sequence.', @rcode = 1
	goto vspexit
	end

if @addonseqtype not in ('D', 'T')
	begin
	select @msg = 'Sequence selected is not an Addon sequence type (D) or (T).', @rcode = 1
	goto vspexit
	end

/* Check for valid Template Seq. */
select @inputtype = Type, @templateseqdesc = Description, @groupnum = GroupNum
from JBTS with (nolock)
where JBCo = @jbco and Template = @template and Seq = @seqinput
if @@rowcount = 0
	begin
	select @msg = 'Invalid template sequence.', @rcode = 1
	goto vspexit
	end

/* Check that Seq being added may not be Larger then the AddonSeq itself. */
if @seqinput >= @addonseq
	begin
	select @msg = 'Seq# that is to be a basis for this AddonSeq may not be'
	select @msg = @msg + ' the same as or greater than the AddonSeq currently selected.', @rcode = 1
	goto vspexit
	end

/* Check that Seq is not a duplicate entry. */
if exists(select 1 from JBTA with (nolock)
	where JBCo = @jbco and Template = @template and Seq = @seqinput and AddonSeq = @addonseq)
	begin
	select @msg = 'Seq# has already been applied to this AddonSeq.', @rcode = 1
	goto vspexit
	end

/* Check that the Type of sequence being added may have Addons applied to it. */
if @inputtype not in ('S', 'A', 'D', 'T', 'N')
	begin
	select @msg = 'This sequence type may not be the basis of an Addon.', @rcode = 1
	goto vspexit
	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBTemplateAddonSeqsVal] TO [public]
GO
