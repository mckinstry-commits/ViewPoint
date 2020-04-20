SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPCONetAmtOptGet    Script Date: 8/28/99 9:32:30 AM ******/
   CREATE proc [dbo].[bspAPCONetAmtOptGet]
   /********************************************************
   * CREATED BY: 	EN 12/28/00
   * MODIFIED BY:	EN 12/28/00
   *			MV 10/18/02 - 18878 quoted identifier cleanup
   *
   * USAGE:
   * 	Retrieves the NetAmtOpt flag from APCO
   *
   * INPUT PARAMETERS:
   
   *	AP Company
   *
   * OUTPUT PARAMETERS:
   *	NetAmtOpt flag (AP Company file)
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   (@apco bCompany=0, @netamtopt char(1)='N' output)
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   	select 	@netamtopt = NetAmtOpt from bAPCO where APCo=@apco
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPCONetAmtOptGet] TO [public]
GO
