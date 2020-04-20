SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImmportData    Script Date: 05/17/2006 ******/
CREATE proc [dbo].[vspPMImportData]
/*************************************
 * Created By:	GF 05/31/2006 6.x only
 * Modified By:	GP 01/18/2010 - 137338 added check for Timberline to insert item record
 *				GF 02/10/2010 - issue #137957 - one item option and also items in the import file
 *
 *
 * Called from PM Import Data form to process text records that have been loaded
 * into PMWX via bulk insert process (vspPMImportDataBulk). Will process text records
 * into PMWI, PMWP, PMWD, PMWS, and PMWM.
 *
 *
 * Pass:
 * PMCO			PM Company
 * Template		PM Import Template
 * ImportId		PM Import ID
 * RetainPct	Default Retainage Percent
 * UserName		Viewpoint user name
 *
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
(@pmco bCompany = 0, @template varchar(10) = null, @importid varchar(10) = null,
 @retainpct bPct = 0, @username bVPUserName = null, @msg varchar(500) output)
as
set nocount on

declare @rcode int, @validcnt int, @errmsg varchar(500), @sqlstring varchar(1000),
		@executestring NVARCHAR(1000), @paramdef NVARCHAR(1000), @importroutine varchar(20),
		@filetype varchar(1), @phasegroup bGroup, @userroutine varchar(30), @ImportYN bYN,
		@ItemOption varchar(1) ---- #!37957

select @rcode = 0

if @pmco is null
	begin
	select @msg = 'Missing PM Company!', @rcode = 1
	goto bspexit
	end

if @template is null
	begin
	select @msg = 'Missing Import Template!', @rcode = 1
	goto bspexit
	end

if @importid is null
	begin
	select @msg = 'Missing Import Id!', @rcode = 1
	goto bspexit
	end

if @username is null
	begin
	select @msg = 'Missing Viewpoint User Name!', @rcode = 1
	goto bspexit
	end

------ get phase group from HQCO
select @phasegroup=PhaseGroup from HQCO where HQCo=@pmco
if @@rowcount = 0
	begin
	select @msg = 'Invalid HQ Company, cannot find phase group.', @rcode = 1
	goto bspexit
	end

------ get import template data
---- #137957
select @importroutine=ImportRoutine, @filetype=FileType, @userroutine=UserRoutine,
		 @ItemOption=ItemOption
from PMUT with (nolock) where Template=@template
if @@rowcount = 0
	begin
	select @msg = 'Invalid Import Template!', @rcode = 1
	goto bspexit
	end

if @filetype NOT IN ('D','F')
	begin
	select @msg = 'Currently only (F)ixed length and (D)elimited file types can be processed.', @rcode = 1
	goto bspexit
	end

------------------------------------------------------
----Find Estimate records, parse them, then upload into PMWH
select @ImportYN=EstimateInfo from PMUR with (nolock) where Template=@template
if @ImportYN = 'Y'
begin
	exec @rcode = dbo.vspPMImportEstimate @pmco, @template, @importid, @username, @retainpct, @errmsg output
	if @rcode <> 0
	begin
		select @msg = @msg + @errmsg, @rcode = 1
		goto cleanup
	end
end

--SELECT @msg = 'we have made it through estimate info', @rcode = 1
--GOTO bspexit


--Find Item records, parse them, then upload into PMWI
select @ImportYN=ContractItem from PMUR with (nolock) where Template=@template
if @ImportYN = 'Y' or @ItemOption = 'I' ---- #137957
begin
	exec @rcode = dbo.vspPMImportItem @pmco, @template, @importid, @username, @retainpct, @errmsg output
	if @rcode <> 0
	begin
		select @msg = @msg + @errmsg, @rcode = 1
		goto cleanup
	end
	else
	begin
		select @msg = @msg + @errmsg + char(13) + char(10)
	end
end

--Find Phase records, parse them, then upload into PMWP
select @ImportYN=Phase from PMUR with (nolock) where Template=@template
if @ImportYN = 'Y'
begin
	exec @rcode = dbo.vspPMImportPhase @pmco, @template, @importid, @username, @retainpct, @errmsg output
	if @rcode <> 0
	begin
		select @msg = @msg + @errmsg, @rcode = 1
		goto cleanup
	end
	else
	begin
		select @msg = @msg + @errmsg + char(13) + char(10)
	end
end

--Find CostType records, parse them, then upload into PMWD
select @ImportYN=CostType from PMUR with (nolock) where Template=@template
if @ImportYN = 'Y'
begin
	exec @rcode = dbo.vspPMImportCostType @pmco, @template, @importid, @username, @retainpct, @errmsg output
	if @rcode <> 0
	begin
		select @msg = @msg + @errmsg, @rcode = 1
		goto cleanup
	end
	else
	begin
		select @msg = @msg + @errmsg + char(13) + char(10)
	end
end

--Find SubDetail records, parse them, then upload into PMWS
select @ImportYN=SubcontractDetail from PMUR with (nolock) where Template=@template
if @ImportYN = 'Y'
begin
	exec @rcode = dbo.vspPMImportSubDetail @pmco, @template, @importid, @username, @retainpct, @errmsg output
	if @rcode <> 0
	begin
		select @msg = @msg + @errmsg, @rcode = 1
		goto cleanup
	end
	else
	begin
		select @msg = @msg + @errmsg + char(13) + char(10)
	end
end

--Find MatlDetail records, parse them, then upload into PMWM
select @ImportYN=MaterialDetail from PMUR with (nolock) where Template=@template
if @ImportYN = 'Y'
begin
	exec @rcode = dbo.vspPMImportMatlDetail @pmco, @template, @importid, @username, @retainpct, @errmsg output
	if @rcode <> 0
	begin
		select @msg = @msg + @errmsg, @rcode = 1
		goto cleanup
	end
	else
	begin
		select @msg = @msg + @errmsg + char(13) + char(10)
	end
end

---------- execute stored proc to update job data in PMWH
----exec @rcode = dbo.vspPMImportDataJob @pmco, @template, @importid, @username, @errmsg output
----if @rcode <> 0
----	begin
----	select @msg = @msg + @errmsg, @rcode = 1
----	goto bspexit
----	end
----
---------- execute stored proc to update item data into PMWI
----exec @rcode = dbo.vspPMImportDataItems @pmco, @template, @importid, @username, @retainpct, @errmsg output
----if @rcode <> 0
----	begin
----	select @msg = @msg + @errmsg, @rcode = 1
----	goto bspexit
----	end
----else
----	begin
----	select @msg = 'Import records loaded. ' + char(13) + char(10) + isnull(@errmsg,'') + char(13) + char(10)
----	end
----
---------- execute stored proc to update phase data into PMWP
----exec @rcode = dbo.vspPMImportDataPhases @pmco, @template, @importid, @username, @retainpct, @errmsg output
----if @rcode <> 0
----	begin
----	select @msg = @errmsg, @rcode = 1
----	goto bspexit
----	end
----else
----	begin
----	select @msg = @msg + @errmsg + char(13) + char(10)
----	end
----
---------- execute stored proc to update cost type data into PMWD
----exec @rcode = dbo.vspPMImportDataDetail @pmco, @template, @importid, @username, @retainpct, @errmsg output
----if @rcode <> 0
----	begin
----	select @msg = @errmsg, @rcode = 1
----	goto bspexit
----	end
----else
----	begin
----	select @msg = @msg + @errmsg + char(13) + char(10)
----	end
----
---------- execute stored proc to update material data into PMWM
----exec @rcode = dbo.vspPMImportDataMatl @pmco, @template, @importid, @username, @retainpct, @errmsg output
----if @rcode <> 0
----	begin
----	select @msg = @errmsg, @rcode = 1
----	goto bspexit
----	end
----else
----	begin
----	select @msg = @msg + @errmsg + char(13) + char(10)
----	end
----
---------- execute stored proc to update material data into PMWS
----exec @rcode = dbo.vspPMImportDataSubs @pmco, @template, @importid, @username, @retainpct, @errmsg output
----if @rcode <> 0
----	begin
----	select @msg = @errmsg, @rcode = 1
----	goto bspexit
----	end
----else
----	begin
----	select @msg = @msg + @errmsg + char(13) + char(10)
----	end

---------- now process data in import work files
---------- cost types
----exec @rcode = dbo.bspPMWDTrans @pmco, @importid, @phasegroup, @retainpct, @errmsg output
---------- phases
----exec @rcode = dbo.bspPMWPTrans @pmco, @importid, @phasegroup, @retainpct, @errmsg output
---------- items
----exec @rcode = dbo.bspPMWITrans @pmco, @importid, @phasegroup, @errmsg output
---- last part phase and clean-up

cleanup:

------ now process data in import work files
------ cost types
exec @rcode = dbo.bspPMWDTrans @pmco, @importid, @phasegroup, @retainpct, @errmsg output
------ phases
exec @rcode = dbo.bspPMWPTrans @pmco, @importid, @phasegroup, @retainpct, @errmsg output
------ items
exec @rcode = dbo.bspPMWITrans @pmco, @importid, @phasegroup, @errmsg output
------last part phase and clean-up
exec @rcode = dbo.bspPMLastPartPhase @pmco, @importid, @errmsg output


------ if user routine exists run at this time
if isnull(@userroutine,'') <> ''
	begin
	select @sqlstring = '', @executestring = ''
	set @sqlstring = 'exec dbo.' + @userroutine + ' @pmco, @importid, @errmsg output'
	set @paramdef = N'@pmco tinyint, @importid varchar(10), @errmsg varchar(255) OUTPUT';
	set @executestring = cast(@sqlstring as NVarchar(1000))
	exec sp_executesql @executestring, @paramdef, @pmco=@pmco, @importid=@importid, @errmsg=@errmsg OUTPUT;
	end

------ check for errors
exec @rcode = dbo.bspPMImportErrors @pmco, @importid, 'Y', 'Y', 'Y', 'Y', 'Y', @errmsg output
if @rcode <> 0
	begin
	select @msg = @msg + @errmsg ------, @rcode = 1
	end

select @rcode = 0






bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMImportData] TO [public]
GO
