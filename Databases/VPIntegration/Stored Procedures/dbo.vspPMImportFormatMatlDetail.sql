SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/****** Object:  Stored Procedure dbo.bspPMWMAdd    Script Date: 8/28/99 9:35:23 AM ******/
CREATE  procedure [dbo].[vspPMImportFormatMatlDetail]
/*******************************************************************************
* Created By:   GF 01/25/2000
* Modified By:  GF 04/26/2001 - check for phase with separator attached.
*               GF 06/02/2001 - use addt'l flags in PMUT when loading materials
*                               null out material code if PMUT.DropMatlCode = 'Y'
*                               rollup materials if PMUT.RollupMatlCode = 'Y'
*				GF 10/30/2008 - issue #130136 notes changed from varchar(8000) to varchar(max)
*				GP 03/25/2009 - issue 126939, modified procedure to format values, removed insert.
*				GF 03/12/2010 - issue #138561 do not rollup if import material is null or empty
*				GP 04/27/2010 - Issue 139225 skip insert of records that have been rolled up
*				GF 01/20/2011 - issue #142984 added code to check for um DEFAULT.
*
* This SP will create import work material records.
*
* It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
*
* Pass In
*   PMCo, ImportId, PhaseGroup, MatlGroup, VendorGroup, Item, Phase, CostType,
*   Material, Vendor, UM, MatlDescription, Units, UnitCost, ECM, Amount,
*   Misc1, Misc2, Misc3
*
* RETURN PARAMS
*   msg           Error Message, or Success message
*
* Returns
*      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
*
********************************************************************************/
(@RollUpNow bYN, @pmco bCompany, @importid varchar(10), @phasegroup bGroup, @matlgroup bGroup, @vendorgroup bGroup,
 @importitem varchar(30), @importphase varchar(30), @importcosttype varchar(30),
 @importmatl varchar(30), @importvendor varchar(30), @importum varchar(30), @matldescription bItemDesc,
 @importunits varchar(30), @importuc varchar(30), @ecm bECM, @importamount varchar(30),
 @importmisc1 varchar(30), @importmisc2 varchar(30), @importmisc3 varchar(30), @notes varchar(max), 
 @item bContractItem = null output, @phase bPhase = null output, @material bMatl = null output, 
 @costtype bJCCType = null output, @vendor bVendor = null output, @um bUM = null output, 
 @units bUnits = null output, @unitcost bUnitCost = null output, @amount bDollar = null output,
 @matldesc_out bItemDesc = null output, @RolledUp bYN = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @sequence int,
   		@template varchar(10), @override bYN, @stdtemplate varchar(10), @costonly bYN,
   		@itemoption char(1), @contractitem bContractItem, @iamount bDollar,
		@mdesc bItemDesc, @pdesc bItemDesc, @phasemask varchar(30),
   		@separator varchar(1), @phaselength int, @plen int, @value varchar(1), @newphase varchar(30),
   		@rollupmatlcode bYN, @matlimportoption varchar(1), @matlfound bYN

select @rcode=0

If @importid is null
      begin
      select @msg='Missing Import Id', @rcode=1
      goto bspexit
      end

------ get template from PMWH
select @template=Template from PMWH where PMCo=@pmco and ImportId=@importid
if @@rowcount = 0
      begin
      select @msg='Invalid Import Id', @rcode = 1
      goto bspexit
      end

if @phasegroup is null
      begin
      select @msg = 'Missing Phase Group!', @rcode = 1
      goto bspexit
      end

if @matlgroup is null
      begin
      select @msg = 'Missing Material Group!', @rcode = 1
      goto bspexit
      end

if @vendorgroup is null
      begin
      select @msg = 'Missing Vendor Group!', @rcode = 1
      goto bspexit
      end

------ get phase input mask
select @phasemask=InputMask, @phaselength=Convert(int,InputLength)
from DDDTShared where Datatype='bPhase'
if isnull(@phasemask,'') = '' select @phasemask='5R-3R-3RN'
if isnull(@phaselength,0) = 0 select @phaselength = 20

select @plen = 1
------ Locate multipart seperator
while (len(@phasemask)>=@plen)
	begin
	select @value = substring(@phasemask,@plen,1)
	if @value not like '[A-Za-z0-9]'
		begin
		select @separator = @value
		goto Separator_end
		end
	select @plen = @plen + 1
	end

Separator_end:
------ get template information
select @override=Override, @stdtemplate=StdTemplate, @itemoption=ItemOption,
   	   @contractitem=ContractItem, @rollupmatlcode=RollupMatlCode, @matlimportoption=MatlImportOption
from PMUT where Template=@template
if isnull(@matlimportoption,'') = '' select @matlimportoption = 'N'

------ set bPMWM parameters and insert record
if IsNumeric(@importunits) = 1
	begin
	select @units = convert(decimal(12,3),@importunits)
	end
else 
	begin
	select @units = 0
	end

if IsNumeric(@importamount) = 1
	begin
	select @amount = convert(decimal(12,2),@importamount)
	end
else
	begin
	select @amount = 0
	end

if IsNumeric(@importuc) = 1
	begin
	select @unitcost = convert(decimal(16,5),@importuc)
	end
else
	begin
	select @unitcost = 0
	end

if @amount = 0
	begin
	select @amount = @unitcost * @units
	end

if @unitcost = 0 and @units <> 0
	begin
	select @unitcost = @amount/@units
	end

------ check UM xref
exec @rcode = dbo.bspPMImportUMGet @template,@importum,@pmco,@override,@stdtemplate,@um output
---- #142984 check for a default value
exec dbo.vspPMImportDefaultValues @template, 'MatlDetail', 'UM', @um, @um output, @msg output

------ check CT xref
exec @rcode = dbo.bspPMImportCTGet @template,@phasegroup,@importcosttype,@pmco,@override,
    				@stdtemplate,@costtype output,@costonly output
------ check Material xref
exec @rcode = dbo.bspPMImportMTGet @template,@matlgroup,@importmatl,@pmco,@override,
    				@stdtemplate,@material output,@mdesc output, @matlfound output
------ check Vendor xref
exec @rcode = dbo.bspPMImportVDGet @template,@vendorgroup,@importvendor,@pmco,@override,
    				@stdtemplate,@vendor output

------ get item from PMWI
select @item = isnull(Item,Null)
from PMWI where PMCo=@pmco and ImportId=@importid and ImportItem=@importitem

------ get phase from PMWP
select @phase = isnull(Phase,Null)
from PMWP where PMCo=@pmco and ImportId=@importid and ImportPhase=@importphase
if @@rowcount = 0
	begin
	select @newphase = @importphase + @separator
	select @phase = isnull(Phase,Null)
	from PMWP where PMCo=@pmco and ImportId=@importid and ImportPhase=@newphase
	if @@rowcount <> 0
		begin
		select @importphase = @newphase
		end
	end

------ if missing phase check phase xref
if isnull(@phase, '') = ''
	begin
   	exec @rcode = dbo.bspPMImportPHGet @template, @phasegroup, @importphase, @pmco,
    				   @override, @stdtemplate, @phase output, @pdesc output
	end

------ set material description
if @matldescription is null and @mdesc is not null
	begin
	select @matldescription = @mdesc
	end

if @itemoption='I'
	begin
	select @item=@contractitem, @importitem=@contractitem
	end

if @itemoption='C' or @itemoption='P'
	begin
	select @importitem=@importphase
	end

------ material import option 'Y'=drop all set @material to null
if @matlimportoption = 'Y'
	select @material = null
------ material import option = 'X' and @matlfound = 'N' then no xref or HQMT exists
if @matlimportoption = 'X' and @matlfound = 'N'
	select @material = null

---- #138561
SET @importmatl = LTRIM(RTRIM(@importmatl))
set @RolledUp = 'N'
------ if rolling up material code, try to match record
if @rollupmatlcode = 'Y' AND LTRIM(RTRIM(ISNULL(@importmatl,''))) <> '' and @RollUpNow = 'Y'
	begin
	if exists(select * from bPMWM where PMCo=@pmco and ImportId=@importid and LTRIM(RTRIM(ISNULL(ImportMaterial,''))) <> ''
				and LTRIM(RTRIM(ImportMaterial))=@importmatl and ImportPhase=@importphase and ImportCostType=@importcosttype
				and ImportUM=@importum and UnitCost=@unitcost)
		begin
		Update bPMWM set Units = Units + @units, Amount = Amount + (@units*m.UnitCost)
		from bPMWM m where m.PMCo=@pmco and m.ImportId=@importid and m.ImportMaterial is not null and m.ImportMaterial=@importmatl
		and m.ImportPhase=@importphase and m.ImportCostType=@importcosttype and m.ImportUM=@importum
		--if rolled up, set flag so parent procedure does not insert a record
		if @@rowcount > 0 set @RolledUp = 'Y'
		goto bspexit
		end
	end


select @matldesc_out=@matldescription

------ insert new material record in PMWM
--select @sequence=1
--select @sequence=isnull(Max(Sequence),0)+1 from bPMWM where PMCo=@pmco and ImportId=@importid
--insert into bPMWM (ImportId,Sequence,Item,PhaseGroup,Phase,CostType,MatlGroup,Material,
--				MatlDescription,VendorGroup,Vendor,UM,Units,UnitCost,ECM,Amount,ImportItem,ImportPhase,
--				ImportCostType,ImportMaterial,ImportVendor,ImportUM,ImportMisc1,ImportMisc2,ImportMisc3,Errors, Notes, PMCo)
--select @importid,@sequence,@item,@phasegroup,@phase,@costtype,@matlgroup,@material,
--				@matldescription,@vendorgroup,@vendor,@um,@units,@unitcost,@ecm,@amount,
--				@importitem,@importphase,@importcosttype,@importmatl,@importvendor,@importum,
--				@importmisc1,@importmisc2,@importmisc3,Null, @notes, @pmco


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportFormatMatlDetail] TO [public]
GO
