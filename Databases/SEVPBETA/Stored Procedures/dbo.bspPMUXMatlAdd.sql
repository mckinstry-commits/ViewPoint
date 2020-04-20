SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMUXMatlAdd    Script Date: 8/28/99 9:35:20 AM ******/
CREATE   procedure [dbo].[bspPMUXMatlAdd]
/*******************************************************************************
* Modified By:	GF 05/11/2001 - Fix to update matldesc if is null.
*				GF 06/01/2006 - 6.x changes #27997
*	
   *
   * This SP will create a Material xref record based on passed parameters.
   *
   * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
   *
   * Pass In
   *   PMCo, ImportId, XrefCode, Material, OldMaterial
   *
   * RETURN PARAMS
   *   msg           Error Message, or Success message
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   *
   ********************************************************************************/
(@pmco bCompany, @importid varchar(10), @xrefcode varchar(30), @material bMatl,
 @oldmaterial bMatl, @matldesc varchar(60), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @template varchar(10), @xreftype tinyint,
		@phasegroup bGroup, @matlgroup bGroup, @vendorgroup bGroup,
		@apco bCompany

select @rcode=0, @xreftype=3

If @importid is null
	begin
	select @msg='Missing ImportId', @rcode=1
	goto bspexit
	end

------ get PMCO info
select @apco=APCo from PMCO with (nolock) where PMCo=@pmco
if @@rowcount = 0
	begin
	select @msg = 'Invalid PM Company.', @rcode=1
	goto bspexit
	end

------ get HQCO data groups for PM
select @phasegroup=PhaseGroup, @matlgroup=MatlGroup
from HQCO with (nolock) where HQCo=@pmco 
if @@rowcount = 0
	begin
	select @msg='Missing data group for HQ Company ' + convert(varchar(3),@pmco) + '!', @rcode=1
	goto bspexit
	end

------ get HQCO vendor group for APCo
select @vendorgroup=VendorGroup
from HQCO with (nolock) where HQCo=@apco 
if @@rowcount = 0
	begin
	select @msg='Invalid AP Company from PM Company. Cannot get vendor group from HQCO.', @rcode=1
	goto bspexit
	end

------ get PMWH info
select @template=Template from bPMWH with (nolock) where PMCo=@pmco and ImportId=@importid
if @@rowcount = 0
	begin
	select @msg = 'Invalid ImportId', @rcode=1
	goto bspexit
	end

------ validate template
select @validcnt = Count(*) from bPMUT with (nolock) where Template=@template
if @validcnt = 0
	begin
	select @msg='Invalid Template', @rcode = 1
	goto bspexit
	end

------ add material xref to PMUX if needed
if isnull(@material,'') = ''
	begin
	select @msg = 'Missing Material.', @rcode = 1
	goto bspexit
	end
else
	begin
	select @validcnt = Count(*) from bPMUX with (nolock) 
	where Template=@template and XrefType=@xreftype and XrefCode=@xrefcode
	if @validcnt = 0
		begin
		insert into bPMUX (Template,XrefType,XrefCode,UM,VendorGroup,Vendor,MatlGroup,
				Material,PhaseGroup,Phase,CostType,CostOnly)
		select @template,@xreftype,@xrefcode,Null,@vendorgroup,Null,
				@matlgroup,@material,@phasegroup,Null,Null,'N'
		end
   end

------ update work records
if @material is not null
	begin
	Update bPMWM set Material=@material, MatlDescription = isnull(MatlDescription,@matldesc)
	where PMCo=@pmco and ImportId=@importid and Material=@oldmaterial and ImportMaterial=@xrefcode
	if @@rowcount<>0 select @rcode=999
	end
else
	begin
	Update bPMWM set Material=@material, MatlDescription = isnull(MatlDescription,@matldesc)
	where PMCo=@pmco and ImportId=@importid and ImportMaterial=@xrefcode and Material is null
	if @@rowcount<>0 select @rcode=999
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMUXMatlAdd] TO [public]
GO
