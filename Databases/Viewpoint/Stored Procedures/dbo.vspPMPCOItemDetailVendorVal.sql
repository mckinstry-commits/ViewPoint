SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE PROC [dbo].[vspPMPCOItemDetailVendorVal]
/***********************************************************
* Created By:	GP 04/05/2011
* Modified By:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
*
* Usage:
*	Used by PMPCOSItemsDetail to validate Vendor. Calls bspAPVendorValForPMMF
*	to handle standard Vendor validation but also adds validtion to check
*	if Vendor belongs to assigned SL or PO.
*
*****************************************************/
(@PMCo bCompany, @Project bProject, @PCOType bPCOType, @PCO bPCO, @PCOItem bPCOItem, 
@PhaseGroup bGroup, @Phase bPhase, @CostType bJCCType, @APCo bCompany, @VendorGroup bGroup,
@Vendor varchar(15), @ActiveOpt char(1) = null, @TypeOpt char(1) = null,
@VendorOut bVendor = null output, @HoldYN bYN = null output, @TaxCode bTaxCode=null output,
@Active bYN = 'Y' output, @msg varchar(255) output)
as
set nocount on
   
declare @rcode int, @SL VARCHAR(30), @PO varchar(30)
select @rcode = 0   

--Validate vendor using previous stored procedure
exec @rcode = dbo.bspAPVendorValForPMMF @PMCo, @Project, @APCo, @VendorGroup, @Vendor, @ActiveOpt, @TypeOpt, 
	@VendorOut output, @HoldYN output, @TaxCode output, @Active output, @msg output
if @rcode = 1	goto vspexit	

--Validate that vendor is assigned to the entered SL or PO
select @SL = Subcontract, @PO = PO
from dbo.PMOL
where PMCo = @PMCo and Project = @Project
	and PCOType = @PCOType and PCO = @PCO 
	and PCOItem = @PCOItem and PhaseGroup = @PhaseGroup 
	and Phase = @Phase and CostType = @CostType

--Check SL vendor
if @SL is not null
begin
	if @VendorOut <> (select Vendor from dbo.SLHD where SLCo = @APCo and SL = @SL and VendorGroup = @VendorGroup)
	begin
		select @msg = 'The Vendor entered does not match the Vendor assigned to the SL.', @rcode = 1
		goto vspexit
	end
end		

--Check PO vendor
if @PO is not null
begin
	if @VendorOut <> (select Vendor from dbo.POHD where POCo = @APCo and PO = @PO and VendorGroup = @VendorGroup)
	begin
		select @msg = 'The Vendor entered does not match the Vendor assigned to the PO.', @rcode = 1
		goto vspexit
	end
end



vspexit:
	return @rcode   
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOItemDetailVendorVal] TO [public]
GO
