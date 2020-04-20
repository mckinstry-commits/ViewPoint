SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspHQMatlValForPMOL    Script Date: 8/28/99 9:36:18 AM ******/
CREATE      proc [dbo].[vspHQMatlValForPMOL]
/********************************************************
* CREATED BY: 	JG	06/23/2011 - TK-06041 - Added for validation PMOL and returning info
* MODIFIED BY:	
*
* USAGE:
* 	TODO: Modify - Retrieves the Purchasing Price, Purchasing UM, and ECM for a Material from bHQMT
*
* INPUT PARAMETERS:
*
* OUTPUT PARAMETERS:
*
* RETURN VALUE:
* 	0 	    Success
*	1		Message Failure
*
**********************************************************/
(@pmco bCompany=0, @matlgroup bGroup=0, @material bMatl=null, @project bJob=null, @vendorgroup bGroup = null, @vendor bVendor = null, 
----OUTPUTS
 @unitcost bUnitCost output, @ecm bECM=null output, @um bUM output,
 @phase bPhase output, @ct bJCCType output,
 @msg varchar(255) output)
as
set nocount on
   
declare @rcode int, @matldesc bItemDesc, @basetaxon varchar(1)

select @rcode = 0, @phase = NULL, @ct = NULL
   
   
if @matlgroup= 0
	begin
	select @msg = 'Missing HQ Material Group', @rcode = 1
	goto bspexit
	end

if @material is null
	begin
	select @msg = 'Missing HQ Material', @rcode = 1
	goto bspexit
	end
   
EXEC	@rcode = bspHQMatlValForPM
		@pmco = @pmco,
		@matlgroup = @matlgroup,
		@material = @material,
		@project = @project,
		@vendorgroup = @vendorgroup,
		@vendor = @vendor,			
		@price = @unitcost OUTPUT,
		@stdum = NULL,
		@PriceECM = @ecm OUTPUT,
		@stdcost = NULL,
		@purchaseum = @um OUTPUT,
		@salesum = NULL,
		@phase = @phase OUTPUT,
		@ct = @ct OUTPUT,
		@stocked = NULL,
		@taxcode = NULL,
		@salescost = NULL,
		@ecm = NULL,
		@taxable = NULL,
		@ValidMaterial = NULL,
		@msg = @msg OUTPUT
		
		
	IF @rcode <> 0
	BEGIN
		goto bspexit 
	END
		
   
   bspexit:
    	if @rcode <> 0 select @msg = @msg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQMatlValForPMOL] TO [public]
GO
