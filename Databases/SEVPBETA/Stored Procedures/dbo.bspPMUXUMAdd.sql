SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMUXUMAdd    Script Date: 8/28/99 9:35:21 AM ******/
CREATE   procedure [dbo].[bspPMUXUMAdd]
/*******************************************************************************
* This SP will create a UM xref record based on passed parameters.
* Modified By:	GF 06/01/2006 - 6.x changes #27997
*				GF 12/26/2007 - issue #126588 add PMUX if needed, then update detail.
*
   *
   * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
   *
   * Pass In
   *   PMCo, ImportId, XrefType, XrefCode, UM, OldUM	
   * 
   * RETURN PARAMS
   *   msg           Error Message, or Success message
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   *
   ********************************************************************************/
(@pmco bCompany, @importid varchar(10), @xrefcode varchar(30), @um bUM, @oldum bUM,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @template varchar(10), @xreftype tinyint,
		@phasegroup bGroup, @matlgroup bGroup, @vendorgroup bGroup,
		@apco bCompany

select @rcode=0, @xreftype=2

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

------ Validate template
select @validcnt = Count(*) from PMUT with (nolock) where Template=@template
if @validcnt = 0 
	begin
	select @msg='Invalid Template', @rcode = 1
	goto bspexit
	end

------ add um xref to PMUX if needed
if isnull(@um,'') = ''
	begin
	select @msg='Missing UM', @rcode =1
	goto bspexit
	end


------ have a UM now check to see if a xref is needed. 
if not exists(select UM from bPMUX where Template=@template and XrefType=@xreftype and XrefCode=@xrefcode)
	begin
	insert into bPMUX (Template,XrefType,XrefCode,UM,VendorGroup,Vendor,MatlGroup,
			Material,PhaseGroup,Phase,CostType,CostOnly)
	select @template,@xreftype,@xrefcode,@um,@vendorgroup,Null,@matlgroup,
			Null,@phasegroup,Null,Null,'N'
	end

------ update work records
Update bPMWI set UM=@um
where PMCo=@pmco and ImportId=@importid and UM=@oldum and ImportUM=@xrefcode
if @@rowcount<>0 select @rcode=999

Update bPMWD set UM=@um
where PMCo=@pmco and ImportId=@importid and UM=@oldum and ImportUM=@xrefcode
if @@rowcount<>0 select @rcode=999

Update bPMWS set UM=@um
where PMCo=@pmco and ImportId=@importid and UM=@oldum and ImportUM=@xrefcode
if @@rowcount<>0 select @rcode=999

Update bPMWM set UM=@um
where PMCo=@pmco and ImportId=@importid and UM=@oldum and ImportUM=@xrefcode
if @@rowcount<>0 select @rcode=999 




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMUXUMAdd] TO [public]
GO
