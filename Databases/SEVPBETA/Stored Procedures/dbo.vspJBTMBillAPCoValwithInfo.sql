SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBTMBillAPCoValwithInfo    Script Date: ******/
CREATE Procedure [dbo].[vspJBTMBillAPCoValwithInfo]
/***********************************************************
* CREATED BY: TJL  05/04/06 - Issue #28227, 6x Rewrite JBTMBillLines
* MODIFIED By : 
* 
*
* USAGE:
* validates AP Company number
* 
* INPUT PARAMETERS
*   APCo   AP Co to Validate  
*
* OUTPUT PARAMETERS
*   
*	
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/ 
(@apco bCompany = null, @vendorgroup bGroup output, @matlgroup bGroup output, 
	@msg varchar(60)=null output)
as
   
set nocount on
  
declare @rcode int
select @rcode = 0
   	
if @apco is null
	begin
	select @msg = 'Missing AP Company#', @rcode = 1
	goto vspexit
	end

if not exists(select 1 from APCO with (nolock) where APCo = @apco)
	begin
	select @msg = 'Not a valid AP Company', @rcode = 1
	goto vspexit
	end
else
   	begin
	select @msg = Name, @vendorgroup = VendorGroup, @matlgroup = MatlGroup
	from HQCO with (nolock) 
	where HQCo = @apco
	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBTMBillAPCoValwithInfo] TO [public]
GO
