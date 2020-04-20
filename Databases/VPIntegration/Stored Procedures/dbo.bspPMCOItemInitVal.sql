SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPMCOItemInitVal]
   /***********************************************************
    * Created By:	GF 12/11/02
    * Modified By:
    *
    * USAGE:
    * Validates PM Pending Change Order Item or Approved Change
    * Order Item. Used in PMChgOrderInit to verify uniqueness.
    *
    * INPUT PARAMETERS
    *	PMCO - JC Company
    *  PROJECT - Project
    *  PCOType - PCO type
    *  PCO - Pending Change Order
    *  PCOItem - PCO Item
    *	ACO		- Approved Change Order
    *	ACOItem	- ACO Item
    *
    * OUTPUT PARAMETERS
    *   @msg - error message if error occurs
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/
   (@pmco bCompany = 0, @project bJob = null, @pcotype bDocType =null, @pco bPCO = null,
    @aco bACO = null, @coitem bPCOItem = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
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
   
   if @coitem is null
   	begin
   	select @msg = 'Missing CO Item!', @rcode = 1
   	goto bspexit
   	end
   
   if @pcotype is null
   	begin
   	select @pco = null
   	-- check ACO
   	if @aco is null
   		begin
   		select @msg = 'Missing ACO!', @rcode = 1
   		goto bspexit
   		end
   	end
   else
   	begin
   	select @aco = null
   	-- check PCO
   	if @pco is null
   		begin
   		select @msg = 'Missing PCO!', @rcode = 1
   		goto bspexit
   		end
   	end
   
   
-- verify that the CO item does not already exist
if @pcotype is null
   	begin
   	select @msg = Description
   	from bPMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@coitem
   	if @@rowcount <> 0
   		begin
   		select @msg = 'ACO Item already exists!', @rcode = 1
   		goto bspexit
   		end
   	end
else
   	begin
   	select @msg = Description
   	from bPMOI with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@coitem
   	if @@rowcount <> 0
   		begin
   		select @msg = 'PCO Item already exists!', @rcode = 1
   		goto bspexit
   		end
   	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMCOItemInitVal] TO [public]
GO
