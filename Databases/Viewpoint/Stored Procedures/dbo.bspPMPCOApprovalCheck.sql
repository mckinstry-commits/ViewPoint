SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPMPCOApprovalCheck]
   /************************************************************************
   * Created By:   GF 04/26/2000
   * Modified By:  GF 04/04/2001 - check for duplicate PCO items that are not numeric
   *				SR 07/09/02 - issue 17738 pass @phasegroup to bspJCVPHASE
   *				GF 12/09/2003 - #23212 - check error messages, wrap concatenated values with isnull
   *
   * Purpose of Stored Procedure is to validate that the contract item(s)
   * assigned to the pending change order item(s) and pending change
   * order item add-on(s) are valid.
   *
   * For pending change order item(s), a valid contract item must be assigned.
   *
   * For pending change order item add-on(s), if a contract item is assigned
   * to the add-on, then must be valid.
   *
   * returns 0 if successfull
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   (@pmco bCompany = null, @project bJob = null, @pcotype bDocType = null,
    @pco bPCO = null, @pcoitem bPCOItem = null, @msg varchar(150) output)
   as
   set nocount on
   
   declare @addon int, @phasegroup bGroup, @phase bPhase, @addon_item bContractItem,
           @costtype bJCCType, @rcode int, @validcnt int, @opencursor tinyint,
           @contract bContract, @JCJPexists char(1), @pphase bPhase, @desc varchar(30),
           @pcontract bContract, @pitem bContractItem, @dept bDept, @projminpct real,
           @vpcoitem bPCOItem, @vcontractitem bContractItem, @vaddon int
   
   select @rcode=0, @opencursor = 0
   
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
   
   if @pcotype is null
       begin
       select @msg = 'Missing PCO Type!', @rcode = 1
    	goto bspexit
       end
   
   if @pco is null
       begin
       select @msg = 'Missing original PCO!', @rcode = 1
    	goto bspexit
       end
   
   if @pcoitem = '' select @pcoitem = null
   
   if @pcoitem is null
     BEGIN
       -- check change order items have not already been approved
       select @validcnt=count(*) from bPMOI with (nolock)
       where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
       and (ACO is not null or ACOItem is not null)
       if @validcnt > 0
           begin
           select @msg='Pending change order item(s) have been approved. Approve each item individually!', @rcode = 1
           goto bspexit
           end
   
       -- check change order items for missing contract item
       select @vpcoitem=PCOItem from bPMOI with (nolock)
       where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
       and ContractItem is null
       if @@rowcount > 0
          begin
    	   select @msg='Missing Contract Item for pending change order item [' + @vpcoitem + ']!', @rcode = 1
     	   goto bspexit
    	   end
   
       -- check change order item(s) for contract item not in JCCI
       select @vpcoitem=a.PCOItem, @vcontractitem=a.ContractItem 
   	from bPMOI a with (nolock)
       where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pcotype and a.PCO=@pco
       and not exists(select * from bJCCI where JCCo=@pmco and Contract=a.Contract and Item=a.ContractItem)
       if @@rowcount > 0
           begin
           select @msg='Contract Item [' + isnull(@vcontractitem,'') + '] for pending change order item [' + isnull(@vpcoitem,'') + '] is not valid!', @rcode = 1
           goto bspexit
           end
   
	---- check change order item add-on(s) for contract item not in JCCI
	select @vaddon=a.AddOn, @vcontractitem=b.Item 
	from bPMOA a with (nolock)
	join bPMPA b with (nolock) on b.PMCo=a.PMCo and b.Project=a.Project and b.AddOn=a.AddOn
	where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pcotype and a.PCO=@pco
	and b.Contract is not null and b.Item is not null
	and not exists(select top 1 1 from bJCCI with (nolock) where JCCo=a.PMCo
					and Contract=b.Contract and Item=b.Item)
	if @@rowcount > 0
		begin
		select @msg='Contract Item [' + isnull(@vcontractitem,'') + '] for add-on [' + convert(varchar(6),isnull(@vaddon,'')) + '] is not valid!', @rcode = 1
		goto bspexit
		end
   
       -- verify pending change order has not been approved
       if exists(select 1 from bPMOP with (nolock) where PMCo=@pmco and Project=@project
                 and PCOType=@pcotype and PCO=@pco and ApprovalDate is not null)
    	  begin
    	  select @msg='The pending change order has already been approved!', @rcode = 1
    	  goto bspexit
    	  end
     END
   ELSE
		BEGIN
		---- check change order item add-on(s) for contract item not in JCCI
		select @vaddon=a.AddOn, @vcontractitem=b.Item 
		from bPMOA a with (nolock)
		join bPMPA b with (nolock) on b.PMCo=a.PMCo and b.Project=a.Project and b.AddOn=a.AddOn
		where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pcotype and a.PCO=@pco
		and a.PCOItem=@pcoitem and b.Item is not null and not exists(select 1 from bJCCI with (nolock)
						where JCCo=@pmco and Contract=b.Contract and Item=b.Item)
		if @@rowcount > 0
			begin
			select @msg='Contract Item [' + isnull(@vcontractitem,'') + '] for add-on [' + convert(varchar(6),isnull(@vaddon,'')) + '] is not valid!', @rcode = 1
			goto bspexit
			end
		END
   
   
   
   -- declare cursor on PMPA
   -- spin through each add-on for project(PMPA), if used on pending change order item
   -- being approved then validate the phase and cost type
   declare bcPMPA cursor LOCAL FAST_FORWARD
   for select AddOn, PhaseGroup, Phase, CostType
   from bPMPA
   where PMCo=@pmco and Project=@project
   
   -- open cursor
   open bcPMPA
   set @opencursor = 1
   
   PMPA_loop:
   fetch next from bcPMPA into @vaddon, @phasegroup, @phase, @costtype
   
   if @@fetch_status <> 0 goto PMPA_end
   
   -- if phase is null, skip validation
   if isnull(@phase,'') = '' goto PMPA_loop
   
   -- validate that add-on is assigned to one of the pending change order items being approved.
   if @pcoitem is null
   	begin
   	select @validcnt=count(*) from bPMOA with (nolock)
   	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and AddOn=@vaddon
   	if @validcnt = 0 goto PMPA_loop
   
   	-- check if on PCO item
   	select @validcnt=count(*) from bPMOA with (nolock)
   	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem and AddOn=@vaddon
   	if @validcnt = 0  goto PMPA_loop
   	end
   
   -- validate cost type
   if not exists (select top 1 1 from bJCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@costtype)
       begin
     	select @msg='Invalid Cost Type [' + convert(varchar(3),isnull(@costtype,'')) + '] assigned to add-on [' + convert(varchar(6),isnull(@vaddon,'')) + '] in PM Project Add-ons!', @rcode = 1
       goto bspexit
       end
   
   -- validate phase
   exec @rcode=dbo.bspJCVPHASE @pmco, @project, @phase, @phasegroup,'Y', @pphase output, @desc output, @phasegroup output,
                @contract output, @pitem output, @dept output, @projminpct output,@JCJPexists output,
                @msg output
   if @rcode <> 0 goto bspexit
   
   goto PMPA_loop
   
   
   
   
   PMPA_end:
   	close bcPMPA
   	deallocate bcPMPA
   	set @opencursor = 0
   
   
   
   bspexit:
       if @opencursor <> 0
           begin
           close bcPMPA
           deallocate bcPMPA
           set @opencursor = 0
           end
   
       if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOApprovalCheck] TO [public]
GO
