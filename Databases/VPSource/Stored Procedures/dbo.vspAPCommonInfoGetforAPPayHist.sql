SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspAPCommonInfoGetforAPPayHist]
/********************************************************
* CREATED BY: 	DC 01/11/08
* MODIFIED BY:	
               
* USAGE:
* 	Retrieves common info from AP Company for use in APPayHistory
*	form's DDFH LoadProc field 
*
* INPUT PARAMETERS:
*	@co			AP Co#
*
* OUTPUT PARAMETERS:
*	@glco				GL Co#
*	@cmco				CM Co#
*	@vendorgroup		Vendor Group
	@clsdmth			LastMthGLClse from GLCO
*	
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
 (@co bCompany=0,
	@glco bCompany =null output,
	@cmco bCompany =null output,
	@vendorgroup bGroup = null output,
	@clsdmth bMonth = null output, 
	@msg varchar(100) output)

  as 
set nocount on
declare @rcode int
select @rcode = 0 

-- Get info from APCO
select @glco=GLCo, @cmco=CMCo
from APCO with (nolock)
where APCo=@co
if @@rowcount = 0
	begin
	select @msg = 'Company# ' + convert(varchar,@co) + ' not setup in AP', @rcode = 1
	goto vspexit
	end

-- Get info from HQCO
select  @vendorgroup =VendorGroup
from bHQCO with (nolock)
where HQCo = @co 

--Get LastMthGLClse from GLCO
select @clsdmth = LastMthGLClsd
from bGLCO where GLCo = @glco
  
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPCommonInfoGetforAPPayHist] TO [public]
GO
