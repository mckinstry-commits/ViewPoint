SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
   CREATE  proc [dbo].[bspPMPCOStatusGet]
   /***********************************************************
    * Created By:	GF 11/10/2004
    * Modified By:
    *
    * USAGE:
    *	Gets the pending status for a pending change order.
    *	Called from the bPMOI triggers, returns the pending status to be updated.
    *
    *
    * INPUT PARAMETERS
    *	@pmco		PM Company
    *	@project	PM Project
    *	@pcotype	PM PCO Document type
    *	@pco		PM Pending Change Order
    *	@pcoitem	PM Pending Change Order Item
    *
    * OUTPUT PARAMETERS
    *	@pendingstatus		PM PCO Item's pending status
    *   @msg - error message if error occurs
    *
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/
   (@pmco bCompany = null, @project bJob = null, @pcotype bDocType = null, @pco bPCO = null,
    @pcoitem bPCOItem, @pendingstatus integer, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @pendingstatus = 0
   
   -- -- -- if missing a key value return with error
   if @pmco is null or @project is null or @pcotype is null or @pco is null or @pcoitem is null
   	begin
   	select @msg = 'Missing Key Values!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   
   
   
   
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOStatusGet] TO [public]
GO
