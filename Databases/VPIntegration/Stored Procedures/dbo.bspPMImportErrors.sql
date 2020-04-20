SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMImportErrors    Script Date: 8/28/99 9:36:24 AM ******/
CREATE   procedure [dbo].[bspPMImportErrors]
/*******************************************************************************
   * Created By:
   * Modified By: GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
   *				GF 06/01/2006 - #27997 - 6.x changes
   *				GP 11/11/2009 - #136204 - add checks to PMSL and PMSM records
   *
   *
   *
   * This SP will check for errors in the work tables. Pass in Y or N for
   * each table you wish to check. Tables: PMWI,PMWP,PMWD,PMWS,PMWM.
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
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   *
   ********************************************************************************/
(@pmco bCompany, @importid varchar(10), @pmwiyn bYN, @pmwpyn bYN, @pmwdyn bYN,
 @pmwsyn bYN, @pmwmyn bYN, @msg varchar(500) output)
as
set nocount on

declare @rcode int, @sequence int, @template varchar(10), @dsequence int, @isequence int,
		@validcnt int, @item bContractItem, @um bUM, @errors varchar(255), @vitem bContractItem,
		@phase bPhase, @vphase bPhase, @costtype bJCCType, @vcosttype bJCCType, @vendor bVendor,
		@material bMatl, @pmwierrors int, @pmwperrors int, @pmwderrors int, @pmwserrors int,
		@pmwmerrors int, @pcode int, @job bJob, @pmsg varchar(255), @olderrors varchar(255),
		@updtflag bYN, @createsicode char(1), @phasegroup bGroup, @matlgroup bGroup,
		@vendorgroup bGroup, @siregion char(6), @sicode char(16), @psequence int,
		@importvendor varchar(30), @apco bCompany, @amount bDollar, @units bUnits, @unitcost bUnitCost

select @rcode=0, @pmwierrors=0, @pmwperrors=0, @pmwderrors=0, @pmwserrors=0, @pmwmerrors=0
   
------ check import id
If @importid is null
      begin
      select @msg='Missing Import Id', @rcode=1
      goto bspexit
      end

------ get PMCo info
select @apco=APCo from PMCO with (nolock) where PMCo=@pmco
if @@rowcount = 0
	begin
	select @msg = 'Invalid PM Company.', @rcode = 1
	goto bspexit
	end

------ get PMWH info
select @template=Template from PMWH with (nolock) where PMCo=@pmco and ImportId=@importid
if @@rowcount = 0
	begin
	select @msg='Invalid Import Id', @rcode = 1
	goto bspexit
	end

------ get HQCO info for PMCo
select @phasegroup=PhaseGroup, @matlgroup=MatlGroup
from HQCO with (nolock) where HQCo=@pmco
if @@rowcount = 0
	begin
	select @msg='Missing data group for HQ Company ' + convert(varchar(3),@pmco) + '!', @rcode=1
	goto bspexit
	end

------ get HQCO info for APCo
select @vendorgroup=VendorGroup 
from HQCO with (nolock) where HQCo=@apco
if @@rowcount = 0
	begin
	select @msg = 'Invalid AP Company assigned to PM Company. Cannot get Vendor Group from HQCO.', @rcode = 1
	goto bspexit
	end

------ check groups
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


------ get PMUT info
select @createsicode=CreateSICode from bPMUT where Template=@template
if @@rowcount = 0 select @createsicode='N'

    if @pmwiyn<>'N' select @pmwiyn='Y'
    if @pmwpyn<>'N' select @pmwpyn='Y'
    if @pmwdyn<>'N' select @pmwdyn='Y'
    if @pmwsyn<>'N' select @pmwsyn='Y'
    if @pmwmyn<>'N' select @pmwmyn='Y'
   
    begin transaction
   
    ProcessPMWI: if @pmwiyn='N' goto ProcessPMWP
    -- pseudo cursor for PMWI
    select @isequence = min(Sequence) from bPMWI where PMCo=@pmco and ImportId=@importid
    while @isequence is not null
    begin
   
       select @item=Item, @siregion=SIRegion, @sicode=SICode, @um=UM, @olderrors=isnull(Errors,'')
       from bPMWI where PMCo=@pmco and ImportId=@importid and Sequence=@isequence
   
       select @errors='', @updtflag='Y'
   
       if @item is null
          begin
          select @errors=isnull(@errors,'') + 'Missing Item: ', @item=Null
          end
       else
          begin
          select @vitem=Item from bPMWI where PMCo=@pmco and ImportId=@importid and Sequence<>@isequence and Item=@item
          if @@rowcount<>0
             begin
             select @errors=isnull(@errors,'') + 'Duplicate Item ' + @vitem + ': '
             end
          end
   
       if @createsicode='N' and isnull(@siregion,'') <> '' and isnull(@sicode,'') <> ''
          begin
          select @validcnt = 0
          select @validcnt = Count(*) from bJCSI where SIRegion=@siregion and SICode=@sicode
          if @validcnt =0
             begin
             select @errors=isnull(@errors,'') + 'Invalid Standard Item: '
             end
          end
   
   
       if @um is null
          begin
          select @errors=ISNULL(@errors,'') + 'Missing UM: ', @um=Null
          end
       else
          begin
          select @validcnt = 0
          select @validcnt = Count(*) from bHQUM where UM=@um
          if @validcnt=0
          begin
             select @errors=isnull(@errors,'') + 'Invalid UM: '
             end
          end
   
       if @errors<>@olderrors
          begin
          select @updtflag='Y'
          end
       else
          begin
          select @updtflag='N'
          end
   
       if @errors=''
          begin
          select @errors=null
          end
   
       if @updtflag='Y'
          begin
          update bPMWI set Errors=@errors where PMCo=@pmco and ImportId=@importid and Sequence=@isequence
          select @pmwierrors=@pmwierrors + 1
          end
   
    select @isequence = min(Sequence) from bPMWI where PMCo=@pmco and ImportId=@importid and Sequence>@isequence
    end
   
    ProcessPMWP: if @pmwpyn='N' goto ProcessPMWD
    -- pseudo cursor for PMWP
    select @psequence = min(Sequence) from bPMWP where PMCo=@pmco and ImportId=@importid
    while @psequence is not null
    begin
   
       select @item=Item, @phase=Phase, @olderrors=isnull(Errors,'')
       from bPMWP where PMCo=@pmco and ImportId=@importid and Sequence=@psequence
   
   
       select @errors='', @updtflag='Y'
   
       if @item is null
          begin
          select @errors=isnull(@errors,'') + 'Missing Item: ', @item=Null
          end
       else
          begin
          select @vitem=Item
          from bPMWI where PMCo=@pmco and ImportId=@importid and Item=@item
          if @@rowcount=0 select @errors=isnull(@errors,'') + 'Invalid Item: '
          end
   
   
       if @phase is null
          begin
          select @errors=isnull(@errors,'') + 'Missing Phase: ', @phase=Null
          end
       else
          begin
          select @job=null, @pcode=0
          exec @pcode = dbo.bspJCPMValUseValidChars @pmco,@phasegroup,@phase,@job,@pmsg output
          if @pcode <> 0 select @errors=isnull(@errors,'') + 'Invalid Phase: '
          end
   
       if @item is not null and @phase is not null
          begin
          select @vitem=Item
          from bPMWP where PMCo=@pmco and ImportId=@importid and Sequence<>@psequence and Phase=@phase and Item<>@item
          if @@rowcount<>0 select @errors=isnull(@errors,'') + 'Phase assigned to more than one Item: '
          end
   
       if @errors<>@olderrors
          begin
          select @updtflag='Y'
          end
       else
          begin
          select @updtflag='N'
          end
   
       if @errors=''
          begin
          select @errors=null
          end
   
       if @updtflag='Y'
          begin
          update bPMWP set Errors=@errors where PMCo=@pmco and ImportId=@importid and Sequence=@psequence
          select @pmwperrors=@pmwperrors + 1
          end
   
    select @psequence = min(Sequence) from bPMWP where PMCo=@pmco and ImportId=@importid and Sequence>@psequence
    end
   
    ProcessPMWD: if @pmwdyn='N'goto ProcessPMWS
    -- pseudo cursor for PMWD
    select @dsequence = min(Sequence) from bPMWD where PMCo=@pmco and ImportId=@importid
    while @dsequence is not null
    begin
   
       select @item=Item, @phase=Phase, @costtype=CostType, @um=UM, @olderrors=isnull(Errors,'')
       from bPMWD where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
   
       select @errors='', @updtflag='Y'
   
       if @item is null
          begin
          select @errors=isnull(@errors,'') + 'Missing Item: ', @item=Null
          end
       else
          begin
          select @vitem=Item
          from bPMWI where PMCo=@pmco and ImportId=@importid and Item=@item
   
          if @@rowcount=0 select @errors=isnull(@errors,'') + 'Invalid Item: '
          end
   
       if @phase is null
          begin
          select @errors=isnull(@errors,'') + 'Missing Phase: ', @phase=Null
          end
       else
          begin
          select @job=null, @pcode=0
   
          exec @pcode = dbo.bspJCPMValUseValidChars @pmco,@phasegroup,@phase,@job,@pmsg output
   
          if @pcode <> 0
      	  select @errors=isnull(@errors,'') + 'Invalid Phase: '
          else
             select @vphase=Phase
             from bPMWP where PMCo=@pmco and ImportId=@importid and Phase=@phase
             if @@rowcount=0 select @errors=isnull(@errors,'') + 'Invalid Phase: '
          end
   
   
       if @costtype is null
          begin
          select @errors=isnull(@errors,'') + 'Missing CostType: ', @costtype=Null
          end
       else
          begin
   
            select @validcnt=0
            select @validcnt = Count(*) from bJCCT where PhaseGroup=@phasegroup and CostType=@costtype
            if @validcnt=0 select @errors=isnull(@errors,'') + 'Invalid CostType: '
          end
   
       if @um is null
          begin
   
          select @errors=isnull(@errors,'') + 'Missing UM: ', @um=Null
          end
       else
    begin
          select @validcnt = Count(*) from bHQUM where UM=@um
          if @validcnt=0 select @errors=isnull(@errors,'') + 'Invalid UM: '
          end
   
   
       if @errors<>@olderrors
          begin
          select @updtflag='Y'
          end
       else
          begin
   
          select @updtflag='N'
   
          end
   
       if @errors=''
          begin
          select @errors=null
          end
   
       if @updtflag='Y'
          begin
          update bPMWD set Errors=@errors where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
          select @pmwderrors=@pmwderrors + 1
          end
   
    select @dsequence = min(Sequence) from bPMWD where PMCo=@pmco and ImportId=@importid and Sequence>@dsequence
    end
   
   
    ProcessPMWS: if @pmwsyn='N' goto ProcessPMWM
    -- pseudo cursor for PMWS
    select @dsequence = min(Sequence) from bPMWS where PMCo=@pmco and ImportId=@importid
    while @dsequence is not null
    begin
   
       select @item=Item, @phase=Phase, @costtype=CostType, @um=UM, @vendor=Vendor,
       @importvendor=ImportVendor, @olderrors=isnull(Errors,''), @amount=Amount, @units=Units, @unitcost=UnitCost
       from bPMWS where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
   
       select @errors='', @updtflag='Y'
   
       if @item is null
          begin
          select @errors=isnull(@errors,'') + 'Missing Item: ', @item=Null
          end
   
       else
          begin
          select @vitem=Item
          from bPMWI where PMCo=@pmco and ImportId=@importid and Item=@item
          if @@rowcount=0 select @errors=isnull(@errors,'') + 'Invalid Item: '
          end
   
       if @phase is null
          begin
          select @errors=isnull(@errors,'') + 'Missing Phase: ', @phase=Null
          end
       else
          begin
          select @job=null, @pcode=0
          exec @pcode = dbo.bspJCPMValUseValidChars @pmco,@phasegroup,@phase,@job,@pmsg output
          if @pcode <> 0
   	  select @errors=isnull(@errors,'') + 'Invalid Phase: '
          else
             select @vphase=Phase
             from bPMWP where PMCo=@pmco and ImportId=@importid and Phase=@phase
             if @@rowcount=0 select @errors=isnull(@errors,'') + 'Invalid Phase: '
          end
   
       if @costtype is null
          begin
          select @errors=isnull(@errors,'') + 'Missing CostType: ', @costtype=Null
          end
       else
          begin
          select @validcnt=0
          select @validcnt = Count(*) from bJCCT where PhaseGroup=@phasegroup and CostType=@costtype
          if @validcnt=0 select @errors=isnull(@errors,'') + 'Invalid CostType: '
          end
   
       if @um is null
          begin
          select @errors=isnull(@errors,'') + 'Missing UM: ', @um=Null
          end
       else
          begin
          select @validcnt = 0
          select @validcnt = Count(*) from bHQUM where UM=@um
          if @validcnt=0 select @errors=isnull(@errors,'') + 'Invalid UM: '
          end
   
       if @vendor=0
          begin
            if @importvendor is null
               begin
                 select @errors=isnull(@errors,'') + 'Missing Vendor: '
               end
            else
               begin
                 select @errors=isnull(@errors,'') + 'Invalid Vendor: '
               end
          end
       else
          begin
          if @vendor is not null
             begin
   
               select @validcnt=0
               select @validcnt = Count(*) from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
               if @validcnt=0 select @errors=isnull(@errors,'') + 'Invalid Vendor: '
             end
          end
          
        -- 136204  
		if @um <> 'LS' and @units = 0 and @amount <> 0
		begin
			select @errors=isnull(@errors,'') + 'Non lump sum records must have units with amount.', @um = null, @units = null, @amount = null
		end
   
       if @errors<>@olderrors
          begin
          select @updtflag='Y'
          end
       else
          begin
          select @updtflag='N'
          end
   
       if @errors=''
          begin
          select @errors=null
          end
   
       if @updtflag='Y'
          begin
   
          update bPMWS set Errors=@errors where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
          select @pmwserrors=@pmwserrors + 1
          end
   
    select @dsequence = min(Sequence) from bPMWS where PMCo=@pmco and ImportId=@importid and Sequence>@dsequence
   
    end
   
   ProcessPMWM: if @pmwmyn='N' goto bspdone
    -- pseudo cursor for PMWM
   
   select @dsequence = min(Sequence) from bPMWM where PMCo=@pmco and ImportId=@importid
   while @dsequence is not null
   begin
   	select @item=Item, @phase=Phase, @costtype=CostType, @um=UM, @material=Material,
   			@vendor=Vendor, @olderrors=isnull(Errors,'')
   	from bPMWM where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
   
   	select @errors='', @updtflag='Y'
   
   	if @item is null
   		begin
   		select @errors=isnull(@errors,'') + 'Missing Item: ', @item=Null
   		end
   	else
   		begin
   		select @vitem=Item
   		from bPMWI where PMCo=@pmco and ImportId=@importid and Item=@item
   		if @@rowcount=0 select @errors=isnull(@errors,'') + 'Invalid Item: '
   		end
   
   	if @phase is null
   		begin
   		select @errors=isnull(@errors,'') + 'Missing Phase: ', @phase=Null
   		end
   	else
   		begin
   		select @job=null, @pcode=0
   		exec @pcode = dbo.bspJCPMValUseValidChars @pmco,@phasegroup,@phase,@job,@pmsg output
   		if @pcode <> 0
   			select @errors=isnull(@errors,'') + 'Invalid Phase: '
   		else
   			select @vphase=Phase
   			from bPMWP where PMCo=@pmco and ImportId=@importid and Phase=@phase
   			if @@rowcount=0 select @errors=isnull(@errors,'') + 'Invalid Phase: '
   		end
   
   	if @material is null
   		begin
   		select @material=Null
   		end
   	else
   		begin
   		select @validcnt = 0
   		select @validcnt = Count(*) from bHQMT where MatlGroup=@matlgroup and Material=@material
   		if @validcnt=0 select @errors=isnull(@errors,'') + 'Invalid Material: '
   		end
   
   	if @um is null
   		begin
   		select @errors=isnull(@errors,'') + 'Missing UM: ', @um=Null
   		end
   	else
   		begin
   		set @pcode = 0
   		exec @pcode = dbo.bspPMWMMatlUMVal @pmco, @matlgroup, @material, @um, @pmsg output
   		if @pcode <> 0 select @errors = isnull(@errors,'') + 'Invalid UM: '
   		end
   
   	if @costtype is null
   		begin
   		select @errors=isnull(@errors,'') + 'Missing CostType: ',@costtype=Null
   		end
   	else
   		begin
   		select @validcnt = 0
   		select @validcnt = Count(*) from bJCCT where PhaseGroup=@phasegroup and CostType=@costtype
   		if @validcnt=0 select @errors=isnull(@errors,'') + 'Invalid CostType: '
   		end
   
   	if @vendor=0
   		begin
   		select @errors=isnull(@errors,'') + 'Missing Vendor: '
   		end
   	else
   		begin
   		if @vendor is not null
   			begin
   			select @validcnt = 0
   			select @validcnt = Count(*) from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
   			if @validcnt=0 select @errors=isnull(@errors,'') + 'Invalid Vendor: '
   			end
   		end
   
       if @errors<>@olderrors
          begin
          select @updtflag='Y'
          end
       else
          begin
          select @updtflag='N'
          end
   
       if @errors=''
          begin
          select @errors=null
          end
   
       if @updtflag='Y'
          begin
          update bPMWM set Errors=@errors where PMCo=@pmco and ImportId=@importid and Sequence=@dsequence
          select @pmwmerrors=@pmwmerrors + 1
          end
   
    select @dsequence = min(Sequence) from bPMWM where PMCo=@pmco and ImportId=@importid and Sequence>@dsequence
    end


bspdone:
	commit transaction
	select @msg=''
	if @pmwierrors > 0 select @msg = isnull(@msg,'') + 'Item', @rcode=6

	if @pmwperrors > 0 ------select @msg = isnull(@msg,'') + ', Phase', @rcode=6
		begin
		if @msg = '' 
			begin
			select @msg = 'Phase', @rcode = 6
			end
		else
			begin
			select @msg = @msg + ', Phase', @rcode = 6
			end
		end

	if @pmwderrors > 0 ------select @msg = isnull(@msg,'') + ', Cost Type', @rcode=6
		begin
		if @msg = ''
			begin
			select @msg = 'Cost Type', @rcode=6
			end
		else
			begin
			select @msg = @msg + ', Cost Type', @rcode=6
			end
		end

	if @pmwserrors > 0 ------select @msg = isnull(@msg,'') + ', Subcontract', @rcode=6
		begin
		if @msg = ''
			begin
			select @msg = 'Subcontract', @rcode=6
			end
		else
			begin
			select @msg = @msg + ', Subcontract', @rcode=6
			end
		end

	if @pmwmerrors > 0 ------select @msg = isnull(@msg,'') + ', Material', @rcode=6
		begin
		if @msg = ''
			begin
			select @msg = 'Material', @rcode=6
			end
		else
			begin
			select @msg = @msg + ', Material', @rcode=6
			end
		end

	if isnull(@msg,'') <> '' 
		select @msg = isnull(@msg,'') + ' errors found.'
	else
		select @msg = 'No import errors found.'


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMImportErrors] TO [public]
GO
