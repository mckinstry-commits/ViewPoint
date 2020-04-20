SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMUXXrefNeededCheck   Script Date: 06/02/2006 ******/
CREATE proc [dbo].[vspPMUXXrefNeededCheck]
/*************************************
 * Created By:	GF 06/02/2006 6.x only
 * Modified By:
 *
 * Called from PM Import Edit form on Std Record Before Update to see if 
 * a xref record is needed for any of the different xref types for
 * a PM Work Table Record.
 *
 *
 * Pass:
 * PMCO				PM Company
 * ImportId			PM Import Id
 * WorkTable		PM Import Work Table (PMWI, PMWP, PMWD, PWMS, or PMWM)
 * Sequence			PM Import Work Table Sequence
 * ImportUM			PM Import UM Code
 * ImportPhase		PM Import Phase Code
 * ImportCostType	PM Import Cost Type Code
 * ImportVendor		PM Import Vendor Code
 * ImportMatl		PM Import Matl Code
 * xum				PM Import Edit UM Value
 * xphase			PM Import Edit Phase Value
 * xcosttype		PM Import Edit Cost Type Value
 * xvendor			PM Import Edit Vendor Value
 * xmatl			PM Import Edit Matl Value
 *
 * Returns:
 * Msg			Returns either an error message or successful completed message
 *
 *
 * Success returns:
 *	0 on Success, 1 on ERROR
 *
 * Error returns:
 *  
 *	1 and error message
 **************************************/
(@pmco bCompany = 0, @importid varchar(10) = null, @worktable varchar(10) = null,
 @sequence int = null, @importum varchar(30) = null, @importphase varchar(30) = null,
 @importcosttype varchar(30) = null, @importvendor varchar(30) = null, @importmatl varchar(30) = null,
 @xum bUM = null, @xphase bPhase = null, @xcosttype bJCCType = null, @xvendor bVendor = null,
 @xmatl bMatl = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @validcnt2 int, @opencursor int, @phasegroup bGroup,
		@matlgroup bGroup, @vendorgroup bGroup, @apco bCompany, @template varchar(10),
		@importroutine varchar(20), @oldum bUM, @oldphase bPhase, @oldcosttype bJCCType,
		@oldvendor bVendor, @oldmatl bMatl

select @rcode = 0, @opencursor = 0, @msg = ''

if @pmco is null
	begin
	select @msg = 'Missing PM Company!', @rcode = 1
	goto bspexit
	end

if @importid is null
	begin
	select @msg = 'Missing Import Id!', @rcode = 1
	goto bspexit
	end

if @worktable not in ('PMWI','PMWP','PMWD','PMWS','PMWM')
	begin
	select @msg = 'Invalid work table!', @rcode = 1
	goto bspexit
	end

------ get phase group from HQCO
select @phasegroup=PhaseGroup, @matlgroup=MatlGroup from HQCO where HQCo=@pmco
if @@rowcount = 0
	begin
	select @msg = 'Invalid HQ Company, cannot find phase group.', @rcode = 1
	goto bspexit
	end

------ get PMCO.APCo
select @apco = APCo from PMCO where PMCo=@pmco
if @@rowcount = 0 select @apco = @pmco

------ get vendor group from HQCO
select @vendorgroup=VendorGroup from HQCO where HQCo=@apco
if @@rowcount = 0
	begin
	select @msg = 'Invalid HQ Company, cannot find vendor group.', @rcode = 1
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

------ get PMWI work table record info
if @worktable = 'PMWI'
	begin
	select @oldum=UM
	from PMWI where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
	------ does not exist in PMWI
	if @@rowcount = 0 goto bspexit
	------ old um = new um then no change. done
	if @oldum = @xum goto bspexit
	end

------ get PMWP work table record info
if @worktable = 'PMWP'
	begin
	select @oldphase=Phase
	from PMWP where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
	------ does not exist in PMWP
	if @@rowcount = 0 goto bspexit
	------ if old phase = new phase then no change. done
	if @oldphase = @xphase goto bspexit
	end

------ get PMWD work table record info
if @worktable = 'PMWD'
	begin
	select @oldphase=Phase, @oldcosttype=CostType, @oldum=UM
	from PMWD where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
	------ does not exist in PMWD
	if @@rowcount = 0 goto bspexit
	------ if old = new phase then no change. done
	if isnull(@xphase,'') <> '' and @oldphase = @xphase goto bspexit
	------ if old = new cost type then no change. done
	if isnull(@xcosttype,0) <> 0 and @oldcosttype = @xcosttype goto bspexit
	------ if old = new um then no change. done
	if isnull(@xum,'') <> '' and @oldum = @xum goto bspexit
	end

------ get PMWS work table record info
if @worktable = 'PMWS'
	begin
	select @oldphase=Phase, @oldcosttype=CostType, @oldum=UM, @oldvendor=Vendor
	from PMWS where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
	------ does not exist in PMWS
	if @@rowcount = 0 goto bspexit
	------ if old = new phase then no change. done
	if isnull(@xphase,'') <> '' and @oldphase = @xphase goto bspexit
	------ if old = new cost type then no change. done
	if isnull(@xcosttype,0) <> 0 and @oldcosttype = @xcosttype goto bspexit
	------ if old = new um then no change. done
	if isnull(@xum,'') <> '' and @oldum = @xum goto bspexit
	------ if old = new vendor then no change. done
	if isnull(@xvendor,'') <> '' and @oldvendor = @xvendor goto bspexit
	end

------ get PMWM work table record info
if @worktable = 'PMWM'
	begin
	select @oldphase=Phase, @oldcosttype=CostType, @oldum=UM, @oldvendor=Vendor, @oldmatl=Material
	from PMWM where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
	------ does not exist in PMWM
	if @@rowcount = 0 goto bspexit
	------ if old = new phase then no change. done
	if isnull(@xphase,'') <> '' and @oldphase = @xphase goto bspexit
	------ if old = new cost type then no change. done
	if isnull(@xcosttype,0) <> 0 and @oldcosttype = @xcosttype goto bspexit
	------ if old = new um then no change. done
	if isnull(@xum,'') <> '' and @oldum = @xum goto bspexit
	------ if old = new vendor then no change. done
	if isnull(@xvendor,'') <> '' and @oldvendor = @xvendor goto bspexit
	------ if old = new material then no change. done
	if isnull(@xmatl,'') <> '' and @oldmatl = @xmatl goto bspexit
	end




------ check UM xref - if @importum does not exist in PMUX then may need to create xref
if isnull(@xum,'') <> '' and isnull(@importum,'') <> ''
	begin
	------ if @oldum is valid and new um is valid then just changing um, xref is not needed
	if isnull(@oldum,'') <> ''
		begin
		select @validcnt = count(*) from HQUM with (nolock) where UM=@oldum
		select @validcnt2 = count(*) from HQUM with (nolock) where UM=@xum
		if @validcnt <> 0 and @validcnt2 <> 0 goto bspexit
		end

	------ check if import um already exists, if found then done
	if not exists(select * from PMUX with (nolock) where Template=@template and XrefType=2 and XrefCode=@importum)
		begin
		select @msg = 'UM Xref needed.', @rcode = 99
		goto bspexit
		end
	else
		begin
		select @msg = '', @rcode = 0
		goto bspexit
		end
	end


------ check Phase xref - if @importphase does not exist in PMUX then may need to create xref
if isnull(@xphase,'') <> '' and isnull(@importphase,'') <> ''
	begin
	------ if @oldphase is valid and new phase is valid then just changing phase, xref is not needed
	if isnull(@oldphase,'') <> ''
		begin
		select @validcnt = count(*) from JCPM with (nolock) where PhaseGroup=@phasegroup and Phase=@oldphase
		select @validcnt2 = count(*) from JCPM with (nolock) where PhaseGroup=@phasegroup and Phase=@xphase
		if @validcnt <> 0 and @validcnt2 <> 0 goto bspexit
		end

	------ check if import phase already exists, if found then done
	if not exists(select * from PMUX with (nolock) where Template=@template and XrefType=0 and XrefCode=@importphase)
		begin
		select @msg = 'Phase Xref needed.', @rcode = 99
		goto bspexit
		end
	else
		begin
		select @msg = '', @rcode = 0
		goto bspexit
		end
	end


------ check CostType xref - if @importcosttype does not exist in PMUX then may need to create xref
if isnull(@xcosttype,0) <> 0 and isnull(@importcosttype,'') <> ''
	begin
	------ if @oldcosttype is valid and new cost type is valid then just changing cost type, xref is not needed
	if isnull(@oldcosttype,0) <> 0
		begin
		select @validcnt = count(*) from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@oldcosttype
		select @validcnt2 = count(*) from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@xcosttype
		if @validcnt <> 0 and @validcnt2 <> 0 goto bspexit
		end

	------ check if import costtype already exists, if found then done
	if not exists(select * from PMUX with (nolock) where Template=@template and XrefType=1 and XrefCode=@importcosttype)
		begin
		select @msg = 'CostType Xref needed.', @rcode = 99
		goto bspexit
		end
	else
		begin
		select @msg = '', @rcode = 0
		goto bspexit
		end
	end


------ check Vendor xref - if @importvendor does not exist in PMUX then may need to create xref
if isnull(@xvendor,'') <> '' and isnull(@importvendor,'') <> ''
	begin
	------ if @oldvendor is valid and new vendor is valid then just changing vendor, xref is not needed
	if isnull(@oldvendor,'') <> ''
		begin
		select @validcnt = count(*) from APVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@oldvendor
		select @validcnt2 = count(*) from APVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@xvendor
		if @validcnt <> 0 and @validcnt2 <> 0 goto bspexit
		end

	------ check if import vendor already exists, if found then done
	if not exists(select * from PMUX with (nolock) where Template=@template and XrefType=4 and XrefCode=@importvendor)
		begin
		select @msg = 'Vendor Xref needed.', @rcode = 99
		goto bspexit
		end
	else
		begin
		select @msg = '', @rcode = 0
		goto bspexit
		end
	end


------ check Material xref - if @importmatl does not exist in PMUX then may need to create xref
if isnull(@xmatl,'') <> '' and isnull(@importmatl,'') <> ''
	begin
	------ if @oldmatl is valid and new material is valid then just changing material, xref is not needed
	if isnull(@oldmatl,'') <> ''
		begin
		select @validcnt = count(*) from HQMT with (nolock) where MatlGroup=@matlgroup and Material=@oldmatl
		select @validcnt2 = count(*) from HQMT with (nolock) where MatlGroup=@matlgroup and Material=@xmatl
		if @validcnt <> 0 and @validcnt2 <> 0 goto bspexit
		end

	------ check if import material already exists, if found then done
	if not exists(select * from PMUX with (nolock) where Template=@template and XrefType=3 and XrefCode=@importmatl)
		begin
		select @msg = 'Material Xref needed.', @rcode = 99
		goto bspexit
		end
	else
		begin
		select @msg = '', @rcode = 0
		goto bspexit
		end
	end



select @msg = '', @rcode = 0























bspexit:
	if @opencursor = 1
		begin
		close bcPMWX
		deallocate bcPMWX
  		select @opencursor = 0
  		end

	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMUXXrefNeededCheck] TO [public]
GO
