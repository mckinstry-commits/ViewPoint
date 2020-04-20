SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMOICalcPendingAmt    Script Date: 8/28/99 9:33:04 AM ******/
CREATE proc [dbo].[bspPMOICalcPendingAmt] 
/***********************************************************
* CREATED BY:	JRE  1/11/98
* MODIFIED By:	GF 10/23/98
*				GF 11/19/2002 - Enhancement for grand total addons. Calculation loop.
*				GF 10/30/2003 - issue #22769 - user grand total include flag when calculating add-ons.
*				GF 02/29/2008 - issue #127195 #127210 changed to use vspPMOACalcs
*
*
* USAGE:
* Calculates the Pending Amount and unit price for a change order item
* 
* INPUT PARAMETERS
*   PMCo	
*   Project
*   PCOType
*   PCO
*   PCOItem
*	
* OUTPUT PARAMETERS
*   PendingAmount
*   Unit Price
*   msg
*
* RETURN VALUE
*   returns 0 if successful, 1 if failure
*****************************************************/ 
   @PMCo bCompany,@Project bJob, @PCOType bDocType, @PCO bPCO, @PCOItem bPCOItem, @msg varchar(255) output
   as
   set nocount on
   
declare @rcode int

set @rcode=0

exec @rcode = dbo.vspPMOACalcs @PMCo, @Project, @PCOType, @PCO, @PCOItem


bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMOICalcPendingAmt] TO [public]
GO
