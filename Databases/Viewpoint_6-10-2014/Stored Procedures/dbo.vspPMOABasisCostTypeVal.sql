SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE proc [dbo].[vspPMOABasisCostTypeVal]
/*************************************
* CREATED BY:	GF 02/28/2008 issue #127210 6.1.0
* MODIFIED By:
*
*
*
* validates PMOA Basis Cost Type and returns the cost type cost and cost + markup from PMOL
*
* Pass:
* PMCo
* Project
* PCOType
* PCO
* PCOItem
* Addon
* PhaseGroup
* CostType
*
* Returns:
* @costtypeout
* @desc
* @markupamt
* @netamt
*
* @msg error message if error occurs otherwise Abbreviation of cost type
*
* RETURN VALUE
*   0         success
*   1         Failure
**************************************/
(@pmco bCompany = null, @project bJob = null, @pcotype bDocType = null, @pco bPCO = null,
 @pcoitem bPCOItem = null, @addon tinyint = null, @phasegroup bGroup = null,
 @costtype varchar(10) = null, @costtypeout bJCCType = null output,
 @markupamt bDollar = 0 output, @netamt bDollar = 0 output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @markupamt = 0, @netamt = 0

if @pmco is null
   	begin
   	select @msg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   	end

if @project is null
   	begin
   	select @msg = 'Missing Project!', @rcode = 1
   	goto bspexit
   	end

if @addon is null
   	begin
   	select @msg = 'Missing AddOn Number!', @rcode = 1
   	goto bspexit
   	end

if @phasegroup is null
	begin
	select @msg = 'Missing Phase Group!', @rcode = 1
	goto bspexit
	end

if @costtype is null
	begin
	select @msg = 'Missing Cost Type!', @rcode = 1
	goto bspexit
	end

---- If @costtype is numeric then try to find
if isnumeric(@costtype) = 1
	begin
	select @costtypeout = CostType, @msg = Abbreviation
	from JCCT with (nolock)
	where PhaseGroup = @phasegroup and CostType = convert(int,convert(float, @costtype))
	end

---- if not numeric or not found try to find as Sort Name
if @@rowcount = 0
	begin
	select @costtypeout = CostType, @msg = Abbreviation
	from JCCT with (nolock)
	where PhaseGroup = @phasegroup and CostType=(select min(j.CostType)
	from bJCCT j with (nolock) where j.PhaseGroup=@phasegroup
	and j.Abbreviation like @costtype + '%')
	if @@rowcount = 0
		begin
		select @msg = 'JC Cost Type not on file!', @rcode = 1
		goto bspexit
		end
	end


---- get the cost type amount and cost type amount with markups for the basis cost type
select @markupamt = Round(IsNull(sum(a.EstCost),0)
    		+ isnull(sum(a.EstCost*b.IntMarkUp),0)
    		+ isnull(sum((a.EstCost+IsNull((a.EstCost*b.IntMarkUp),0))*b.ConMarkUp),0),2),
		@netamt = isnull(sum(a.EstCost),0)
from PMOL a with (nolock) 
Join PMOM b with (nolock) on a.PMCo=b.PMCo and a.Project=b.Project and a.PCOType=b.PCOType
and a.PCO=b.PCO and a.PCOItem=b.PCOItem and a.PhaseGroup=b.PhaseGroup and a.CostType=b.CostType
where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pcotype and a.PCO=@pco
and a.PCOItem=@pcoitem and a.CostType=@costtypeout
if @markupamt is null select @markupamt = 0
if @netamt is null select @netamt = 0





bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMOABasisCostTypeVal] TO [public]
GO
