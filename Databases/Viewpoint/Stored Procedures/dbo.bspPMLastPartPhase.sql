SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/******************************************************/
CREATE procedure [dbo].[bspPMLastPartPhase]
/*******************************************************************************
 * Created By:	GF 08/12/1999
 * Modified By:	TV 02/01/2001 - fix for if last part phase code > 2 chars
 *				GF 10/11/2001 - more problems with last part phase.
 *				GF 09/19/2002 - more problems with phase format. HQMultipart is broken.
 *				GF 03/05/2003 - issue #20549 - consider import item when looking for duplicate
 *								phase cost types and not creating last part phase.
 *				GF 07/26/2005 - issue #29394 after creating phases need to check for create cost types.
 *				GF 08/24/2005 - issue #29400 moved the create and subcontract cost type create moved here from
 *								bspPMWDTrans to be done as the last piece before import complete.
 *				GF 04/13/2006 - issue #120807 changed logic when creating subcontract records.
 *									Will now only insert if not exists. No more updating existing.
 *				GF 10/16/2007 - issue #125191 change for new last part phase option 'S' when subcontract
 *								detail exists. this was a 5.x custom for Brannan. Std for 6.1
 *				GF 06/13/2008 - issue #128666 goto labels were going to wrong position. Last part phase when only subct cost types
 *				GF 11/03/2008 - issue #130893 added check for unique phase option when checking for orphans
 *				GF 12/18/2008 - issue #131418 try to find cost type flags from JCPC when creating cost types.
 *				GF 04/01/2009 - issue #132905 problem with creating last part phase when using 'S' option
 *				GF 07/25/2009 - issue #129667 use material cost type 2
 *				GF 07/27/2010 - issue #140742 if using always option for last part phase, clean up phases when done creating
 *				GF 01/08/2011 - TK-11535 trim trailing spaces from phase
 *
 *
 *
 *
 *
 * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
 *
 * Pass In
 *   PMCo, ImportId
 *
 * RETURN PARAMS
 *   msg           Error Message, or Success message
 *
 * Returns
 *
 * STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
 *
 ********************************************************************************/
(@pmco bCompany, @importid varchar(10), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @sequence int, @template varchar(10), @validcnt int, @separator char(1),
  		@phase bPhase, @item bContractItem, @part varchar(20), @phasemask varchar(30),
  		@revmask varchar(30), @phaselength int, @lastpartphase char(1), @lenpart int,
  		@plen int, @validpart int, @revpart varchar(2), @itemvalue varchar(20),
  		@seqnvalue int, @phasepart varchar(20), @newphase bPhase, @pphase bPhase,
  		@isequence int, @vitem bContractItem, @vphase bPhase, @dsequence int,
  		@costtype bJCCType, @um bUM, @units bUnits, @hours bHrs, @costs bDollar,
  		@dum bUM, @dunits bUnits, @dhours bHrs, @dcosts bDollar, @importcosttype varchar(30),
  		@dimportcosttype varchar(30), @value int, @partlen int, @charvalue varchar(1),
  		@formphase bPhase, @importitem varchar(30), @phasegroup bGroup, @vendorgroup bGroup,
  		@validphasechars int, @createsubrecs bYN, @slcosttype bJCCType, @slcosttype2 bJCCType,
  		@slct1option tinyint, @override bYN, @stdtemplate varchar(10), @useitemqtyum bYN,
  		@openPMWD tinyint, @importphase varchar(30), @importum varchar(30),
  		@slunits bUnits, @slcosts bDollar, @valcount int, @unitcost bUnitCost,
  		@wcretgpct bPct, @useum bYN, @useunits bYN, @usehours bYN, @createcosttype bJCCType,
  		@billflag char(1), @itemunitflag bYN, @phaseunitflag bYN, @slum bUM,
  		@slunitcost bUnitCost, @matlgroup bGroup, @apco bCompany, @openPMWP tinyint,
		@userroutine varchar(30), @phasesubct_exists bYN, @ph_keyid bigint,
		@ict_keyid bigint, @dct_keyid bigint, @ct_um bUM, @ct_billflag char(1),
		@ct_itemunitflag bYN, @ct_phaseunitflag bYN, @multiple_rows tinyint,
		@matlcosttype2 bJCCType, @matlcosttype bJCCType

select @rcode=0, @lenpart=0, @plen=1, @validpart=0, @part='', @separator='',
	   @openPMWD = 0, @openPMWP = 0

If @importid is null
	begin
	select @msg = 'Missing Import Id', @rcode=1
	goto bspexit
	end

------ validate template
select @template=Template from PMWH with (nolock) where PMCo=@pmco and ImportId=@importid
if @@rowcount = 0
  	begin
  	select @msg = 'Invalid Import Id', @rcode = 1
  	goto bspexit
  	end
  
------ get phase group and material group
select @phasegroup=PhaseGroup, @matlgroup=MatlGroup
from HQCO with (nolock) where HQCo=@pmco
if @@rowcount = 0
	begin
  	select @msg='Missing HQ Company, cannot get phase group!', @rcode=1
  	goto bspexit
  	end

------ get PM Company info
select @apco=APCo, @slcosttype=SLCostType, @slcosttype2=SLCostType2,
	   @slct1option=SLCT1Option, @matlcosttype=MtlCostType, @matlcosttype2=MatlCostType2
from PMCO with (nolock) where PMCo=@pmco
if @@rowcount = 0 
	begin
	select @apco=@pmco, @createsubrecs = 'N'
	end

------ get vendor group from HQCO
select @vendorgroup=VendorGroup from HQCO where HQCo=@apco
if @@rowcount = 0
	begin
  	select @msg='Missing HQ Company, cannot get phase group!', @rcode=1
  	goto bspexit
  	end

------ get template information
select @lastpartphase=isnull(LastPartPhase,'D'), @override=Override, @stdtemplate=StdTemplate,
		@createsubrecs=CreateSubRecsYN, @useitemqtyum=UseItemQtyUM, @userroutine=UserRoutine
from PMUT with (nolock) where Template=@template
if isnull(@lastpartphase,'') = '' select @lastpartphase='D'

------- get valid portion of phase
select @validphasechars = ValidPhaseChars from JCCO where JCCo = @pmco
if @@rowcount = 0 select @validphasechars = 0

------- get WCRetgPct from bPMWI
select top 1 @wcretgpct=RetainPCT
from bPMWI where PMCo=@pmco and ImportId=@importid and Item=@item
group by PMCo, ImportId, Item, RetainPCT
if isnull(@wcretgpct,0) = 0 select @wcretgpct = 0

------ get phase DD format
select @phasemask=InputMask, @phaselength=convert(int,InputLength)
from DDDTShared with (nolock) where Datatype='bPhase'
if isnull(@phasemask,'') = '' select @phasemask='5R-3R-3RN'
if isnull(@phaselength,0) = 0 select @phaselength=20
select @revmask= Reverse(@phasemask)
------ Locate multipart seperator
while (len(@revmask)>=@plen)
	begin
  	select @charvalue = substring(@revmask,@plen,1)
  	if @charvalue not like '[A-Za-z0-9]'
  		begin
  		select @separator = @charvalue, @plen = 20
  		end
  		select @plen = @plen + 1
	end

select @partlen = charindex(@separator,@revmask)
select @part = reverse(substring(@revmask,1,@partlen-1))
select @plen=1, @value = 0

while len(@part) >= @plen
	begin
	if substring(@part,@plen,1) like '[0-9]'
		begin
		if substring(@part,@plen+1,1) like '[0-9]'
			begin
			select @value = @value + convert(int, substring(@part,@plen,2))
			select @plen = @plen + 1
			end
		else
			begin
			select @value = @value + convert(int, substring(@part,@plen,1))
			end
		end
	select @plen = @plen+1
	end

if isnull(@value,0) = 0 goto Part_Two_Create_Costtypes
select @lenpart = @value
if @separator = '' select @separator = '-'


if @lastpartphase <> 'S' goto old_no_unique_codes

---- need to check if we have multiple SL Cost Types for phases
if isnull(@slcosttype,'') <> ''	
	begin
	if exists(select top 1 1 from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid and CostType=@slcosttype)
		begin
		set @multiple_rows = 1
		end
	end
---- check if second SLCostType exists in PMWD for phase
if isnull(@slcosttype2,'') <> ''
	begin
	if exists(select top 1 1 from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid and CostType=@slcosttype2)
		begin
		set @multiple_rows = 1
		end
	end

---- create cursor on PMWP to rollup phases, costs, subcontract, and materials if needed
declare bcPMWP cursor LOCAL FAST_FORWARD 
	for select Sequence, Phase, Item, ImportItem, ImportPhase, KeyID
from bPMWP a where PMCo=@pmco and ImportId=@importid and isnull(Phase,'') <> ''

open bcPMWP
select @openPMWP = 1

LastPartPhaseSubctOption_loop:
fetch next from bcPMWP into @sequence, @phase, @item, @importitem, @importphase, @ph_keyid

if @@fetch_status = -1 goto LastPartPhaseSubctOption_end
if @@fetch_status <> 0 goto LastPartPhaseSubctOption_loop

if @multiple_rows = 0
	begin
	---- check if duplicate phases
	if not exists(select * from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Phase=@phase and KeyID<>@ph_keyid)
		begin
		goto LastPartPhaseSubctOption_loop
		end
	end

---- set items in PMWD, PMWM, PMWS to phase item
--Update bPMWD set Item=@item
--where PMCo=@pmco and ImportId=@importid and Phase=@phase
--Update bPMWM set Item=@item
--where PMCo=@pmco and ImportId=@importid and Phase=@phase
--Update bPMWS set Item=@item
--where PMCo=@pmco and ImportId=@importid and Phase=@phase

select @phasesubct_exists = 'N'
---- check if only when phase sub cost type exists flag
---- check if first SLCostType exists in PMWD for phase
if isnull(@slcosttype,'') <> ''	
	begin
	if exists(select top 1 1 from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid
				and ImportPhase=@importphase and CostType=@slcosttype)
		begin
		select @phasesubct_exists = 'Y'
		end
	end
---- check if second SLCostType exists in PMWD for phase
if isnull(@slcosttype2,'') <> ''
	begin
	if exists(select top 1 1 from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid
				and ImportPhase=@importphase and CostType=@slcosttype2)
		begin
		select @phasesubct_exists = 'Y'
		end
	end

---- if we do not have any subcontract cost type then no need to create last part phase
if @phasesubct_exists = 'N'
	begin
	goto LastPartPhaseSubctOption_loop
	end
else
	begin
	delete from bPMWP
	where PMCo=@pmco and ImportId=@importid and Phase=@phase and Item=@item and KeyID<>@ph_keyid 
	end


---- create cursor on PMWD to accumulate duplicate cost types
declare bcPMWD cursor LOCAL FAST_FORWARD for
		select Sequence, CostType, UM, Units, Hours, Costs, ImportCostType, KeyID
from bPMWD where PMCo=@pmco and ImportId=@importid and Phase=@phase

------ open cursor
open bcPMWD
select @openPMWD = 1

LastPartCTSubctOption_loop:
fetch next from bcPMWD into @isequence, @costtype, @um, @units, @hours, @costs, @importcosttype, @ict_keyid

if @@fetch_status = -1 goto LastPartCTSubctOption_end
if @@fetch_status <> 0 goto LastPartCTSubctOption_loop

---- check for duplicate cost types
select @dsequence=min(Sequence), @dum=isnull(UM,'LS'), @dunits=isnull(Units,0),
		@dhours=isnull(Hours,0),@dcosts=isnull(Costs,0),@dimportcosttype=ImportCostType,
		@dct_keyid = KeyID
from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid and ImportItem=@importitem
and Phase=@phase and CostType=@costtype and KeyID <> @ict_keyid
group by Sequence, ImportCostType, KeyID, UM, Units, Hours, Costs
if @@rowcount = 0 goto LastPartCTSubctOption_loop

if isnull(@costtype,0) = 0 goto LastPartCTSubctOption_loop
if @dimportcosttype <> @importcosttype goto LastPartCTSubctOption_loop

---- accumulate values
select @hours=@hours+@dhours
select @costs=@costs+@dcosts
if @um = @dum and @um <> 'LS'
	begin
	select @units=@units+@dunits
	end

select @dsequence, @isequence, @phase, @importitem, @item

------ update first cost type
--Update bPMWD set Units=@units, Hours=@hours, Costs=@costs
--where PMCo=@pmco and ImportId=@importid and Phase=@phase and Sequence=@isequence
--
------ delete duplicate cost type
--delete from bPMWD
--where PMCo=@pmco and ImportId=@importid and Phase=@phase and CostType=@costtype and Sequence=@dsequence

goto LastPartCTSubctOption_loop


LastPartCTSubctOption_end:
	if @openPMWD = 1
		begin
  		close bcPMWD
  		deallocate bcPMWD
  		set @openPMWD = 0
  		end

---- create last part phase if possible
if isnull(@item,'') <> ''
	begin
	---- skip if part of phase is populated
	select @pphase=rtrim(@phase)
	if substring(@pphase,(len(@pphase)),1) = @separator
		begin
		---- skip if length of item > length of phase part
		select @itemvalue = rtrim(ltrim(convert(varchar(20),@item)))
		if (len(@itemvalue)<=@lenpart)
			begin

			---- populate last part phase
			select @phasepart=@itemvalue, @formphase = null
			select @newphase=@pphase + @phasepart

			---- format multi-part phase
			exec @rcode = bspHQFormatMultiPart @newphase, @phasemask, @formphase output
			if @rcode = 0
				begin
				---- verify that the new phase does not already exist
				if not exists(select top 1 1 from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid
							and Phase=@formphase and KeyID<>@ph_keyid)
					BEGIN
					----TK-11535
					update bPMWP set Phase=RTRIM(@formphase) where KeyID=@ph_keyid
					---- now update bPMWD for the subcontract cost types
					update bPMWD set Phase=RTRIM(@formphase)
					where PMCo=@pmco and ImportId=@importid and Item=@item and Phase=@phase and CostType=@slcosttype
					update bPMWD set Phase=RTRIM(@formphase)
					where PMCo=@pmco and ImportId=@importid and Item=@item and Phase=@phase and CostType=@slcosttype2
					end
				end
			end
		end
	end

---- goto next phase
goto LastPartPhaseSubctOption_loop


LastPartPhaseSubctOption_end:
	if @openPMWP = 1
		begin
  		close bcPMWP
  		deallocate bcPMWP
  		set @openPMWP = 0
  		end


















old_no_unique_codes:
if @lastpartphase not in ('N','S') goto CreatePart
------ create cursor on PMWP to rollup phases, costs, subcontract, and materials if needed
declare bcPMWP cursor LOCAL FAST_FORWARD for select Sequence, Phase, Item, ImportItem, ImportPhase, KeyID
from bPMWP where PMCo=@pmco and ImportId=@importid

------ open cursor
open bcPMWP
select @openPMWP = 1

PMWP_loop:
fetch next from bcPMWP into @sequence, @phase, @item, @importitem, @importphase, @ph_keyid

if @@fetch_status = -1 goto PMWP_end
if @@fetch_status <> 0 goto PMWP_loop

------ check for a phase
if isnull(@phase,'') = '' goto PMWP_loop

------ check if duplicate phases
if not exists(select * from bPMWP with (nolock) where PMCo=@pmco
				and ImportId=@importid and Phase=@phase and KeyID<>@ph_keyid)
	goto PMWP_loop

------ set items in PMWD, PMWM, PMWS to phase item
Update bPMWD set Item=@item
where PMCo=@pmco and ImportId=@importid and Phase=@phase
Update bPMWM set Item=@item
where PMCo=@pmco and ImportId=@importid and Phase=@phase
Update bPMWS set Item=@item
where PMCo=@pmco and ImportId=@importid and Phase=@phase

select @phasesubct_exists = 'N'
---- if sub cost types exist only then check detail
----if @lastpartphase = 'S'
----	begin
----	---- check if only when phase sub cost type exists flag
----	---- check if first SLCostType exists in PMWD for phase
----	if isnull(@slcosttype,'') <> ''	
----		begin
----		select @validcnt = 0
----		select @validcnt = count(*) from bPMWD where ImportId=@importid and ImportPhase=@importphase and CostType=@slcosttype
----		if @validcnt > 0 select @phasesubct_exists = 'Y'
----		end
----	if isnull(@slcosttype2,'') <> ''
----		begin
----		select @validcnt = 0
----		select @validcnt = count(*) from bPMWD where ImportId=@importid and ImportPhase=@importphase and CostType=@slcosttype2
----		if @validcnt > 0 select @phasesubct_exists = 'Y'
----		end
----	end

if @phasesubct_exists = 'N'
	begin
	delete from bPMWP
	where ImportId=@importid and Phase=@phase and Sequence <> @sequence
	end
else
	begin
	delete from bPMWP
	where ImportId=@importid and Phase=@phase and Item=@item and Sequence <> @sequence 
	end

------ create cursor on PMWD to accumulate duplicate cost types
declare bcPMWD cursor LOCAL FAST_FORWARD
		for select Sequence, CostType, UM, Units, Hours, Costs, ImportCostType, ImportItem
from bPMWD where PMCo=@pmco and ImportId=@importid and Phase=@phase

------ open cursor
open bcPMWD
select @openPMWD = 1

Duplicate_PMWD_loop:
fetch next from bcPMWD into @isequence, @costtype, @um, @units, @hours, @costs, @importcosttype, @importitem

if @@fetch_status = -1 goto Duplicate_PMWD_end
if @@fetch_status <> 0 goto Duplicate_PMWD_loop

------ check for duplicate cost types
select @dsequence=Sequence, @dum=isnull(UM,'LS'), @dunits=isnull(Units,0),
		@dhours=isnull(Hours,0),@dcosts=isnull(Costs,0),@dimportcosttype=ImportCostType
from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid and ImportItem=@importitem
and Phase=@phase and CostType=@costtype and Sequence <> @isequence
if @@rowcount=0 goto Duplicate_PMWD_loop

if isnull(@costtype,0) = 0 goto Duplicate_PMWD_loop
if @dimportcosttype <> @importcosttype goto Duplicate_PMWD_loop

------ accumulate values
select @hours=@hours+@dhours
select @costs=@costs+@dcosts
if @um = @dum and @um <> 'LS'
	begin
	select @units=@units+@dunits
	end

------ update first cost type
Update bPMWD set Units=@units, Hours=@hours, Costs=@costs
where PMCo=@pmco and ImportId=@importid and Phase=@phase and Sequence=@isequence

------ delete duplicate cost type
delete from bPMWD
where PMCo=@pmco and ImportId=@importid and Phase=@phase and CostType=@costtype and Sequence=@dsequence


goto Duplicate_PMWD_loop

Duplicate_PMWD_end:
	if @openPMWD = 1
		begin
  		close bcPMWD
  		deallocate bcPMWD
  		set @openPMWD = 0
  		end

goto PMWP_loop

PMWP_end:
	if @openPMWP = 1
		begin
  		close bcPMWP
  		deallocate bcPMWP
  		set @openPMWP = 0
  		end



---- never option for duplicates
if @lastpartphase = 'N' goto Part_Two_Create_Costtypes

---- item as last part when possible
---- put item in last part of phase where possible
select @sequence = min(Sequence) from bPMWP with (nolock) where ImportId=@importid
while @sequence is not null
begin
 	select @item=Item, @phase=Phase, @importitem=ImportItem, @importphase=ImportPhase
 	from bPMWP with (nolock) where ImportId=@importid and Sequence=@sequence
 	if @@rowcount = 0 goto pmwp_next_custom
 	if isnull(@phase,'') = '' goto pmwp_next_custom
 	if isnull(@item,'') = '' goto pmwp_next_custom
 
 	---- skip if part of phase is populated
 	select @pphase=rtrim(@phase)
 	if substring(@pphase,(len(@pphase)),1) <> @separator goto pmwp_next_custom
 
 	---- skip if length of item > length of phase part
 	select @itemvalue = rtrim(ltrim(convert(varchar(20),@item)))
 	if (len(@itemvalue)>@lenpart) goto pmwp_next_custom
 
 	---- check if only when phase sub cost type exists flag
 	select @phasesubct_exists = 'N'
----	---- check if first SLCostType exists in PMWD for phase
----	if isnull(@slcosttype,'') <> ''	
----		begin
----		if exists(select ImportId from bPMWD where ImportId=@importid and PhaseGroup=@phasegroup
---- 								and Phase=@phase and CostType=@slcosttype)
----			begin
----			select @phasesubct_exists = 'Y'
----			end
----		end
----	if isnull(@slcosttype2,'') <> ''
----		begin
----		if exists(select ImportId from bPMWD where ImportId=@importid and PhaseGroup=@phasegroup
---- 								and Phase=@phase and CostType=@slcosttype2)
----			begin
----			select @phasesubct_exists = 'Y'
----			end
----		end

	if @phasesubct_exists = 'N' goto pmwp_next_custom

 	---- populate last part phase
 	select @phasepart=@itemvalue, @formphase = null
 	select @newphase=@pphase + @phasepart
 
 	select @newphase, @phasemask, @formphase, @phasepart
 
 	exec @rcode = bspHQFormatMultiPart @newphase, @phasemask, @formphase output
 	if @rcode <> 0 goto pmwp_next_custom
 
 	---- check if new phase already set up
 	select @validcnt=0
 	select @validcnt = Count(*)
 	from bPMWP with (nolock) where ImportId=@importid and Phase=@formphase and Sequence<>@sequence
 	if @validcnt<>0 goto pmwp_next_custom
	----TK-11535
 	Update bPMWP set Phase=RTRIM(@formphase) where ImportId=@importid and Sequence=@sequence
 


	if @lastpartphase = 'S' goto pmwp_next_custom

 	---- another cursor to update like phases
 	select @isequence = min(Sequence) from bPMWP with (nolock) where ImportId=@importid
 	while @isequence is not null
 	begin
 
 		if @isequence=@sequence goto next_like_phase_custom
 
 		select @vitem=Item, @vphase=Phase
 		from bPMWP with (nolock) where ImportId=@importid and Sequence=@isequence
 		if @vphase is null or @vphase='' goto next_like_phase_custom
 
 		if @vphase<>@phase goto next_like_phase_custom
 
 		if @vitem is null or @vitem='' goto next_like_phase_custom
 
 		---- skip if last part of phase is populated
 		select @pphase=rtrim(@vphase)
 		if substring(@pphase,(len(@pphase)),1) <> @separator goto next_like_phase_custom
 
 		---- skip if length of item > length of phase part
 		select @itemvalue = rtrim(ltrim(convert(varchar(20),@vitem)))
 		if (len(@itemvalue)>@lenpart) goto next_like_phase_custom
 
 		---- populate last part phase
 		select @phasepart=@itemvalue, @formphase = null
 		select @newphase=@pphase + @phasepart
 
 		exec @rcode = bspHQFormatMultiPart @newphase, @phasemask, @formphase output
 		if @rcode <> 0 goto next_like_phase_custom
 
 		---- check if new phase already set up
 		select @validcnt=0
 		select @validcnt = Count(*)
 		from bPMWP with (nolock) where ImportId=@importid and Phase=@formphase and Sequence<>@isequence
 		if @validcnt<>0 goto next_like_phase_custom
		----TK-11535
 		Update bPMWP set Phase=RTRIM(@formphase) where ImportId=@importid and Sequence=@isequence
     
 		next_like_phase_custom:
 		select @isequence = min(Sequence) from bPMWP with (nolock) where ImportId=@importid and Sequence>@isequence
     	if @@rowcount = 0 select @isequence = null
     	end

pmwp_next_custom:
select @sequence = min(Sequence) from bPMWP with (nolock) where ImportId=@importid and Sequence>@sequence
if @@rowcount = 0 select @sequence = null
end

goto Part_Two_Create_Costtypes




CreatePart: -- first pass - put item in last part of phase where possible
select @sequence = min(Sequence) from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid
while @sequence is not null
begin
	select @item=Item, @phase=Phase
	from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
       if @@rowcount = 0 goto pmwp_next_1
       if isnull(@phase,'') = '' goto pmwp_next_1
       if isnull(@item,'') = '' goto pmwp_next_1
    
       -- skip if part of phase is populated
       select @pphase=rtrim(@phase)
       if substring(@pphase,(len(@pphase)),1) <> @separator
          goto pmwp_next_1
    
       -- skip if length of item > length of phase part
       select @itemvalue = rtrim(ltrim(convert(varchar(20),@item)))
       if (len(@itemvalue)>@lenpart) goto pmwp_next_1
    
       -- check if duplicate phase
       if @lastpartphase='D'
          begin
            select @validcnt=0
            select @validcnt = Count(*)
            from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Phase=@phase and Sequence<>@sequence
            if @validcnt=0 goto pmwp_next_1
          end
    
       -- populate last part phase
       select @phasepart=@itemvalue, @formphase = null
       select @newphase=@pphase + @phasepart
    
       select @newphase, @phasemask, @formphase, @phasepart
    
       exec @rcode = bspHQFormatMultiPart @newphase, @phasemask, @formphase output
       if @rcode <> 0 goto pmwp_next_1
    
       select @formphase
    
       -- check if new phase already set up
       select @validcnt=0
       select @validcnt = Count(*)
       from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Phase=@formphase and Sequence<>@sequence
       if @validcnt<>0 goto pmwp_next_1
    
		----TK-11535
       Update bPMWP set Phase=RTRIM(@formphase) where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
    
       -- another cursor to update like phases
       select @isequence = min(Sequence) from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid
       while @isequence is not null
       begin
    
    
          if @isequence=@sequence goto next_like_phase
    
    	  select @vitem=Item, @vphase=Phase
          from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Sequence=@isequence
          if @vphase is null or @vphase='' goto next_like_phase
    
          if @vphase<>@phase goto next_like_phase
    
          if @vitem is null or @vitem='' goto next_like_phase
    
          -- skip if last part of phase is populated
          select @pphase=rtrim(@vphase)
          if substring(@pphase,(len(@pphase)),1) <> @separator
             goto next_like_phase
    
          -- skip if length of item > length of phase part
          select @itemvalue = rtrim(ltrim(convert(varchar(20),@vitem)))
          if (len(@itemvalue)>@lenpart)
             goto next_like_phase
    
          -- populate last part phase
          select @phasepart=@itemvalue, @formphase = null

          select @newphase=@pphase + @phasepart
    
          exec @rcode = bspHQFormatMultiPart @newphase, @phasemask, @formphase output
          if @rcode <> 0 goto next_like_phase
    
          -- check if new phase already set up
          select @validcnt=0
          select @validcnt = Count(*)
          from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Phase=@formphase and Sequence<>@isequence
          if @validcnt<>0 goto next_like_phase
			----TK-11535
          Update bPMWP set Phase=RTRIM(@formphase) where PMCo=@pmco and ImportId=@importid and Sequence=@isequence
    
    	next_like_phase:
    	select @isequence = min(Sequence) from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Sequence>@isequence
    	if @@rowcount = 0 select @isequence = null
    	end
    
    
    pmwp_next_1:
    select @sequence = min(Sequence) from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Sequence>@sequence
    if @@rowcount = 0 select @sequence = null
    end
    
     -- second pass put in sequence number for duplicates
     select @sequence = min(Sequence) from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid
     while @sequence is not null
     begin
    
        select @item=Item, @phase=Phase
        from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
    
        if @@rowcount = 0
           goto pmwp_next_2
    
        if ISNULL(@phase,'') = '' goto pmwp_next_2
    
        -- skip if part of phase is populated
        select @pphase=rtrim(@phase)
        if substring(@pphase,(len(@pphase)),1) <> @separator
				goto pmwp_next_2
    
		---- check if phase code is duplicated for the same item different sequence.
		IF EXISTS(SELECT 1 FROM dbo.bPMWP WHERE PMCo=@pmco and ImportId=@importid and Phase=@phase
						AND Item=@item AND Sequence <> @sequence)
				BEGIN
				DELETE FROM dbo.bPMWP 
				WHERE PMCo=@pmco 
					AND ImportId=@importid 
					AND Phase=@phase
					AND Item=@item 
					AND Sequence = @sequence
				GOTO pmwp_next_2
				END	
				
        -- check for duplicate phase
        select @validcnt=0
        select @validcnt = Count(*)
        from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Phase=@phase and Sequence<>@sequence
        if @validcnt = 0 goto pmwp_next_2
    
        -- populate last part phase
    
        select @seqnvalue=0
        seqn_loop:
          select @seqnvalue=@seqnvalue+1
          if @seqnvalue>999
             goto pmwp_next_2
    
          select @phasepart=rtrim(ltrim(convert(varchar(20),@seqnvalue)))
          select @newphase=@pphase + @phasepart
    	  select @formphase = null
    
          exec @rcode = bspHQFormatMultiPart @newphase,@phasemask,@formphase output
          if @rcode <> 0 goto pmwp_next_2
    
          -- check if new phase already set up
          select @validcnt=0
          select @validcnt = Count(*) from bPMWP with (nolock) 
          where PMCo=@pmco and ImportId=@importid and Phase=@formphase and Sequence<>@sequence
          if @validcnt<>0
             goto seqn_loop
		  ----TK-11535
          Update bPMWP set Phase=RTRIM(@formphase) where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
    
    pmwp_next_2:
    select @sequence = min(Sequence) from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Sequence>@sequence
    end



Part_Two_Create_Costtypes:
------ need to check for create cost types, if new phases created may need to create cost types also
exec @rcode = dbo.bspPMWDTrans @pmco, @importid, @phasegroup, @wcretgpct, @msg output
if @lastpartphase <> 'S' ---- #130893
	begin
	exec @rcode = dbo.bspPMWMTrans @pmco, @importid, @phasegroup, @matlgroup, @vendorgroup, @msg output
	exec @rcode = dbo.bspPMWSTrans @pmco, @importid, @phasegroup, @vendorgroup, @msg output
	end


---- #140742 clean up phase records when using last part phase = always, no last part, and no detail 
if @lastpartphase = 'A' and @lenpart > 0 and @phaselength > 0
	begin
	;
	with CleanUp_Phases(KeyID, Phase) AS
	(
		select p.KeyID, p.Phase
		from dbo.bPMWP p
		where p.PMCo = @pmco and p.ImportId = @importid and p.Phase is not null
		and substring(reverse(p.Phase), 1, 1) <> @separator 
		and substring(reverse(p.Phase), 1, @lenpart) = SPACE(@lenpart)
		and not exists(select top 1 1 from dbo.bPMWD d where d.PMCo=p.PMCo
				and d.ImportId = p.ImportId and p.Phase = d.Phase)
		and (select count(*) from dbo.bPMWP x where x.PMCo=p.PMCo and x.ImportId = p.ImportId
				and substring(x.Phase, 1, @phaselength - @lenpart) = substring(p.Phase, 1, @phaselength - @lenpart)) > 1
		group by p.Phase, p.KeyID
	)
	
	----select * from CleanUp_Phases
	----;
	delete from dbo.bPMWP
	from dbo.bPMWP p
	join CleanUp_Phases x on x.KeyID = p.KeyID
	where p.PMCo=@pmco and p.ImportId=@importid
	;
	end
---- #140742	



------ create cursor on PMWD to add subcontract and cost type records
declare bcPMWD cursor LOCAL FAST_FORWARD for select Sequence
from bPMWD where PMCo=@pmco and ImportId=@importid

------ open cursor
open bcPMWD
select @openPMWD = 1

PMWD_loop:
fetch next from bcPMWD into @dsequence

if @@fetch_status = -1 goto PMWD_end
if @@fetch_status <> 0 goto PMWD_loop

------ get needed information from PMWD
select @item=Item, @phase=Phase, @costtype=CostType, @um=UM, @hours=Hours,
	   @units=Units, @costs=Costs, @importitem=ImportItem, @importphase=ImportPhase,
	   @importcosttype=ImportCostType,@importum=ImportUM
from bPMWD where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence and PhaseGroup=@phasegroup
if @@rowcount = 0 goto PMWD_loop

------ get WCRetgPct from PMWI
select @wcretgpct=RetainPCT
from bPMWI where PMCo=@pmco and ImportId=@importid and Item=@item and ImportItem=@importitem
if isnull(@wcretgpct,0) = 0 select @wcretgpct = 0

------ create subcontract cost types if requested
if @createsubrecs = 'Y' and isnull(@costtype,'') <> ''
	begin
  	------ check first SLCostType
  	if isnull(@slcosttype,'') = @costtype
  		begin
		------ get costs #120807
		select @costs=sum(Costs)
		from bPMWD where PMCo=@pmco and ImportId=@importid and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
		------ get units
		select @units=sum(Units)
		from bPMWD where PMCo=@pmco and ImportId=@importid and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype and UM=@um
		------ find first subcontract record
  		select top 1 @sequence=Sequence
  		from bPMWS with (nolock) 
  		where PMCo=@pmco and ImportId=@importid /*and ImportPhase=@importphase*/ and Phase=@phase and CostType=@costtype
  		Group By ImportId, /*ImportPhase,*/ Phase, CostType, Sequence
  		if @@rowcount = 0
  			begin
  			------ insert SL cost type into PMWS
  			select @slunits=@units, @slcosts=@costs
  			if @slunits <> 0 select @unitcost = (@slcosts/@slunits)
  			if @um='LS' select @slunits = 0, @unitcost = 0
  			select @sequence=1
  			select @sequence=isnull(Max(Sequence),0)+1 
  			from bPMWS with (nolock) where PMCo=@pmco and ImportId=@importid
  			insert into bPMWS(ImportId, Sequence, Item, PhaseGroup, Phase, CostType, VendorGroup, Units, UM,
  					UnitCost, ECM, Amount, WCRetgPct, ImportItem, ImportPhase, ImportCostType, ImportUM, PMCo,
  					SMRetgPct)
  			select @importid, @sequence, @item, @phasegroup, @phase, @costtype, @vendorgroup, @slunits, @um,
  					@unitcost, 'E',@slcosts,@wcretgpct,@importitem,@importphase,@importcosttype,@importum,@pmco,
  					@wcretgpct
  			end
  		end
  
	------ check second SLCostType
  	if isnull(@slcosttype2,'') = @costtype
		begin
		------ get costs #120807
		select @costs=sum(Costs)
		from bPMWD where PMCo=@pmco and ImportId=@importid and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
		------ get units
		select @units=sum(Units)
		from bPMWD where PMCo=@pmco and ImportId=@importid and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype and UM=@um
  		select top 1 @sequence=Sequence
  		from bPMWS with (nolock) 
  		where PMCo=@pmco and ImportId=@importid /*and ImportPhase=@importphase*/ and Phase=@phase and CostType=@costtype
  		Group By ImportId, /*ImportPhase,*/ Phase, CostType, Sequence
  		if @@rowcount = 0
  			begin
  			------ insert SL cost type into PMWS
  			select @slunits=@units, @slcosts=@costs
  			if @slunits <> 0 select @unitcost = (@slcosts/@slunits)
  			if @um='LS' select @slunits = 0, @unitcost = 0
  			select @sequence=1
  			select @sequence=isnull(Max(Sequence),0)+1 
  			from bPMWS with (nolock) where PMCo=@pmco and ImportId=@importid
  			insert into bPMWS(ImportId, Sequence, Item, PhaseGroup, Phase, CostType, VendorGroup, Units, UM,
  					UnitCost, ECM, Amount, WCRetgPct, ImportItem, ImportPhase, ImportCostType, ImportUM, PMCo,
  					SMRetgPct)
  			select @importid, @sequence, @item, @phasegroup, @phase, @costtype, @vendorgroup, @slunits, @um,
  					@unitcost, 'E', @slcosts, @wcretgpct, @importitem, @importphase, @importcosttype, @importum, @pmco,
  					@wcretgpct
  			end
		end
	end

declare @creatematlrecs char(1)
set @creatematlrecs = 'N'
---- create subcontract cost types if requested
if @creatematlrecs = 'Y' and isnull(@costtype,'') <> ''
	begin
  	------ check first SLCostType
  	if isnull(@matlcosttype,'') = @costtype
  		begin
		----
		select @costs=sum(Costs)
		from bPMWD where PMCo=@pmco and ImportId=@importid and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
		---- get units
		select @units=sum(Units)
		from bPMWD where PMCo=@pmco and ImportId=@importid and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype and UM=@um
		---- find first material record
  		select top 1 @sequence=Sequence
  		from bPMWM with (nolock) 
  		where PMCo=@pmco and ImportId=@importid and Phase=@phase and CostType=@costtype
  		Group By ImportId, ImportPhase, Phase, CostType, Sequence
  		if @@rowcount = 0
  			begin
  			------ insert Material cost type into PMWM
  			select @slunits=@units, @slcosts=@costs
  			if @slunits <> 0 select @unitcost = (@slcosts/@slunits)
  			if @um='LS' select @slunits = 0, @unitcost = 0
  			select @sequence=1
  			select @sequence=isnull(Max(Sequence),0)+1 
  			from bPMWM with (nolock) where PMCo=@pmco and ImportId=@importid
  			----insert into bPMWM(ImportId, Sequence, Item, PhaseGroup, Phase, CostType, VendorGroup, Units, UM,
  			----		UnitCost, ECM, Amount, WCRetgPct, ImportItem, ImportPhase, ImportCostType, ImportUM, PMCo)
  			----select @importid, @sequence, @item, @phasegroup, @phase, @costtype, @vendorgroup, @slunits, @um,
  			----		@unitcost, 'E', @slcosts, @wcretgpct, @importitem, @importphase, @importcosttype, @importum, @pmco
  			end
  		end
  
	------ check second MatlCostType
  	if isnull(@matlcosttype2,'') = @costtype
		begin
		----
		select @costs=sum(Costs)
		from bPMWD where PMCo=@pmco and ImportId=@importid and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
		---- get units
		select @units=sum(Units)
		from bPMWD where PMCo=@pmco and ImportId=@importid and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype and UM=@um
  		select top 1 @sequence=Sequence
  		from bPMWM with (nolock) 
  		where PMCo=@pmco and ImportId=@importid and Phase=@phase and CostType=@costtype
  		Group By ImportId, ImportPhase, Phase, CostType, Sequence
  		if @@rowcount = 0
  			begin
  			------ insert Material cost type into PMWM
  			select @slunits=@units, @slcosts=@costs
  			if @slunits <> 0 select @unitcost = (@slcosts/@slunits)
  			if @um='LS' select @slunits = 0, @unitcost = 0
  			select @sequence=1
  			select @sequence=isnull(Max(Sequence),0)+1 
  			from bPMWM with (nolock) where PMCo=@pmco and ImportId=@importid
  			----insert into bPMWM(ImportId, Sequence, Item, PhaseGroup, Phase, CostType, VendorGroup, Units, UM,
  			----		UnitCost, ECM, Amount, WCRetgPct, ImportItem, ImportPhase, ImportCostType, ImportUM, PMCo)
  			----select @importid, @sequence, @item, @phasegroup, @phase, @costtype, @vendorgroup, @slunits, @um,
  			----		@unitcost, 'E', @slcosts, @wcretgpct, @importitem, @importphase, @importcosttype, @importum, @pmco
  			end
		end
	end


------ create cost type from bPMUC
if @costtype > 0
	begin
  	select @validcnt=count(*) from bPMUC with (nolock)
  	where Template=@template and CostType=@costtype
  	if @validcnt > 0
		begin
		------ pseudo cursor from bPMUC
		select @createcosttype=min(CreateCostType) from bPMUC with (nolock)
		where Template=@template and CostType=@costtype
		while @createcosttype is not null
  			begin
  			------ get PMUC data
  			select @useum=UseUM, @useunits=UseUnits, @usehours=UseHours
			from bPMUC with (nolock)
  			where Template=@template and CostType=@costtype and CreateCostType=@createcosttype
  			if @@rowcount <> 0
  				begin
  				if not exists(select top 1 1 from bPMWD with (nolock) where PMCo=@pmco and ImportId=@importid
  								and ImportPhase=@importphase and Phase=@phase and CostType=@createcosttype)
  					begin
					---- set defaults #131418
					select @ct_um = 'LS', @ct_billflag = 'C', @ct_itemunitflag = 'N', @ct_phaseunitflag = 'N'
					---- try and get bill flag, item unit flag, and phase unit flag from phase cost types
					---- Check full phase in JC Phase Cost Types
					select @ct_um=UM, @ct_billflag=BillFlag, @ct_itemunitflag=ItemUnitFlag, @ct_phaseunitflag=PhaseUnitFlag
					from bJCPC with (nolock) 
					where PhaseGroup = @phasegroup and Phase=@phase and CostType=@createcosttype
					if @@rowcount = 0
  						begin
						---- Check valid portion
						if @validphasechars > 0
  							begin
  							-- Check partial phase in JC Phase Cost Types
  							select @pphase = substring(@phase,1,@validphasechars) + '%'
   							select Top 1 @ct_um=UM, @ct_billflag=BillFlag, @ct_itemunitflag=ItemUnitFlag, @ct_phaseunitflag=PhaseUnitFlag
   							from bJCPC with (nolock) 
   							where PhaseGroup=@phasegroup and Phase like @pphase and CostType=@createcosttype
							Group By PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
							if @@rowcount = 0 
								begin
								select @ct_um = 'LS', @ct_billflag = 'C', @ct_itemunitflag = 'N', @ct_phaseunitflag = 'N'
								end
   							end
						end

  					if @useum = 'N'
						begin
						select @um=@ct_um, @importum=@ct_um
						end
					else
						begin
						select @ct_um = @um, @importum = @um
						if isnull(@ct_um,'') = ''
							begin
							select @ct_um = 'LS', @importum = 'LS'
							end
						end
  					if @useunits = 'N' select @units = 0
  					if @usehours = 'N' select @hours = 0
  					-- -- -- insert into bPMUC #131418
  					select @sequence=1, @costs=0
  					select @sequence=isnull(Max(Sequence),0)+1 from bPMWD where PMCo=@pmco and ImportId=@importid
  					insert into bPMWD(ImportId, Sequence, Item, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag,
  								PhaseUnitFlag, Hours, Units, Costs, ImportItem, ImportPhase, ImportCostType, ImportUM, PMCo)
  					select @importid, @sequence, @item, @phasegroup, @phase, @createcosttype,
							isnull(@ct_um,'LS'), isnull(@ct_billflag,'C'),
							isnull(@ct_itemunitflag,'N'), isnull(@ct_phaseunitflag,'N'),
  							@hours, @units, @costs, @importitem, @importphase, @importcosttype,
							@importum, @pmco
  					end
  				end
  			select @createcosttype=min(CreateCostType) from bPMUC with (nolock)
  			where Template=@template and CostType=@costtype and CreateCostType>@createcosttype
  			if @@rowcount = 0 select @createcosttype = null
  			end
  		end
  	end



goto PMWD_loop


PMWD_end:
	if @openPMWD = 1
		begin
  		close bcPMWD
  		deallocate bcPMWD
  		set @openPMWD = 0
  		end





bspexit:
  	if @openPMWP = 1
  		begin
  		close bcPMWP
  		deallocate bcPMWP
  		set @openPMWP = 0
  		end

  	if @openPMWD = 1
  		begin
  		close bcPMWD
  		deallocate bcPMWD
  		set @openPMWD = 0
  		end

	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspPMLastPartPhase] TO [public]
GO
