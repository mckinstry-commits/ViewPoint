SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMWSAdd    Script Date: 8/28/99 9:35:24 AM ******/
CREATE  procedure [dbo].[vspPMImportFormatSubDetail]
/*******************************************************************************
 * Created By:  GF 01/25/2000
 * Modified By: GF 04/26/2001 - check for phase with separator attached.
 *				GF 09/05/2007 - issue #125405 check UM is LS and set units to zero.
*				GF 10/30/2008 - issue #130136 notes changed from varchar(8000) to varchar(max)
 *				GP 03/25/2009 - issue 126939, modified procedure to format values, removed insert.
 *				GF 01/20/2011 - issue #142984 added code to check for um DEFAULT.
 *
 *
 * This SP will create import work subcontract records.
 *
 * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
 *
 * Pass In
 *   PMCo, ImportId, Item, PhaseGroup, VendorGroup, ImportItem, ImportPhase,
 *   ImportCostType, ImportVendor, ImportUM, Description, Units, UnitCost,
 *   ECM, Amount, WCRetgPct
 *
 * RETURN PARAMS
 *   msg           Error Message, or Success message
 *
 * Returns
 *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
 *
 ********************************************************************************/
(@pmco bCompany, @importid varchar(10), @phasegroup bGroup, @vendorgroup bGroup,
 @importitem varchar(30), @importphase varchar(30), @importcosttype varchar(30),
 @importvendor varchar(30), @importum varchar(30), @description bItemDesc,
 @importunits varchar(30), @importuc varchar(30), @ecm bECM, @importamount varchar(30),
 @importpct varchar(30), @importmisc1 varchar(30) = null, @importmisc2 varchar(30) = null,
 @importmisc3 varchar(30) = null, @notes varchar(max), 
 @item bContractItem = null output, @phase bPhase = null output, @costtype bJCCType = null output,
 @wcretgpct bPct = null output, @units bUnits = null output, @unitcost bUnitCost = null output, 
 @amount bDollar = null output, @um bUM = null output, @vendor bVendor = null output, 
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @sequence int,
   		@template varchar(10), @override bYN, @stdtemplate varchar(10), @costonly bYN,
   		@itemoption char(1), @contractitem bContractItem, @iamount bDollar,
   		@pdesc bDesc, @phasemask varchar(30), @separator varchar(1),
   		@phaselength int, @plen int, @value varchar(1), @newphase varchar(30)

select @rcode=0, @item='', @phase='', @um='', @costtype = 0, @vendor = 0

If @importid is null
      begin
      select @msg='Missing Import Id', @rcode=1
      goto bspexit
      end

select @template=Template from bPMWH where PMCo=@pmco and ImportId=@importid
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

if @vendorgroup is null
      begin
      select @msg = 'Missing Vendor Group!', @rcode = 1
      goto bspexit
      end
   
    -- get phase input mask
    select @phasemask=InputMask from DDDTShared where Datatype='bPhase'
    if @phasemask is null or @phasemask='' select @phasemask='5R-3R-3RN'
   
    select @phaselength = Convert(int,InputLength) from DDDTShared where Datatype='bPhase'
    if @phaselength is null or @phaselength=0 select @phaselength=20
   
    select @plen = 1
   
    -- Locate multipart seperator
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
   
    -- get template information
    select @override=Override, @stdtemplate=StdTemplate, @itemoption=ItemOption, @contractitem=ContractItem
    from bPMUT where Template=@template
   
    -- set bPMWS parameters and insert record
   
    if IsNumeric(@importpct) = 1
       begin
       select @wcretgpct = convert(decimal(6,4), @importpct)
       end
    else
       begin
       select @wcretgpct = 0
       end
   
    if @wcretgpct >= 1
       begin
       select @wcretgpct = @wcretgpct / 100
       end
   
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
   
exec @rcode = dbo.bspPMImportUMGet @template,@importum,@pmco,@override,@stdtemplate,@um output
---- #142984 check for a default value
exec dbo.vspPMImportDefaultValues @template, 'SubDetail', 'UM', @um, @um output, @msg output

exec @rcode = dbo.bspPMImportCTGet @template,@phasegroup,@importcosttype,@pmco,@override,
    				@stdtemplate,@costtype output,@costonly output

exec @rcode = dbo.bspPMImportVDGet @template,@vendorgroup,@importvendor,@pmco,@override,
    				@stdtemplate,@vendor output

select @item = isnull(Item,Null)
from PMWI where PMCo=@pmco and ImportId=@importid and ImportItem=@importitem

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
   
    if @phase is null or @phase=''
       begin
       exec @rcode = dbo.bspPMImportPHGet @template,@phasegroup,@importphase,@pmco,
    				   @override,@stdtemplate,@phase output,@pdesc output
       end
   
    if @itemoption='I'
       begin
       select @item=@contractitem, @importitem=@contractitem
       end
   
    if @itemoption='C' or @itemoption='P'
       begin
       select @importitem=@importphase
       end
   
    if @amount = 0 and @units = 0 and @um = 'LS' and @unitcost <> 0
       begin
       select @amount = @unitcost
       select @unitcost = 0
       end

	if @um='LS' and @units <> 0
		begin
		select @units = 0, @unitcost = 0
		end
   

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportFormatSubDetail] TO [public]
GO
