SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPOTotalGet    Script Date: 8/28/99 9:35:16 AM ******/
   CREATE   proc [dbo].[bspPMPOTotalGet]
   /********************************************************
   * Created By:   CW  01/01/98
   * Modified By:  GF  11/24/2000  Restrict to not include pending c.o.
   *               GF  12/12/2000  Accumulating PM PO amounts incorrectly
   *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
   *
   * USAGE:
   *   Retrieves the total cost for a Jobs PO. The total for
   *   a purchase order is the sum of the items in POIT and
   *   the items in PMMF.
   *
   * USED IN
   *   PMPOItems
   *
   * INPUT PARAMETERS:
   *   PMCO
   *	PO
   *	PROJECT
   *
   * OUTPUT PARAMETERS:
   *	PO Amount
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   (@poco  bCompany, @pmco bCompany, @project bJob, @po varchar(30), @amount bDollar output,
    @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @amount = 0
   
   if @poco is null
       begin
   	select @msg = 'Missing PO Company', @rcode = 1
   	goto bspexit
   	end
   
   if @po is null
   	begin
   	select @msg = 'Missing PO', @rcode = 1
   	goto bspexit
   	end
   
   if @project is null
   	begin
   	select @msg = 'Missing Project', @rcode = 1
   	goto bspexit
   	end
   
   -- get amount from POIT items
   select @amount = sum(i.CurCost) from bPOHD h
   join bPOIT i on h.POCo=i.POCo and h.PO=i.PO
   where h.POCo=@poco and h.PO=@po
   
   -- now add in PMMF items
   select @amount=isnull(@amount,0) + isnull(sum(Amount),0) from bPMMF
   where PMCo=@pmco and Project=@project and POCo=@poco and PO=@po and InterfaceDate is null
   and ((RecordType='O' and ACO is null) or (RecordType='C' and ACO is not null))
   
   
   
   bspexit:
       if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPOTotalGet] TO [public]
GO
