SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPMGetContractItemUP]
   /***********************************************************
    * Created By:  GF 03/30/2000
    * Modified By:
    *
    * USAGE:
    * Extracts OrigUnitPrice from JCCI for a PMCo/Project/PCOType/PCO/PCOItem
    *
    * INPUT PARAMETERS
    *  PMCo
    *  Project
    *  PCOType
    *  PCO
    *  PCOItem
    *
    * OUTPUT PARAMETERS
    *   JCCI.OrigUnitPrice
    *
    * RETURN VALUE
    *   returns OrigUnitPrice
    *****************************************************/
    @pmco bCompany, @project bJob, @pcotype bPCOType, @pco bPCO, @pcoitem bPCOItem,
    @errmsg varchar(255) output
   as
   set nocount on
   
   declare @rcode int, @contract bContract, @item bContractItem
   
   select @rcode = 0
   
   -- get contract from bJCJM
   select @contract=isnull(Contract,'')
   from bJCJM with (nolock) where JCCo=@pmco and Job=@project
   
   -- get contract item from bPMOI
   select @item=isnull(ContractItem,'')
   from bPMOI with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype
   and PCO=@pco and PCOItem=@pcoitem
   
   if isnull(@contract,'') = '' or isnull(@item,'') = ''
       begin
       select @errmsg='0'
       goto bspexit
       end
   
   select @errmsg=convert(varchar(16),isnull(OrigUnitPrice,0))
   from bJCCI with (nolock) where JCCo=@pmco and Contract=@contract and Item=@item
   
   
   bspexit:
       if @rcode<>0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMGetContractItemUP] TO [public]
GO
