SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPCORetInfoGet    Script Date: 8/28/99 9:32:31 AM ******/
   CREATE proc [dbo].[bspAPCORetInfoGet]
   /********************************************************
   * CREATED BY: 	EN 7/25/97
   * MODIFIED BY:	EN 7/25/97
   *
   * USAGE:
   * 	Retrieves the Retainage Hold Code and Retainage Pay Type from APCO
   *
   * INPUT PARAMETERS:
   *	@apco	AP Company
   *
   * OUTPUT PARAMETERS:
   *	RetHoldCode
   *	RetPayType
   *
   * RETURN VALUE:
   * 	0	Success
   *	1	Failure
   *
   **********************************************************/
   (@apco bCompany=0)
   as 
   set nocount on
   
   	select 	'RetHoldCode'=RetHoldCode, 'RetPayType'=RetPayType
   		from bAPCO where APCo=@apco 
   
   bspexit:

GO
GRANT EXECUTE ON  [dbo].[bspAPCORetInfoGet] TO [public]
GO
