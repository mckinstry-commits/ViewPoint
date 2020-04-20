SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQCompanyVal    Script Date: 8/28/99 9:34:49 AM ******/
CREATE    proc [dbo].[vspHQCompanyInfoGet]
/********************************
* Created: kb 06/11/03 
* Modified:	
*
* Retrieves all HQ Company Info for all companies and is used in the 
* company object instantiated by a form to hold company info
*
* Input:
*	no inputs
* Output:
*	@msg - errmsg if one is encountered

* Return code:
*	0 = success, 1 = failure
*
*********************************/
	(@msg varchar(60) output)
as
	set nocount on
	declare @rcode int
	select @rcode = 0
	

select HQCo,Name,Address,City,State,Zip,Address2,FedTaxId,
Phone,Fax,VendorGroup,MatlGroup,PhaseGroup,CustGroup,TaxGroup,
EMGroup,Vendor,Customer,AuditCoParams,AuditTax,AuditMatl,
UniqueAttchID,ShopGroup from bHQCO 

if @@rowcount = 0
	begin
	select @msg = 'No HQ Company info!', @rcode = 1
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQCompanyInfoGet] TO [public]
GO
