SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************************/
CREATE proc [dbo].[bspPMOLPCOGenerate]
/********************************************************
 * Created By:   GF 08/01/2001
 * Modified By:	GF 05/23/2003 - issue #21293 - use percentage for PMOL units when PMOI.UM = JCCI.UM
 *				GF 06/12/2003 - issue #21293 - need to consider when PMOI.Amt = 0 and PMOI.Units <> 0
 *				GF 10/09/2003 - issue #22694 - division by zero when UM='LS', no jcch units, no jcci units
 *				GF 12/09/2003 - #23212 - check error messages, wrap concatenated values with isnull
 *				GF 02/21/2006 - issue #28844 enhancement to generate detail when JCCI.Units = 0 and
 *							JCCI.UnitPrice <> 0 and JCCI.Amount = 0 assume JCCI.Units as one.
 *				GF 02/21/2006 - issue #120258 enhancement to use current values from JCCI and JCCP.
 *				GF 09/05/2010 - changed to use function vfDateOnly
 *				GF 04/29/2012 - TK-14576 #146361 need to write out vendor group to PMOL
 *
 *
 * USAGE:
 *   Generates phase detail for a pending change order item.
 *
 * USED IN
 *   PMChgOrdItemsGrid
 *
 * INPUT PARAMETERS:
 *   PMCO        PM Company
 *	PROJECT     PM Project
 *   PCOType
 *   PCO
 *   PCOItem
 *   Contract
 *   ContractItem
 *
 * OUTPUT PARAMETERS:
 *	Error Message, if one
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO, @pcoitem bPCOItem,
 @contract bContract, @contractitem bContractItem, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @opencursor tinyint, @jcciunits bUnits, @jccium bUM, @jcciamt bDollar,
		@pmoium bUM, @pmoiunits bUnits, @pmoiamt bDollar, @aco bACO, @acoitem bACOItem, @phasegroup bGroup,
		@phase bPhase, @costtype bJCCType, @jcchhours bHrs, @jcchunits bUnits, @jcchcost bDollar,
		@jcchum bUM, @pmolunits bUnits, @pmolhours bHrs, @pmolamt bDollar, @unithours bHrs,
		@hourcost bUnitCost, @unitcost bUnitCost, @pmolcount int,
		@jcciup bUnitCost, @jccp_mth bMonth, @actual_date bDate,
		----TK-14576 146361
		@VendorGroup bGroup

select @rcode = 0, @pmolcount = 0, @opencursor = 0
----#141031
set @actual_date = dbo.vfDateOnly()
set @jccp_mth = dbo.vfDateOnlyMonth()

if @pmco is null
       begin
       select @msg = 'Missing PM company!', @rcode = 1
       goto bspexit
       end

if @project is null
       begin
       select @msg = 'Missing Project!', @rcode = 1
       goto bspexit
       end

if @pcotype is null
       begin
       select @msg = 'Missing PCO Type!', @rcode = 1
       goto bspexit
       end

if @pco is null
       begin
       select @msg = 'Missing PCO!', @rcode = 1
       goto bspexit
       end

if @pcoitem is null
       begin
       select @msg = 'Missing PCO Item!', @rcode = 1
       goto bspexit
       end

if @contract is null
       begin
       select @msg = 'Missing Contract!', @rcode = 1
       goto bspexit
       end

if @contractitem is null
       begin
       select @msg = 'Missing Contract Item!', @rcode = 1
       goto bspexit
       end

-- -- -- check if detail already exists in PMOL
select @validcnt=count(*) from PMOL with (nolock)
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
if @validcnt <> 0
   begin
   select @msg = 'Phase detail already exists for this change order item, cannot generate!', @rcode = 1
   goto bspexit
   end

---- TK-14576 146361 get vendor group using PMCO.APCo
SELECT @VendorGroup = h.VendorGroup
FROM dbo.bPMCO p
INNER JOIN dbo.bHQCO h ON h.HQCo = p.APCo
WHERE p.PMCo = @pmco

-- -- -- get item information from JCCI #120258
select @jccium=UM, @jcciunits=ContractUnits, @jcciamt=ContractAmt, @jcciup=UnitPrice
from JCCI with (nolock) where JCCo=@pmco and Contract=@contract and Item=@contractitem
if @@rowcount = 0
	begin
	select @msg = 'Unable to get Contract Item data from JCCI!', @rcode = 1
	goto bspexit
	end

-- -- -- if contract item units and amount = 0, no generate #28844
if @jcciunits = 0 and @jcciamt = 0 and @jcciup = 0
	begin
	select @msg = 'No contract item units or amount, cannot generate!', @rcode =1
	goto bspexit
	end

-- -- -- if not item units but there is a unit price set units to 1 for calculations #28844
if @jcciunits = 0 and @jcciup <> 0 select @jcciunits = 1

   
-- -- -- get pco item information from PMOI
   select @aco=ACO, @acoitem=ACOItem, @pmoium=UM, @pmoiunits=Units,
          @pmoiamt= case when FixedAmountYN = 'Y' then FixedAmount else PendingAmount end
   from PMOI with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
   if @@rowcount = 0
       begin
       select @msg = 'Unable to get PCO Item data from PMOI!', @rcode = 1
       goto bspexit
       end
   else
       begin
       -- check if approved
       if isnull(@aco,'') <> '' or isnull(@acoitem,'') <> ''
           begin
           select @msg = 'This PCO Item has been approved on ACO: ' + isnull(@aco,'') + ' ACOItem: ' + isnull(@acoitem,'') + ' , cannot generate!', @rcode = 1
           goto bspexit
           end
       -- check if PCO Item UM <> Contract Item UM
       if @pmoium <> @jccium
           begin
           select @msg = 'PCO Item UM (' + isnull(@pmoium,'') + ') <> contract item UM (' + isnull(@jccium,'') + '), cannot generate!', @rcode = 1
           goto bspexit
           end
       end
   
   
-- -- -- pseudo cursor on JCJP
select @phase=min(Phase) from JCJP with (nolock) where JCCo=@pmco and Job=@project
while @phase is not null
begin
	-- -- -- get phase information
	select @phasegroup=PhaseGroup
	from JCJP with (nolock) where JCCo=@pmco and Job=@project and Phase=@phase and Contract=@contract and Item=@contractitem
	if @@rowcount = 0 goto next_jcjp_row
   
	-- -- -- declare cursor on JCCH phase cost types
	declare bcJCCH cursor FAST_FORWARD
   	for select CostType, UM -- -- -- , OrigHours, OrigUnits, OrigCost #120258
	from bJCCH where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
   
	-- -- -- open cursor
	open bcJCCH
	select @opencursor = 1
   
	JCCH_loop:
	fetch next from bcJCCH into @costtype, @jcchum -- -- --, @jcchhours, @jcchunits, @jcchcost #120258
   
	if @@fetch_status <> 0 goto JCCH_end

	-- -- -- get current estimate values from JCCP for phase and cost type through current month #120258
	select @jcchhours = 0, @jcchunits = 0, @jcchcost = 0
	select @jcchhours=sum(CurrEstHours), @jcchunits=sum(CurrEstUnits), @jcchcost=sum(CurrEstCost)
	from bJCCP with (nolock)
	where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype and Mth<=@jccp_mth

	-- -- -- reset values
	select @pmolunits = 0, @pmolhours = 0, @pmolamt = 0, @unithours = 0, @hourcost = 0, @unitcost = 0
   
	-- -- -- if UM match issue #21293
       if @pmoium = @jcchum 
   		begin
   		if @jcciunits <> 0
   			select @pmolunits =((@pmoiunits/@jcciunits)*@jcchunits)
   		else
   			select @pmolunits = @pmoiunits
   		end
   
       -- -- -- if UM do not match and contract item OrigUnits <> 0
       if @pmoium <> @jcchum
           begin
           if @jcciunits <> 0
               select @pmolunits = ((@pmoiunits/@jcciunits)*@jcchunits)
           else
               select @pmolunits = 0
           end
   
       -- -- -- if UM = 'LS' and JCCH units = 0 calculate lump sum dollars
       if @jcchum = 'LS' and @jcchunits = 0
           begin
           select @pmolunits = 0
   		if @jcciamt <> 0 and @pmoiamt = 0 and @jcciunits <> 0
   			begin
   			select @pmolamt = ((@pmoiunits/@jcciunits)*@jcchcost),
   				   @pmolhours = ((@pmoiunits/@jcciunits)*@jcchhours)
   			goto PMOL_ADD
   			end
   
           if @jcciamt <> 0
   			begin
               select @pmolamt = ((@pmoiamt/@jcciamt)*@jcchcost),
                      @pmolhours = ((@pmoiamt/@jcciamt)*@jcchhours)
   			end
           else
               select @pmolamt = 0, @pmolhours = 0
   
           goto PMOL_ADD
           end
   
   
       -- -- -- if UM = 'LS' and contract item amount <> 0
       if @jcchum = 'LS'
           begin
           if @jcciamt <> 0
               select @pmolunits = ((@pmoiamt/@jcciamt)*@jcchunits)
           else
               select @pmolamt = 0
           end
   
       -- -- -- calculate using JCCH original units
       if @jcchunits <> 0
           select @pmolamt = ((@jcchcost/@jcchunits)*@pmolunits),
                  @pmolhours = ((@jcchhours/@jcchunits)*@pmolunits)
       else
           select @pmolamt = 0, @pmolhours = 0
   
       PMOL_ADD:
   
       if @pmolunits <> 0 select @unitcost = (@pmolamt/@pmolunits), @unithours = (@pmolhours/@pmolunits)
       if @pmolhours <> 0 select @hourcost = (@pmolamt/@pmolhours)
       if @jcchum = 'LS' select @pmolunits = 0
   
       -- -- -- insert PMOL record
       insert into bPMOL (PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, CostType,
                   EstUnits, UM, UnitHours, EstHours, HourCost, UnitCost, ECM, EstCost, SendYN,
                   ----TK-14576 146361
                   VendorGroup)
       select @pmco, @project, @pcotype, @pco, @pcoitem, null, null, @phasegroup, @phase, @costtype,
					isnull(@pmolunits,0), @jcchum, isnull(@unithours,0), isnull(@pmolhours,0), isnull(@hourcost,0), 
					isnull(@unitcost,0), 'E', isnull(@pmolamt,0), 'Y',
					----TK-14576 146361
                    @VendorGroup
       if @@rowcount = 0
           begin
           select @msg = 'Error inserting cost type ' + convert(varchar(3),isnull(@costtype,'')) + ' into PMOL.', @rcode = 1
           goto bspexit
           end
   
       select @pmolcount = @pmolcount + 1
       goto JCCH_loop


	-- -- -- de-allocate JCCH cursor
	JCCH_end:
		if @opencursor <> 0
			begin
			close bcJCCH
			deallocate bcJCCH
			select @opencursor = 0
			end



next_jcjp_row:
select @phase=min(Phase) from JCJP with (nolock) where JCCo=@pmco and Job=@project and Phase>@phase
if @@rowcount = 0 select @phase = null
end




bspexit:
	if @opencursor <> 0
		begin
		close bcJCCH
		deallocate bcJCCH
		select @opencursor = 0
		end
   
	if @rcode= 0 select @msg = 'Generated ' + convert(varchar(6),@pmolcount) + ' phase detail records into PMOL.'
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMOLPCOGenerate] TO [public]
GO
