SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMCOCompanyGet    Script Date: 8/28/99 9:32:37 AM ******/
   CREATE proc [dbo].[bspCMCOCompanyGet]
   /********************************************************
   * CREATED BY: 	KF 5/30/97
   * MODIFIED BY:	KF 5/30/97
   *
   * USAGE:
   * 	Retrieves the CM Company from APCO
   *
   * INPUT PARAMETERS:
   
   *	AP Company
   *
   * OUTPUT PARAMETERS:
   *	CMCo from APCO (AP Company file)
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   (@apco bCompany=0)
   as 
   set nocount on
   
   
   
   	select 	'CMCo'=CMCo
   		from bAPCO where APCo=@apco 
   
   bspexit:

GO
GRANT EXECUTE ON  [dbo].[bspCMCOCompanyGet] TO [public]
GO
