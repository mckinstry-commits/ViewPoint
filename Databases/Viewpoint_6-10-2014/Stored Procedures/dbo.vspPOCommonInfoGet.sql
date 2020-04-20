SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE                proc [dbo].[vspPOCommonInfoGet]
  /********************************************************
  * CREATED BY: 	kb 6/27/5
  * MODIFIED BY:	GF 05/10/2012 TK-14878 return work flow module active flag
  *               
  *
  * USAGE:
  * 	Retrieves common info from POCO and group stuff for use in various
  *		form's DDFH LoadProc field 
  *
  * INPUT PARAMETERS:
  *	PO Company
  *
  * OUTPUT PARAMETERS:
  *	From APCO
  *	JCCO, EMCO, INCO, GLCO, CMCO, CMACCT, PayCategoryYN,
  *	NetAmtOpt, ICRptYN
  *	From HQCO
  *	VendorGroup, CustGroup, TaxGroup
  *	From PMCO
  *	APVendUpdYN
  *	
  * RETURN VALUE:
  * 	0 	    Success
  *	1 & message Failure
  *
  **********************************************************/
(@co bCompany=0, @jcco bCompany = null output, @emco bCompany = null output,
 @inco bCompany = null output, @glco bCompany = null output,
 @vendorgroup bGroup = null OUTPUT
 ----TK-14878
 ,@WorkFlowActive CHAR(1) = 'Y' OUTPUT)
as 
set nocount ON

declare @rcode int, @opencursor int, @retpaytype INT

SET @rcode = 0
SET @opencursor = 0

-- Get info from APCO
select 	@jcco=JCCo, @emco=EMCo, @inco=INCo, @glco=GLCo
from bAPCO with (nolock) where APCo=@co

-- Get info from HQCO
select  @vendorgroup =VendorGroup from HQCO with (nolock) where HQCo = @co 

---- TK-14878 work flow active
SET @WorkFlowActive = 'Y'
IF EXISTS(SELECT 1 FROM dbo.vDDMO WHERE Mod = 'WF' AND Active = 'N')
	BEGIN
	SET @WorkFlowActive = 'N'
	END
	
  
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPOCommonInfoGet] TO [public]
GO
