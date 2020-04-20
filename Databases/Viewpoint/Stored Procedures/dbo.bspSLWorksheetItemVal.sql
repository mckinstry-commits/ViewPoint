SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLWorksheetItemVal    Script Date: 8/28/99 9:33:41 AM ******/
   CREATE  proc [dbo].[bspSLWorksheetItemVal]
   /***********************************************************
    * CREATED BY	: kb 3/26/00
    * MODIFIED BY	:  DC 6/29/10  #135813 - expand subcontract number
    *
    * USAGE:
    *
    * USED IN
    *
    * INPUT PARAMETERS
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of SL, Vendor,
    *   Vendor group,Vendor Name,BackOrdered
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/   
       (@slco bCompany, @sl VARCHAR(30), --bSL, DC #135813
       @slitem bItem, @billchangedyn bYN output, @msg varchar(100) output)
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   if @slco is null
   	begin
   	select @msg = 'Missing SL Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @sl is null
   	begin
   	select @msg = 'Missing SL!', @rcode = 1
   	goto bspexit
   	end
   
   if @slitem is null
   	begin
   	select @msg = 'Missing SL Item#!', @rcode = 1
   	goto bspexit
   	end
   
   select @billchangedyn=BillChangedYN, @msg = LineDesc from SLWI where
       SLCo = @slco and SL = @sl and SLItem = @slitem
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLWorksheetItemVal] TO [public]
GO
