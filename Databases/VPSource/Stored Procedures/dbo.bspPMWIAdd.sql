SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPMWIAdd    Script Date: 8/28/99 9:36:26 AM ******/
CREATE procedure [dbo].[bspPMWIAdd]
/*******************************************************************************
* Created By:  GF 01/25/2000
* Modified By: GF 06/02/2001 - use description from standard item code table if PMUT.UseSICodeDesc = 'Y'
*              bc 09/10/01 - put a Replace statement around @importunits & @importamt
*                            because a customer had commas in their text file
*				GF 01/08/2003 - changed item format to use the bContractItem input mask. Per Hazel conversion
*				GF 07/01/2003 - issue #20656 add increment item by capability.
*				GF 10/24/2003 - issue #21104 SIRegion moved to PMWH from PMWI
*				GF 10/30/2008 - issue #130136 notes changed from varchar(8000) to varchar(max)
*				GF 01/09/2011 - TK-11535 trim trailing spaces
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
 @notes varchar(max), @msg varchar(255) output)
as
set nocount on
   
   declare @rcode int, @sequence int, @retainpct bPct, @amount bDollar, @units bUnits,
   		@unitcost bUnitCost, @override bYN, @stdtemplate varchar(10), @itemoption char(1),
   		@importsicode bYN, @initsicode char(1), @defaultsiregion varchar(6), @template varchar(10),
   		@itemformat varchar(10), @itemmask varchar(10), @itemlength varchar(10),
   		@ditem varchar(16), @item bContractItem, @um bUM, @ium bUM, @iunits bUnits,
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

----TK-11535 trim trailing spaces
SET @importitem = RTRIM(@importitem)
SET @importpct = RTRIM(@importpct)
SET @importum = RTRIM(@importum)
SET @description = RTRIM(@description)
SET @importamt = RTRIM(@importamt)
SET @importunits = RTRIM(@importunits)
SET @importuc = RTRIM(@importuc)
SET @importmisc1 = RTRIM(@importmisc1)
SET @importmisc2 = RTRIM(@importmisc2)
SET @importmisc3 = RTRIM(@importmisc3)
SET @notes = RTRIM(@notes)


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
   if isnull(@incrementby,0) = 0 select @incrementby = 1
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
		begin
		set @sicode=@importitem
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
   
   exec @rcode = dbo.bspPMImportUMGet @template,@importum,@pmco,@override,@stdtemplate,@um output
   
   if @um='LS' and @units<>0
   	begin
   	select @units=0, @unitcost=0
   	end
   
------ check if duplicate item, if found update amount and units only
----select 'Formatted Item: ',@item, @importitem
----select @item, @description, @um, @units, @amount
select @isequence=Sequence, @ium=UM, @iamount=Amount, @iunits=Units
from bPMWI with (nolock) where PMCo=@pmco and ImportId=@importid and Item=@item and ImportItem=@importitem
if @@rowcount <> 0
	begin
   	select @iamount=@iamount+@amount
   	if @ium=@um select @iunits=@iunits+@units
   	Update bPMWI SET Amount=@iamount, Units=@iunits
   	where PMCo=@pmco and ImportId=@importid and Sequence=@isequence
   	end
else
   	begin
   	----insert_PMWI:
   	insert into dbo.bPMWI (ImportId,Sequence,Item,SIRegion,SICode,Description,UM,RetainPCT,Amount,
   				Units,UnitCost,ImportItem,ImportUM,ImportMisc1,ImportMisc2,ImportMisc3,Errors,
				Notes, PMCo)
   	select @importid,isnull(@sequence,max(i.Sequence)+1),@item,null,@sicode,@description,@um,@retainpct,
        			@amount,@units,@unitcost,@importitem,@importum,@importmisc1,@importmisc2,
        			@importmisc3,Null, @notes, @pmco
    from dbo.bPMWI i with (nolock) where i.PMCo=@pmco and i.ImportId=@importid
   	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWIAdd] TO [public]
GO
