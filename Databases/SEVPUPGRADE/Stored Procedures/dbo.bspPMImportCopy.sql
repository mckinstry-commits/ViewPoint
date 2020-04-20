SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMImportCopy    Script Date: 8/28/99 9:35:12 AM ******/
CREATE procedure [dbo].[bspPMImportCopy]
/*******************************************************************************
 * Created:  10/15/99 GF
 * Modified: 02/14/2000 GF
 *           02/24/2001 DANF Added FixedAmt to PMUT
 *           06/09/2001 - Changed PMUT insert to do seleced columns
 *           04/15/2002 - Added Columns names to insert
 *			07/01/2003 - issue #20656 added column IncrementBy to PMUT
 *			GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
 *			GP 05/13/2009 - 133427 copy PMUR and PMUD records (template detail)
 *
 *
 * This SP will copy Import Templates from one template to another.  Pass in the Source
 * template, Destination template, destination description along with which cross
 * reference files you want to copy.
 *
 * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
 *
 * Pass In
 *   SourceTemplate			Template to copy from
 *   Destinationtmplate		Template to create
 *   DestinationDescription	Template description created
 *   CopyPhases				Copy Cross reference phases
 *   CopyVendors			Copy Cross refernece Vendors
 *   CopyCostTypes			Copy Cross refernece Cost Types
 *   CopyCreateCostTypes	Create Cost Type in destination template
 *   copyunitofMeasure		Copy Cross reference Unit of measures
 *   CopyMaterial			Copy Cross reference Materials
 *   UseStandard			Use standard template values - not used currently
 *	 @pmco					Current PM Company
 *	 @phasegroup			current PM company phase group
 *	 @matlgroup				current PM company material group
 *	 @vendorgroup			current vendor group for PMCO.APCo
 *
 * RETURN PARAMS
 *   msg           Error Message, or Success message
 *
 * Returns
 *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
 *
********************************************************************************/
(@srctemplate varchar(10), @destemplate varchar(10), @desdescription varchar(30),
 @cpyphase bYN, @cpyvendor bYN, @cpycosttype bYN, @cpycreatecosttype bYN,
 @cpyum bYN, @cpymaterial bYN, @usestandard bYN, @pmco bCompany, @phasegroup bGroup,
 @matlgroup bGroup, @vendorgroup bGroup, @msg varchar(255) output)
as
set nocount on

declare @cnt int, @rcode int, @opencursor int, @xreftype tinyint, @xrefcode varchar(30),
		@um bUM, @vendor bVendor, @material bMatl, @phase bPhase, @costtype bJCCType,
		@costonly bYN

select @rcode = 0, @opencursor = 0

-- -- -- check source and destination templates
if @srctemplate is null or @destemplate is null
	begin
	select @msg='Missing Source and/or destination templates.', @rcode=1
	goto bspexit
   	end

-- -- -- check source template is setup
if not exists(select * from PMUT with (nolock) where Template=@srctemplate)
	begin
	select @msg='Source Template ' + isnull(@srctemplate,'') + ' is not setup, cannot copy!',@rcode=1
	goto bspexit
   	end

-- -- -- check destination template is not setup
if exists(select * from PMUT with (nolock) where Template=@destemplate)
	begin
	select @msg='Destination Template ' + isnull(@destemplate,'') + ' is already setup, cannot copy!',@rcode=1
	goto bspexit
   	end

-- -- -- check copying from the same template
if @srctemplate=@destemplate
	begin
	select @msg='The from and to templates are the same, you cannot copy a template onto itself.', @rcode=1
	goto bspexit
	end



Begin Transaction

-- -- -- add PMUT
if not exists(select Template from PMUT with (nolock) where Template=@destemplate)
	begin
   	insert into PMUT (Template, Description, ImportRoutine, Override, StdTemplate, FileType, Delimiter,
			OtherDelim, TextQualifier, ItemOption, AccumCosts, ContractItem, ItemDescription, BegPosition,
			EndPosition, ImportSICode, InitSICode, DefaultSIRegion, LastPartPhase, CreatePhase, CreateCostType,
			CreateVendor, CreateMatl, CreateUM, DefaultContract, DefaultFirm, COItem, CreateSICode,
			CreateSubRecsYN, FixedAmt, DropMatlCode, UseSICodeDesc, RollupMatlCode, UseItemQtyUM, IncrementBy,
			UserRoutine, RecordTypeCol, BegRecTypePos, EndRecTypePos, XMLRowTag, SampleFile, Notes, Copy)
	select @destemplate, @desdescription, ImportRoutine, Override, StdTemplate, FileType, Delimiter,
			OtherDelim, TextQualifier, ItemOption, AccumCosts, ContractItem, ItemDescription, BegPosition,
			EndPosition, ImportSICode, InitSICode, DefaultSIRegion, LastPartPhase, CreatePhase, CreateCostType,
			CreateVendor, CreateMatl, CreateUM, DefaultContract, DefaultFirm, COItem, CreateSICode,
			CreateSubRecsYN, FixedAmt, DropMatlCode, UseSICodeDesc, RollupMatlCode, UseItemQtyUM, IncrementBy,
			UserRoutine, RecordTypeCol, BegRecTypePos, EndRecTypePos, XMLRowTag, SampleFile, Notes, 'Y'
	from PMUT with (nolock) where Template=@srctemplate
   	if @@rowcount = 0
		begin
   		select @msg = 'Unable to add destination template', @rcode=1
   		goto bsperror
   		end
   	end

-- -- -- add PMUR 133427
if not exists(select top 1 1 from PMUR with (nolock) where Template = @destemplate)
begin
	insert into bPMUR (Template, Description, ContractItem, Phase, CostType, SubcontractDetail, MaterialDetail,
		EstimateInfo, ResourceDetail, ContractItemID, PhaseID, CostTypeID, SubcontractDetailID, MaterialDetailID,
		EstimateInfoID, ResourceDetailID)
	select @destemplate, @desdescription, ContractItem, Phase, CostType, SubcontractDetail, MaterialDetail,
		EstimateInfo, ResourceDetail, ContractItemID, PhaseID, CostTypeID, SubcontractDetailID, MaterialDetailID,
		EstimateInfoID, ResourceDetailID 
	from bPMUR with (nolock) where Template = @srctemplate
	if @@rowcount = 0
	begin
	   	select @msg = 'Unable to add PMUR record', @rcode=1
   		goto bsperror
	end
end

-- -- -- add PMUD 133427
if not exists(select top 1 1 from PMUD with (nolock) where Template = @destemplate)
begin
	insert into bPMUD (Template, RecordType, Identifier, Seq, Form, ColumnName, ColDesc, DefaultValue,
		FormatInfo, Required, RecColumn, BegPos, EndPos, ViewpointDefault, ViewpointDefaultValue,
		Datatype, UserDefault, OverrideYN, UpdateKeyYN, UpdateValueYN, ImportPromptYN, XMLTag, Hidden)
	select @destemplate, RecordType, Identifier, Seq, Form, ColumnName, ColDesc, DefaultValue,
		FormatInfo, Required, RecColumn, BegPos, EndPos, ViewpointDefault, ViewpointDefaultValue,
		Datatype, UserDefault, OverrideYN, UpdateKeyYN, UpdateValueYN, ImportPromptYN, XMLTag, Hidden
	from bPMUD with (nolock) where Template = @srctemplate
	if @@rowcount = 0
	begin
	   	select @msg = 'Unable to add PMUD record', @rcode=1
   		goto bsperror	
	end
end 

-- -- -- add PMUX
-- -- -- Xreftype 0 = Phases, 1 = Cost types, 2 = Unit of Measures, 3 = Materials, 4 = Vendors
declare bcPMUX cursor LOCAL FAST_FORWARD
for select XrefType, XrefCode, UM, Vendor, Material, Phase, CostType, CostOnly
from PMUX with (nolock) where Template=@srctemplate

-- -- -- open cursor
open bcPMUX
select @opencursor = 1

-- -- -- loop through xref detail
process_loop:
fetch next from bcPMUX into @xreftype, @xrefcode, @um, @vendor, @material, @phase, @costtype, @costonly
if (@@fetch_status <> 0) goto process_loop_end

-- -- -- only copy xref records where types match copy flags
if @cpyphase <> 'Y' and @xreftype = 0 goto process_loop
if @cpycosttype <> 'Y' and @xreftype = 1 goto process_loop
if @cpyum <> 'Y' and @xreftype = 2  goto process_loop
if @cpymaterial <> 'Y' and @xreftype = 3 goto process_loop
if @cpyvendor <> 'Y' and @xreftype = 4 goto process_loop

-- -- -- insert record into destination template xrefs
insert PMUX (Template, XrefType, XrefCode, UM, VendorGroup, Vendor, MatlGroup, 
			Material, PhaseGroup, Phase, CostType, CostOnly)
select @destemplate, @xreftype, @xrefcode, @um, null, @vendor, null,
			@material, null, @phase, @costtype, @costonly
----select @destemplate, @xreftype, @xrefcode, @um, @vendorgroup, @vendor, @matlgroup,
----			@material, @phasegroup, @phase, @costtype, @costonly


goto process_loop


process_loop_end:
	if @opencursor = 1
		begin
		close bcPMUX
		deallocate bcPMUX
  		select @opencursor = 0
  		end


-- -- -- add PMUC
if @cpycreatecosttype = 'Y'
	begin
   	select @cnt = count(*) from bPMUC with (nolock) where Template = @srctemplate
   	if @cnt>0
		begin
		insert bPMUC (Template, PhaseGroup, CostType, CreateCostType, UseUM, UseUnits, UseHours)
			select @destemplate, @phasegroup, CostType, CreateCostType, UseUM, UseUnits, UseHours
----		select @destemplate, @phasegroup, CostType, CreateCostType, UseUM, UseUnits, UseHours
		from bPMUC with (nolock) where Template = @srctemplate
   		if @@rowcount <> @cnt
   			begin
   			select @msg = 'Unable to add Cost type creations.', @rcode = 1
   			goto bsperror
   			end
   		end
   	end

--Issue 133427
update bPMUT
set Copy = 'N'
where Template = @destemplate

commit transaction



select @msg = 'Source Template: ' + isnull(@srctemplate,'') + ' has been successfully copied to template: ' + isnull(@destemplate,'') + '.'


bspexit:
	if @opencursor = 1
		begin
		close bcPMUX
		deallocate bcPMUX
  		select @opencursor = 0
  		end
	return @rcode

bsperror:
	if @opencursor = 1
		begin
		close bcPMUX
		deallocate bcPMUX
  		select @opencursor = 0
  		end
	rollback transaction
	return @rcode



-------- -- -- PMUT insert generates standards for PMUH & PMUD, if using standards there
-------- -- -- is no needed to delete and replace with override template values
------if @usestandard <> 'Y'
------	begin
------	delete bPMUD from bPMUD where Template=@destemplate
------	delete bPMUH from bPMUH where Template=@destemplate
------
------	-- -- -- add PMUH
------	if not exists(select Template from bPMUH with (nolock) where Template=@destemplate)
------		begin
------		insert bPMUH (ImportRoutine, Template, RecordId, UseYN, ColumnPosition, BegPosition, EndPosition)
------		select @srcimportroutine, @destemplate, RecordId, UseYN, ColumnPosition, BegPosition, EndPosition)
------   		from bPMUH with (nolock) where Template=@srctemplate
------		if @@rowcount = 0
------			begin
------			select @msg='Unable to add destination template record header.', @rcode=1
------			goto bsperror
------			end
------		end
------
------	-- -- -- add PMUD
------	select @cnt = count(*) from bPMUD with (nolock) where Template = @srctemplate
------	if @cnt>0
------		begin
------		insert bPMUD (ImportRoutine, Template, RecordId, FieldName, UseYN, ColumnPosition, 
------			BegPosition, EndPosition, DefaultValue)
------		select @srcimportroutine, @destemplate, RecordId, FieldName, UseYN, ColumnPosition,
------			BegPosition, EndPosition, DefaultValue
------		from bPMUD with (nolock) where Template = @srctemplate
------   		if @@rowcount <> @cnt
------			begin
------			select @msg = 'Unable to add destination template record detail.', @rcode = 1
------			goto bsperror
------			end
------		end
------	end


------if @cpyphase = 'Y'
------	begin
------   	select @cnt = count(*) from bPMUX with (nolock) where Template = @srctemplate and XrefType = 0
------   	if @cnt > 0
------   		begin
------   		insert PMUX (Template, XrefType, XrefCode, UM, VendorGroup, Vendor, MatlGroup, 
------				Material, PhaseGroup, Phase, CostType, CostOnly)
------		select @destemplate, XrefType, XrefCode, UM, VendorGroup, Vendor, MatlGroup,
------				Material, PhaseGroup, Phase, CostType, CostOnly
------		from bPMUX with (nolock) where Template = @srctemplate and XrefType = 0
------   		if @@rowcount <> @cnt
------			begin
------			select @msg = 'Unable to add Cross references Phases.', @rcode = 1
------			goto bsperror
------			end
------		end
------	end
------
------if @cpycosttype = 'Y'
------   	begin
------   	select @cnt = count(*) from bPMUX with (nolock) where Template = @srctemplate and XrefType = 1
------   	if @cnt>0
------   		begin
------   		insert PMUX (Template, XrefType, XrefCode, UM, VendorGroup, Vendor, MatlGroup, 
------				Material, PhaseGroup, Phase, CostType, CostOnly)
------		select @destemplate, XrefType, XrefCode, UM, VendorGroup, Vendor, MatlGroup,
------				Material, PhaseGroup, Phase, CostType, CostOnly
------		from bPMUX with (nolock) where Template = @srctemplate and XrefType = 1
------   		if @@rowcount <> @cnt
------			begin
------   			select @msg = 'Unable to add Cross references Cost Types.', @rcode = 1
------   			goto bsperror
------   			end
------   		end
------   	end
------
------if @cpyum='Y'
------	begin
------	select @cnt = count(*) from bPMUX with (nolock) where Template = @srctemplate and XrefType = 2
------   	if @cnt>0
------		begin
------		insert PMUX (Template, XrefType, XrefCode, UM, VendorGroup, Vendor, MatlGroup, 
------				Material, PhaseGroup, Phase, CostType, CostOnly)
------		select @destemplate, XrefType, XrefCode, UM, VendorGroup, Vendor, MatlGroup,
------				Material, PhaseGroup, Phase, CostType, CostOnly
------		from bPMUX with (nolock) where Template = @srctemplate and XrefType = 2
------   		if @@rowcount <> @cnt
------   			begin
------   			select @msg = 'Unable to add Cross references unit of measures.', @rcode = 1
------   			goto bsperror
------   			end
------   		end
------   	end
------
------if @cpymaterial='Y'
------	begin
------   	select @cnt = count(*) from bPMUX with (nolock) where Template = @srctemplate and XrefType = 3
------   	if @cnt>0
------   		begin
------   		insert PMUX(Template, XrefType, XrefCode, UM, VendorGroup, Vendor, MatlGroup, 
------				Material, PhaseGroup, Phase, CostType, CostOnly)
------		select @destemplate, XrefType, XrefCode, UM, VendorGroup, Vendor, MatlGroup,
------				Material, PhaseGroup, Phase, CostType, CostOnly
------		from bPMUX with (nolock) where Template = @srctemplate and XrefType = 3
------   		if @@rowcount <> @cnt
------   			begin
------   			select @msg = 'Unable to add Cross references Materials.', @rcode = 1
------   			goto bsperror
------   			end
------   		end
------   	end
------
------if @cpyvendor='Y'
------	begin
------	select @cnt = count(*) from bPMUX with (nolock) where Template = @srctemplate and XrefType = 4
------   	if @cnt>0
------		begin
------   		insert PMUX (Template, XrefType, XrefCode, UM, VendorGroup, Vendor, MatlGroup, 
------				Material, PhaseGroup, Phase, CostType, CostOnly)
------		select @destemplate, XrefType, XrefCode, UM, VendorGroup, Vendor, MatlGroup,
------				Material, PhaseGroup, Phase, CostType, CostOnly
------		from bPMUX with (nolock) where Template = @srctemplate and XrefType = 4
------   		if @@rowcount <> @cnt
------   			begin
------   			select @msg = 'Unable to add Cross references Vendors.', @rcode = 1
------   			goto bsperror
------   			end
------   		end
------   	end

GO
GRANT EXECUTE ON  [dbo].[bspPMImportCopy] TO [public]
GO
