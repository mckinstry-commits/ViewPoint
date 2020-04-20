SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************************/
   CREATE procedure [dbo].[bspPMPCOApprovalCheckPhases]
   /************************************************************************
   * Created By:	GF 11/01/2004
   * Modified By:	GF 01/30/2007 - issue #123743 mismatch contract item check
   *
   *
   *
   * Purpose of Stored Procedure is to check each phase assigned to PCO item(s)
   * that are going to be approved to see if the phase contract items match
   * the PCO item contract items. If not a warning will appear in the approval
   * window. This SP is called from PMPCOApproval Form.
   *
   * Calling Form = 1 then approving a change order
   * Calling Form = 2 then approving a change order item
   *
   *
   * returns 0 if successfull
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   (@pmco bCompany = null, @project bJob = null, @pcotype bDocType = null,
    @pco bPCO = null, @pcoitem bPCOItem = null, @callingform tinyint,
    @intext char(1) output, @variance bYN output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @var_item bPCOItem
   
   select @rcode=0, @variance = 'N', @intext = 'E', @msg = ''
   
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
   
   if @callingform not in (1,2) set @callingform = 1
   
   if @pcoitem = '' select @pcoitem = null
   
   
   -- -- -- get internal/external flag from bPMOP
   select @intext=IntExt from bPMOP with (nolock)
   where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
   if @@rowcount = 0 set @intext = 'E'
   
   
   -- -- -- check all item and phases not approved when approving a change order 
   if @callingform = 1
   	begin
   	select @var_item = min(a.PCOItem)
   	from bPMOI a with (nolock)
   	join bPMOL b with (nolock) on b.PMCo=a.PMCo and b.Project=a.Project and b.PCOType=a.PCOType and b.PCO=a.PCO and b.PCOItem=a.PCOItem
   	join bJCJP p with (nolock) on p.JCCo=b.PMCo and p.Job=b.Project and p.Phase=b.Phase and p.Item<>a.ContractItem
   	where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pcotype and a.PCO=@pco and a.ACO is null
   	if @@rowcount <> 0 and @var_item is not null
   		begin
   		select @msg = isnull(@var_item,''), @variance = 'Y'
   		goto bspexit
   		end
   	end
   
   
   -- -- -- check all phases for a item when approving a change order item
   if @callingform = 2
   	begin
   	select @var_item = min(a.PCOItem)
   	from bPMOI a with (nolock)
   	join bPMOL b with (nolock) on b.PMCo=a.PMCo and b.Project=a.Project and b.PCOType=a.PCOType and b.PCO=a.PCO and b.PCOItem=a.PCOItem
   	join bJCJP p with (nolock) on p.JCCo=b.PMCo and p.Job=b.Project and p.Phase=b.Phase and p.Item<>a.ContractItem
   	where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pcotype and a.PCO=@pco 
   	and a.PCOItem=@pcoitem and a.ACO is null
   	if @@rowcount <> 0 and @var_item is not null
   		begin
   		select @msg = isnull(@var_item,''), @variance = 'Y'
   		goto bspexit
   		end
   	end
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOApprovalCheckPhases] TO [public]
GO
