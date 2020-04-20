SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBCostTypeVal]
/***********************************************************
* CREATED BY:     05/12/00 bc
* MODIFIED By : kb 8/7/00 - added validation to make sure that the
*         			costtype is unique among all template source/category combination
*  	RM 02/28/01 - Changed Cost type to varchar(10)
*  	kb 4/1/2 - issue #16848
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 09/22/06 - Issue #28215, 6x Rewrite.  Return JBTS values for JBTC defaults
* USAGE:
*
* INPUT PARAMETERS
*   JBCo      JB Co to validate against
*
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Contract
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
@jbco bCompany, @costtype varchar(10), @template varchar(10), @templateseq int,
	@costtypeout bJCCType output, @catgy char(1) output, @apyn bYN output, @emyn bYN output, 
	@inyn bYN output, @jcyn bYN output, @msyn bYN output, @pryn bYN output, @seqcategory varchar(10) output,
	@liabtype bLiabilityType output, @earntype bEarnType output, @earnliabopt char(1) output, 
	@msg varchar(255) output
   
as
set nocount on
  
declare @rcode int, @seqtype char(1), @phasegrp bGroup, @desc varchar(10)
   
select @rcode = 0
   
if @jbco is null
	begin
	select @msg = 'Missing JB Company.', @rcode = 1
	goto bspexit
	end

/* Check that this is not a change being made to Standard Templates. */
if @template is null
	begin 
	select @msg = 'Missing JB Template.', @rcode = 1
	goto bspexit
	end

/* Must be run from form code otherwise JOIN columns get cleared when moving thru records */
--if @template in ('STD ACTDT','STD CONT','STD PHASE','STD SEQ') 
--	and SUSER_SNAME() <> 'bidtek' and SUSER_SNAME() <> 'viewpointcs'
--	begin
--	select @msg = 'Cannot edit Standard templates.', @rcode = 1
--	goto bspexit
--	end

/* Check that sequence type allows CostTypes to be added. */
select @seqtype = Type
from JBTS with (nolock)
where JBCo = @jbco and Template = @template and Seq = @templateseq
if @@rowcount = 0
	begin
	select @msg = 'Missing JB Template Sequence.', @rcode = 1
	goto bspexit
	end

if @seqtype not in ('S', 'N')
	begin
	select @msg = 'Sequence selected is not a sequence type (S) or (N) and CostTypes may not be added.', @rcode = 1
	goto bspexit
	end

/* Begin CostType validation. */
select @phasegrp = PhaseGroup
from HQCO with (nolock)
where HQCo = @jbco
   
/* If @costtype is numeric then try to find */
if isnumeric(@costtype) = 1
	begin
	select @costtypeout = CostType, @desc = Abbreviation, @catgy = JBCostTypeCategory, @msg = Description
	from JCCT with (nolock)
	where PhaseGroup = @phasegrp and CostType = convert(int,convert(float, @costtype))
	end
   
/* if not numeric or not found try to find as Sort Name */
if isnull(@@rowcount, 0) = 0
	begin
	select @costtypeout = CostType, @desc = Abbreviation, @msg = Description
	from JCCT with (nolock)
	where PhaseGroup = @phasegrp
        and CostType=(select min(j.CostType)
			from bJCCT j
			where j.PhaseGroup=@phasegrp and j.Abbreviation like @costtype + '%')
	if @@rowcount = 0
		begin
		select @msg = 'JC Cost Type not on file!', @rcode = 1
		goto bspexit
		end
	end
   
/* Check if this costtype/source/category combination exists on any other
   template seq, if so then this one can't be added here.  Also return JBTS 
   values back as JBTC defaults. */
select @apyn = APYN, @emyn = EMYN, @inyn = INYN, @jcyn = JCYN, @msyn = MSYN, @pryn = PRYN, 
	@seqcategory = Category, @earnliabopt = EarnLiabTypeOpt, @liabtype = LiabilityType,	
	@earntype = EarnType
from JBTS with (nolock) 
where JBCo = @jbco and Template = @template and Seq = @templateseq
   
if exists(select * from bJBTC where JBCo = @jbco and Template = @template
	and Seq <> @templateseq and  ((APYN = 'Y' and @apyn = 'Y')
		or (INYN = 'Y' and @inyn = 'Y')
		or (PRYN = 'Y' and @pryn = 'Y')
		or (MSYN = 'Y' and @msyn = 'Y')
		or (EMYN = 'Y' and @emyn = 'Y')
		or (JCYN = 'Y' and @jcyn = 'Y'))
	and (Category = @seqcategory
		or (Category is null and @seqcategory is null))
	and (EarnLiabTypeOpt = 'E' and (EarnType is null or (EarnType = @earntype)))
	and (EarnLiabTypeOpt = 'L' and (LiabilityType is null or (LiabilityType = @liabtype)))
	and (EarnLiabTypeOpt = 'B')
--  and (EarnType = @earntype or (EarnType is null and @earntype is null))
--  and (LiabilityType = @liabtype or (LiabilityType is null and @liabtype is null))
	and CostType = @costtypeout)
		begin
		select @msg = 'Cost Type exists on other template seq(s) for this source/category combination',
		@rcode = 1
		end
   
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBCostTypeVal] TO [public]
GO
