SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMUXCTAdd    Script Date: 8/28/99 9:35:20 AM ******/
CREATE  procedure [dbo].[bspPMUXCTAdd]
/*******************************************************************************
* This SP will create a CostType xref record based on passed parameters.
* Modified By:	GF 06/01/2006 - 6.x changes #27997
*
   *
   * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
   *
   * Pass In
   *   PMCo, ImportId, XrefCode, CostType, OldCostType
   *
   * RETURN PARAMS
   *   msg           Error Message, or Success message
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   *
   ********************************************************************************/
(@pmco bCompany, @importid varchar(10), @xrefcode varchar(30), @xct varchar(30),
 @xoldct varchar(30), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @template varchar(10), @xreftype tinyint,
        @phasegroup bGroup, @matlgroup bGroup, @vendorgroup bGroup,
        @costtype bJCCType, @oldcosttype bJCCType, @apco bCompany

select @rcode=0, @xreftype=1, @xct=rtrim(ltrim(@xct)), @xoldct=rtrim(ltrim(@xoldct))

if IsNumeric(@xct) = 1
	begin
	select @costtype = convert(int,@xct)
	end
else
	begin
	select @costtype = Null
	end


if IsNumeric(@xoldct) = 1
	begin
	select @oldcosttype = convert(int,@xoldct)
	end
else
	begin
	select @oldcosttype = Null
	end

if @oldcosttype = 0 select @oldcosttype = null

------ check importid
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

------ add cost type xref to PMUX if needed
if isnull(@costtype,0) = 0
	begin
	select @msg='Missing Cost Type', @rcode =1
	goto bspexit
	end
else
	begin
	select @validcnt = Count(*) from PMUX with (nolock) 
	where Template=@template and XrefType=@xreftype and XrefCode=@xrefcode
	if @validcnt = 0
		begin
		insert into bPMUX (Template,XrefType,XrefCode,UM,VendorGroup,Vendor,MatlGroup,
   				Material,PhaseGroup,Phase,CostType,CostOnly)
		select @template,@xreftype,@xrefcode,Null,@vendorgroup,Null,
				@matlgroup,Null,@phasegroup,Null,@costtype,'N'
		end
	end


------  update work records
if @oldcosttype is not null
	begin
	Update bPMWD set CostType=@costtype
	where PMCo=@pmco and ImportId=@importid and CostType=@oldcosttype and ImportCostType=@xrefcode
	if @@rowcount<>0 select @rcode=999

	Update bPMWS set CostType=@costtype
	where PMCo=@pmco and ImportId=@importid and CostType=@oldcosttype and ImportCostType=@xrefcode
	if @@rowcount<>0 select @rcode=999

	Update bPMWM set CostType=@costtype
	where PMCo=@pmco and ImportId=@importid and CostType=@oldcosttype and ImportCostType=@xrefcode
	if @@rowcount<>0 select @rcode=999
	end
else
	begin
	Update bPMWD set CostType=@costtype
	where PMCo=@pmco and ImportId=@importid and ImportCostType=@xrefcode and (CostType is null or CostType=0)
	if @@rowcount<>0 select @rcode=999

	Update bPMWS set CostType=@costtype
	where PMCo=@pmco and ImportId=@importid and ImportCostType=@xrefcode and (CostType is null or CostType=0)
	if @@rowcount<>0 select @rcode=999

	Update bPMWM set CostType=@costtype
	where PMCo=@pmco and ImportId=@importid and ImportCostType=@xrefcode and (CostType is null or CostType=0)
	if @@rowcount<>0 select @rcode=999
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMUXCTAdd] TO [public]
GO
