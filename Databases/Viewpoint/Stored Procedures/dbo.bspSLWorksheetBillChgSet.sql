SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLWorksheetBillChgSet   */
   CREATE proc [dbo].[bspSLWorksheetBillChgSet]
   /***********************************************************
    * CREATED BY: kb 3/26/00
    * MODIFIED By :  DC 6/29/10 - #135813 - expand subcontract number
    *
    * USAGE:
    *
    * INPUT PARAMETERS
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Routine
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/   
   	(@slco bCompany, @sl VARCHAR(30), --bSL, DC #135813
   	@slitem bItem)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   
   update SLWI set BillChangedYN = 'N' from SLWI i
   join SLWH h on h.SLCo = i.SLCo and h.SL = i.SL
   where i.SLCo = @slco and i.SL = @sl and i.SLItem = @slitem
   and BillChangedYN = 'Y'
   
   select @rcode = 0
   
   bspexit:
   	return

GO
GRANT EXECUTE ON  [dbo].[bspSLWorksheetBillChgSet] TO [public]
GO
