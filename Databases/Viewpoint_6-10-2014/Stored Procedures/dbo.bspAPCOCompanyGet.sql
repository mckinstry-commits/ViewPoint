SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPCOCompanyGet    Script Date: 8/28/99 9:32:30 AM ******/
   CREATE  proc [dbo].[bspAPCOCompanyGet]
   /********************************************************
   * CREATED BY: 	KF 3/26/97
   * MODIFIED BY:	KF 3/26/97
   *               kb 4/3/2 - issue #16838
   *
   * USAGE:
   * 	Retrieves the JC Company, EM Company, IN Company, GL Company
   	CM Company from APCO
   *
   * INPUT PARAMETERS:
   
   *	AP Company
   *
   * OUTPUT PARAMETERS:
   *	JCCO, EMCO, INCO, GLCO, CMCO from APCO (AP Company file)
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   (@apco bCompany=0)
   as
   set nocount on
   
   	select 	'JCCo'=JCCo, 'EMCo'=EMCo, 'INCo'=INCo, 'GLCo'=GLCo,
   		'CMCo'=CMCo, 'CMAcct' = CMAcct
   		from bAPCO where APCo=@apco
   
   bspexit:

GO
GRANT EXECUTE ON  [dbo].[bspAPCOCompanyGet] TO [public]
GO
