SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMWIAdd    Script Date: 8/28/99 9:36:26 AM ******/
CREATE procedure [dbo].[vspPMImportFormatItem]
/*******************************************************************************
* Created By:  GF 01/25/2000
* Modified By: GF 06/02/2001 - use description from standard item code table if PMUT.UseSICodeDesc = 'Y'
*              bc 09/10/01 - put a Replace statement around @importunits & @importamt
*                            because a customer had commas in their text file
*				GF 01/08/2003 - changed item format to use the bContractItem input mask. Per Hazel conversion
*				GF 07/01/2003 - issue #20656 add increment item by capability.
*				GF 10/24/2003 - issue #21104 SIRegion moved to PMWH from PMWI
*				GF 10/30/2008 - issue #130136 notes changed from varchar(8000) to varchar(max)
*				GP 03/25/2009 - issue 126939, modified procedure to format values, removed insert.
*				GP 10/27/2009 - issue 136329, fixed amount calculation on duplicate item records.
*				GF 12/15/2009 - issue #137070 use SIC description for item when none exists.
*				GF 12/16/2009 - issue #137056 problem with duplicate item when increment by is zero.
*				GF 10/19/2010 - issue #139967 when import item code as SI code was not using import si code
*				GF 01/20/2011 - issue #142984 added check for viewpoint UM default.
*
*
* This SP will creat import work item records.
*
* It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
*
* Pass In
*   PMCo, ImportId, ImportItem, SIRegion, SICode, Description, ImportUM,
*   RetainPCT, Amount, Units, UnitCost, Misc1, Misc2, Misc3
*
* RETURN PARAMS
*   msg           Error Message, or Success message
*
* Returns
*      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
*
********************************************************************************/
(@pmco bCompany, @importid varchar(10), @importitem varchar(30), @siregion varchar(6),
 @sicode varchar(16), @description bItemDesc, @importum varchar(30), @importpct varchar(30),
 @importamt varchar(30), @importunits varchar(30), @importuc varchar(30),
 @importmisc1 varchar(30), @importmisc2 varchar(30), @importmisc3 varchar(30),
 @notes varchar(max), @item bContractItem = null output, @siregion_out varchar(6) = null output, 
 @sicode_out varchar(16) = null output, @retainpct bPct = null output, @amount bDollar = null output, 
 @units bUnits = null output, @unitcost bUnitCost = null output, @um bUM = null output, 
 @sidesc_out bItemDesc = null output, @msg varchar(255) output)
as
set nocount on

   declare @rcode int, @sequence int,  @override bYN, @stdtemplate varchar(10), @itemoption char(1),
   		@importsicode bYN, @initsicode char(1), @defaultsiregion varchar(6), @template varchar(10),
   		@itemformat varchar(10), @itemmask varchar(10), @itemlength varchar(10),
   		@ditem varchar(16), @ium bUM, @iunits bUnits,
   		@iamount bDollar, @isequence int, @usesicodedesc bYN, @sidesc bDesc,
   		@importroutine varchar(20), @scheduleofvalues bYN, @inputmask varchar(30),
   		@incrementby smallint, @pmwh_siregion varchar(6)

   select @rcode=0
   
   If @importid is null
       begin
       select @msg='Missing Import Id', @rcode=1
       goto bspexit
       end
   
   if isnull(@siregion,'') = '' set @siregion = null
   
   select @template=Template, @pmwh_siregion=SIRegion
   from bPMWH with (nolock) where PMCo=@pmco and ImportId=@importid
   if @@rowcount = 0
       begin
       select @msg='Invalid Import Id', @rcode = 1
       goto bspexit
       end
   
   -- get input mask for bContractItem
   select @inputmask = InputMask, @itemlength = convert(varchar(10), InputLength)
   from DDDTShared with (nolock) where Datatype = 'bContractItem'
   if isnull(@inputmask,'') = '' select @inputmask = 'R'
   if isnull(@itemlength,'') = '' select @itemlength = '16'
   if @inputmask in ('R','L')
   	begin
   	select @inputmask = @itemlength + @inputmask + 'N'
   	end
   
   
   select @override=Override, @stdtemplate=StdTemplate, @itemoption=ItemOption,
          @importsicode=ImportSICode, @initsicode=InitSICode, @defaultsiregion=DefaultSIRegion,
          @usesicodedesc=UseSICodeDesc, @importroutine=ImportRoutine, @incrementby=IncrementBy
   from bPMUT with (nolock) where Template=@template
   ---- #137056
   if isnull(@incrementby,0) < 1 set @incrementby = 1
   if isnull(@defaultsiregion,'') = '' set @defaultsiregion = null
   
   select @scheduleofvalues=ScheduleOfValues
   from bPMUI with (nolock) where ImportRoutine=@importroutine
   if @@rowcount = 0 select @scheduleofvalues = 'Y'
   
   -- update SIRegion in PMWH when valid value found
   if isnull(@pmwh_siregion,'') = ''
   	begin
   	set @pmwh_siregion = isnull(@siregion, @defaultsiregion)
   	if @pmwh_siregion is not null
   		update bPMWH set SIRegion = @pmwh_siregion
   		where ImportId=@importid
   	end
   
   
-- set bPMWI parameters and insert record
select @sequence=@incrementby
select @sequence=isnull(Max(Sequence),0)+ @incrementby
from bPMWI with (nolock) where PMCo=@pmco and ImportId=@importid
   
if @importsicode = 'N'
    begin
    select @ditem = rtrim(ltrim(convert(varchar(16),@importitem)))
	exec dbo.bspHQFormatMultiPart @ditem, @inputmask, @item output
----   		if @scheduleofvalues = 'N' set @sicode = null
    end
   
if @importsicode = 'Y'
	begin
	if isnull(@sicode,'') = '' set @sicode=@importitem
	if @initsicode = 'I'
		begin
		select @ditem = rtrim(ltrim(convert(varchar(16),@sequence)))
		exec dbo.bspHQFormatMultiPart @ditem, @inputmask, @item output
		end
	else
		BEGIN
		----#139967
		----set @sicode=@importitem
		select @ditem = rtrim(ltrim(convert(varchar(16),@sicode)))
		exec dbo.bspHQFormatMultiPart @ditem, @inputmask, @item output
		end
	end

   if IsNumeric(@importpct) = 1
        begin
        select @retainpct = convert(decimal(6,4), @importpct)
        end
   else
        begin
        select @retainpct = 0
        end
   
   if @retainpct >= 1
        begin
        select @retainpct = @retainpct / 100
        end
   
   if IsNumeric(@importunits) = 1
        begin
        select @units = convert(decimal(12,3),replace(@importunits,',',''))
       end
   else
        begin
        select @units = 0
        end
   
   if IsNumeric(@importamt) = 1
        begin
        select @amount = convert(decimal(12,2),replace(@importamt,',',''))
        end
   else
        begin
        select @amount = 0
        end
   
   if IsNumeric(@importuc) = 1
        begin
        select @unitcost = convert(decimal(16,5),replace(@importuc,',',''))
        end
   else
        begin
        select @unitcost = 0
        end
   
   if @amount = 0
        begin
        select @amount = @units * @unitcost
        end
   
   
   if @unitcost = 0 and @units <> 0
        begin
        select @unitcost = @amount/@units
        end


exec @rcode = dbo.bspPMImportUMGet @template,@importum,@pmco,@override,@stdtemplate,@um OUTPUT
---- #142984 check for a default value
exec dbo.vspPMImportDefaultValues @template, 'Item', 'UM', @um, @um output, @msg output
if @um='LS' and @units<>0
	begin
	select @units=0, @unitcost=0
	end
   
------ check if duplicate item, if found update amount and units only
----select 'Formatted Item: ',@item, @importitem
----select @item, @description, @um, @units, @amount
--select @isequence=Sequence, @ium=UM, @iamount=Amount, @iunits=Units
--from bPMWI with (nolock) where PMCo=@pmco and ImportId=@importid and Item=@item and ImportItem=@importitem
--if @@rowcount <> 0
--	begin
--   	select @iamount=@iamount+@amount
--   	if @ium=@um select @iunits=@iunits+@units
--   	Update bPMWI SET Amount=@iamount, Units=@iunits
--   	where PMCo=@pmco and ImportId=@importid and Sequence=@isequence
--   	end


select @siregion_out=isnull(@siregion, @defaultsiregion), @sicode_out=@sicode

---- issue #137070
set @sidesc_out = @description
if @importsicode = 'Y' and @sicode_out is not null and @defaultsiregion is not null
	begin
	if isnull(@sidesc_out,'Missing Description') = 'Missing Description'
		begin
		select @sidesc_out = Description
		from dbo.JCSI with (nolock) where SIRegion=@defaultsiregion and SICode=@sicode
		if @@rowcount = 0 set @sidesc_out = @description
		end
	end
	
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportFormatItem] TO [public]
GO
