SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMUXVendorAdd    Script Date: 8/28/99 9:35:21 AM ******/
CREATE   procedure [dbo].[bspPMUXVendorAdd]
/*******************************************************************************
 * This SP will create a Vendor xref record based on passed parameters.
* Modified By:	GF 01/01/2003
*				GF 06/01/2006 - 6.x changes #27997
   *
   * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
   *
   * Pass In
   *   PMCo, ImportId, XrefCode, Vendor, OldVendor	
   * 
   * RETURN PARAMS
   *   msg           Error Message, or Success message
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   *
   ********************************************************************************/
(@pmco bCompany, @importid varchar(10), @xrefcode varchar(30), @xvendor varchar(30),
 @xoldvendor varchar(30), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @template varchar(10), @xreftype tinyint,
		@phasegroup bGroup, @matlgroup bGroup, @vendorgroup bGroup,
		@vendor bVendor, @oldvendor bVendor, @apco bCompany

select @rcode=0, @xreftype=4, @xvendor=rtrim(ltrim(@xvendor)), @xoldvendor=rtrim(ltrim(@xoldvendor))

if IsNumeric(@xvendor) = 1
	begin
	select @vendor = convert(int,@xvendor)
	end
else
	begin
	select @vendor = Null
	end

if IsNumeric(@xoldvendor) = 1
	begin
	select @oldvendor = convert(int,@xoldvendor)
	end
else
	begin
	select @oldvendor = Null
	end

if @oldvendor = 0 select @oldvendor = null

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
select @template=Template from PMWH with (nolock) where PMCo=@pmco and ImportId=@importid
if @@rowcount = 0
	begin
	select @msg = 'Invalid ImportId', @rcode=1
	goto bspexit
	end

------ validate template
select @validcnt = Count(*) from PMUT with (nolock) where Template=@template
if @validcnt = 0 
	begin
	select @msg='Invalid Template', @rcode = 1
	goto bspexit
	end


------ add vendor xref to PMUX if needed
if isnull(@vendor,0) = 0
	begin
	select @msg = 'Missing Vendor.', @rcode = 1
	goto bspexit
	end
else
	select @validcnt = Count(*) from bPMUX with (nolock) 
	where Template=@template and XrefType=4 and XrefCode=@xrefcode
	if @validcnt = 0
		begin
		insert into bPMUX (Template,XrefType,XrefCode,UM,VendorGroup,Vendor,MatlGroup,
				Material,PhaseGroup,Phase,CostType,CostOnly)
		select @template,@xreftype,@xrefcode,Null,@vendorgroup,@vendor,@matlgroup,
			Null,@phasegroup,Null,Null,'N'
		end

------ update work records
if @oldvendor is not null
	begin
	Update bPMWS set Vendor=@vendor
	where PMCo=@pmco and ImportId=@importid and Vendor=@oldvendor and ImportVendor=@xrefcode
	if @@rowcount<>0 select @rcode=999
      
	Update bPMWM set Vendor=@vendor
	where PMCo=@pmco and ImportId=@importid and Vendor=@oldvendor and ImportVendor=@xrefcode
	if @@rowcount<>0 select @rcode=999
	end
else
	begin
	Update bPMWS set Vendor=@vendor
	where PMCo=@pmco and ImportId=@importid and ImportVendor=@xrefcode and isnull(Vendor,0) = 0
	if @@rowcount<>0 select @rcode=999
      
	Update bPMWM set Vendor=@vendor
	where PMCo=@pmco and ImportId=@importid and ImportVendor=@xrefcode and isnull(Vendor,0) = 0
	if @@rowcount<>0 select @rcode=999
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMUXVendorAdd] TO [public]
GO
