SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     PROCEDURE [dbo].[vspJCCIBillTypeVal] 
  
  (@jcco bCompany = null, @contract bContract = null, @item bContractItem = null, @errmsg varchar(255) output)
  
  AS
  
  set nocount on
  /***********************************************************
   * CREATED BY: DANF 07/27/2005
   * MODIFIED: 
   *
   * USAGE:
   * validates JC contract item bill type changes
   *
   * INPUT PARAMETERS
   *   JCCo   JC Co to validate against 
   *   Contract  Contract to validate against
   *   Item      Contract item to validate
   *
   * OUTPUT PARAMETERS
   *   @errmsg      error message if error occurs otherwise Description of Contract Item
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  	declare @rcode int, @validcnt int
  	select @rcode = 0
  
--issue 15396
--Changed TV 1/29/03 needs to validate against Item as well
if exists (select top 1 1 from dbo.bJBIT with (nolock) where bJBIT.JBCo = @jcco and bJBIT.Contract = @contract and bJBIT.Item = @item)
	begin
	select @errmsg = 'This item has been previously billed.' + char(13) +char(10) + 'A change to the bill type may result in differences on the Previous Billed amounts in JB.'
	select @rcode = 1
	goto bspexit
	end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCIBillTypeVal] TO [public]
GO
