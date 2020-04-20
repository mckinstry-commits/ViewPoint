SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************* CREATED BY ***********************/
   CREATE proc [dbo].[bspPMPCOContractInfo]
   (@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO, @aco bACO,
    @msg varchar(255) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: GF  02/04/2000
    * MODIFIED BY:
    *
    * USAGE:
    *  Retrieves Contract Projected Close Date for a
    *  pending or approved change order.
    *
    * INPUT PARAMETERS
    *   PMCO    - JC Company
    *   PROJECT - Project
    *   ACO     - Approved Change Order needed to get ACO contract
    *   PCOType - PCO type needed to get pending change order contract
    *   PCO     - Pending change order needed to get contract
    *
    * OUTPUT PARAMETERS
    *  @msg - error message if error occurs or ProjCloseDate
    *
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/
   
    declare @rcode int, @contract bContract
   
    select @rcode = 0, @msg = ''
   
   if @pmco is null
   	begin
   	goto bspexit
   	end
   
   if @project is null
   	begin
   	goto bspexit
   	end
   
   if @aco is not null
      begin
        select @contract = Contract from PMOH with (nolock)
   	 where PMCo = @pmco and Project = @project and ACO = @aco
   
        if @@rowcount = 0 goto pco_contract
   
        if @contract is null goto pco_contract
   
        select @msg = ProjCloseDate from bJCCM with (nolock)
        where JCCo=@pmco and Contract=@contract
   
        if @@rowcount > 0 goto bspexit
      end
   
   pco_contract:
   
   if @pco is not null
      begin
        select @contract = Contract from PMOP with (nolock)
        where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
   
        if @@rowcount =0 goto bspexit
   
        if @contract is null goto bspexit
   
        select @msg = ProjCloseDate from bJCCM with (nolock)
        where JCCo=@pmco and Contract=@contract
      end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOContractInfo] TO [public]
GO
