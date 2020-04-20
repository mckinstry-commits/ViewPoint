SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPCOItemCheck    Script Date: 09/10/2004 ******/
  CREATE     proc [dbo].[bspPMPCOItemCheck]
  /***********************************************************
  * Created By:	GF 09/10/2004
  * Modified By:
  *
  * USAGE: Called from PM PCO Totals Zero Out form to check PCO item or all PCO items
  *	to see if any or all are assigned to a approved change order.
  *	An error is returned if any of the following occurs
  *	no company passed
  *	no project passed
  *	no PCO Type passed
  *	no PCO passed
  *	no matching PCO Item found in PMOI if zeroing out an item
  *
  * INPUT PARAMETERS
  *	PMCO- JC Company to validate against
  *	PROJECT- project to validate against
  *	PCOType - PCO type
  *	PCO - Pending Change Order to validate
  *	PCOItem - PCO Item to validate
  *	ZeroOutType - (P)roject, (C)hange order, (I)tem
  *
  * RETURN VALUE
  *   0 - Success
  *   1 - Failure
  *****************************************************/
  (@pmco bCompany = 0, @project bJob = null, @pcotype bDocType =null, @pco bPCO = null,
   @pcoitem bPCOItem = null, @zeroouttype varchar(1), @msg varchar(255) output)
  as
  set nocount on
  
  declare @rcode int, @validcnt int
  
  select @rcode = 0
  
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
  	select @msg = 'Missing PCO!', @rcode = 1
  	goto bspexit
  	end
  
  if @zeroouttype = 'I' and isnull(@pcoitem,'') = ''
  	begin
  	select @msg = 'Missing PCO Item!', @rcode = 1
  	goto bspexit
  	end
  
  if isnull(@pcoitem,'') <> ''
  	begin
  	select @msg = Description from bPMOI with (nolock)
  	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem 
  	end
  
  -- -- -- if project level no PCO or PCO Item check needed
  if @zeroouttype = 'P' goto bspexit
  
  -- -- -- if change order level check to see if any items are not approved
  if @zeroouttype = 'C'
  	begin
  	select @validcnt = count(*) from bPMOI with (nolock)
  	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and isnull(ACO,'') = ''
  	if @validcnt = 0
  		begin
  		select @msg = 'All PCO Items for PCO: ' + @pco + ' are assigned to approved change orders.', @rcode = 1
  		goto bspexit
  		end
  	end
  
  -- -- -- if change order item level check to see it item is approved
  if @zeroouttype = 'I'
  	begin
  	select @validcnt = count(*) from bPMOI with (nolock)
  	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
  	and PCOItem=@pcoitem and isnull(ACO,'') = ''
  	if @validcnt = 0
  		begin
  		select @msg = 'PCO Item: ' + @pcoitem + ' has been approved.', @rcode = 1
  		goto bspexit
  		end
  	end
  
  
  
  
  
  
  bspexit:
  	if @rcode<>0 select @msg = isnull(@msg,'')
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOItemCheck] TO [public]
GO
