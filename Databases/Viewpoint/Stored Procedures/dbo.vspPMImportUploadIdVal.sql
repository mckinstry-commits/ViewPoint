SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImportUploadIdVal    Script Date: 06/06/2006 ******/
CREATE proc [dbo].[vspPMImportUploadIdVal]
/*************************************
 * Created By:	GF 06/06/2006 - for 6.x
 * Modified By:	GF 12/14/2009 - issue #137050 - validate state/country combination
 *				GP 03/08/2010 - issue #138338 - validate insurance code on phase records
 *				GF 01/04/2010 - issue #142720 - estimate description changed to 60-characters
 *
 *
 *
 * validates PM Import Id from PM Import Upload.
 * Runs PM Import Errors update to verify that ImportId is clean to upload.
 *
 * Pass:
 *	PM Company
 *	PM Import Id
 *
 * OutPut:
 * Errors Flag
 * Import Template
 * Estimate description
 * SI Region
 * Import Template CO Item flag
 *
 * Success returns:
 *	0 and PMWH Description
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany = null, @importid varchar(10) = null,
 @errors bYN = 'N' output, @template varchar(10) = null output, @estimate_desc bItemDesc = null output,
 @siregion varchar(6) = null output, @coitem bYN = 'N' output, @pmwi_item_count int = 0 output, 
 @pmwi_invalid_count int = 0 output, @msg varchar(255) output)
as 
set nocount on

declare @rcode int, @errmsg varchar(255), @validcnt int, @description bDesc,
		@mailstate varchar(4), @mailcountry char(2), @shipstate varchar(4),
		@shipcountry char(2), @ErrPhaseSeq int

select @rcode = 0, @errors = 'N', @pmwi_invalid_count = 0, @pmwi_item_count = 0

if @pmco is null
   	begin
   	select @msg = 'Missing PM Company.', @rcode = 1
   	goto bspexit
   	end

if @importid is null
	begin
	select @msg = 'Missing Import Id', @rcode=1
   	goto bspexit
	end


---- validate Import Id
select @template=Template, @estimate_desc=Description, @siregion=SIRegion,
		@mailstate=MailState, @mailcountry=MailCountry, @shipstate=ShipState,
		@shipcountry=ShipCountry
from PMWH with (nolock) where PMCo=@pmco and ImportId=@importid
if @@rowcount = 0 
   	begin
   	select @msg = 'Invalid Import Id.', @rcode = 1
	goto bspexit
   	end

if isnull(@mailstate,'') <> ''
	begin
	if not exists(select 1 from dbo.HQST with (nolock) where State=@mailstate)
		begin
		select @msg='Invalid Mail State, correct first before uploading.', @rcode = 1
		goto bspexit
		end
	end

if isnull(@shipstate,'') <> ''
	begin
	if not exists(select 1 from dbo.HQST with (nolock) where State=@shipstate)
		begin
		select @msg='Invalid Ship State, correct first before uploading.', @rcode = 1
		goto bspexit
		end
	end
	
--Validate PWPM.InsCode - Issue 138338
select top 1 @ErrPhaseSeq=PMWP.Sequence
from dbo.PMWP with (nolock) 
left join dbo.HQIC with (nolock) on HQIC.InsCode=PMWP.InsCode
where PMWP.PMCo=@pmco and PMWP.ImportId=@importid and isnull(PMWP.InsCode,'') <> ''
and not exists(select top 1 1 from dbo.HQIC where PMWP.InsCode=InsCode)
if @@rowcount = 1
begin
	select @msg = 'Invalid Insurance Code on Phase record - Seq:' + cast(@ErrPhaseSeq as varchar(4)), @rcode = 1
	goto bspexit
end	


------ get PMUT info
select @description=Description, @coitem=COItem
from PMUT with (nolock) where Template=@template
if @@rowcount = 0
	begin
	select @description = '', @coitem='N'
	end



------ run SP to update errors if any
exec @rcode = dbo.bspPMImportErrors @pmco, @importid, 'Y', 'Y', 'Y', 'Y', 'Y', @errmsg output

------ check for errors
select @validcnt = 0, @rcode = 0, @msg = ''
------ check PMWI
select @validcnt = Count(*)
from PMWI with (nolock) where PMCo=@pmco and ImportId=@importid and isnull(Errors,'') > ''
if @validcnt <> 0
	begin
	select @msg='Item - ', @rcode=1
	end
------ check PMWP
select @validcnt = 0
select @validcnt = Count(*)
from PMWP with (nolock) where PMCo=@pmco and ImportId=@importid and isnull(Errors,'') > ''
if @validcnt <> 0
	begin
	select @msg=isnull(@msg,'') + 'Phase - ', @rcode=1
	end
------ check PMWD
select @validcnt = 0
select @validcnt = Count(*)
from PMWD with (nolock) where PMCo=@pmco and ImportId=@importid and isnull(Errors,'') > ''
if @validcnt <> 0
	begin
	select @msg=isnull(@msg,'') + 'Cost Type - ', @rcode=1
	end
------ check PMWS
select @validcnt = 0
select @validcnt = Count(*)
from PMWS with (nolock) where PMCo=@pmco and ImportId=@importid and isnull(Errors,'') > ''
if @validcnt <> 0
	begin
	select @msg=isnull(@msg,'') + 'Subcontract - ', @rcode=1
	end
------ check PMWM
select @validcnt = 0
select @validcnt = Count(*)
from PMWM with (nolock) where PMCo=@pmco and ImportId=@importid and isnull(Errors,'') > ''
if @validcnt <> 0
	begin
	select @msg=isnull(@msg,'') + 'Material - ', @rcode=1
	end

if @rcode = 0
	begin
	------ create import id description
	select @msg = isnull(@template,'') + ' - ' + isnull(@description,'')
	end
else
	begin
	select @msg = isnull(@msg,'') + ' errors found.', @errors='Y'
	end

---- need a count of PMWI records and if any contract items lengths without spaces
---- is greater than 10, in which case cannot be loaded as a CO item.
---- get count of PMWI records
select @pmwi_item_count = count(*) from PMWI with (nolock) where PMCo=@pmco and ImportId=@importid
---- get count of PMWI records where the contract item data length without spacesis > 10
select @pmwi_invalid_count = count(*) from PMWI with (nolock) where PMCo=@pmco
and ImportId=@importid and datalength(ltrim(rtrim(Item))) > 10

--if @pmwi_item_count > 0
--	begin
--	------ get count of PMWI records where the contract item data length without spacesis > 10
--	select @pmwi_invalid_count = count(*) from PMWI with (nolock) where PMCo=@pmco
--	and ImportId=@importid and datalength(ltrim(rtrim(Item))) > 10
--	end



bspexit:
	------if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportUploadIdVal] TO [public]
GO
