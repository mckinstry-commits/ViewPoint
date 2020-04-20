SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPMVGInitialize]
/*************************************
 * Created By:	GF 04/01/2004
 * Modified By: GF 01/26/2005 - issue #26892 add material order tab to views
 *				GF 03/20/2007 - issue #28097 changes for 6.x now using PMVG.Form instead of PMVG.ViewGrid
 *				GF 03/26/2007 - issue @29238 added project firms tab and inputs
 *				CC 03/03/2010 - issue #130945 added project email tab
 *				AW 01/11/2013 TK-20642 / 147448 PMVG needs to exist prior to PMVC so moved out of trigger because of FK
 *
 *
 *
 * called from PMVM insert trigger or PMDocTrack form to initialize 
 * the PMVG grid views if missing
 *
 * Pass:
 * PM View Name
 *
 *
 * Success returns:
 *	0 
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@viewname varchar(10) = null,  @msg varchar(255) output)
as 
set nocount on

declare @rcode int

select @rcode = 0

if isnull(@viewname,'') = ''
   	begin
   	select @msg = 'Invalid Document Tracking View Name', @rcode = 1
   	goto bspexit
   	end


---- first check to make sure the Viewpoint Grid Form defaults exist if not then add these first
---- create each grid form view in PMVG if missing, the Viewpoint default columns will
---- be loaded from the PMVG insert trigger
if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMSM')
   	begin
   	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'Submittals', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMSM', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMRI')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'Request for Information', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMRI', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMOP')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMOP', 'Pending Change Orders', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMOP', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMRQ')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMRQ', 'Request for Quote', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMRQ', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMOH')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMOH', 'Approved Change Orders', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMOH', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMOD')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'Other Documents', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMOD', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMIM')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMIM', 'Issues', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMIM', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackSLHD')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackSLHD', 'Subcontracts', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackSLHD', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPOHD')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPOHD', 'Purchase Orders', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPOHD', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMPU')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMPU', 'Punch Lists', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMPU', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMMM')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMMM', 'Meeting Minutes', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMMM', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMDL')
   	begin
   	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMDL', 'Daily Log', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMDL', @msg output
	if @rcode <> 0 goto bspexit

   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMDG')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMDG', 'Drawing Log', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMDG', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMTL')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMTL', 'Test Log', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMTL', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMIL')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMIL', 'Inspection Log', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMIL', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMTM')
   	begin
   	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMTM', 'Transmittals', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMTM', @msg output
	if @rcode <> 0 goto bspexit
   	end

if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMPN')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMPN', 'Project Notes', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMPN', @msg output
	if @rcode <> 0 goto bspexit
   	end

---- issue #26892
if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackINMO')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackINMO', 'Material Orders', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackINMO', @msg output
	if @rcode <> 0 goto bspexit
   	end

---- issue #29238
if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackPMPF')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackPMPF', 'Project Firms', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackPMPF', @msg output
	if @rcode <> 0 goto bspexit
   	end

---- issue 130945
if not exists(select ViewName from PMVG where ViewName='Viewpoint' and Form='PMDocTrackEmail')
   	begin
	insert PMVG(ViewName, Form, GridTitle, Hide)
   	select 'Viewpoint', 'PMDocTrackEmail', 'Project Email', 'N'
	exec @rcode = dbo.bspPMVCInitialize 'Viewpoint', 'PMDocTrackEmail', @msg output
	if @rcode <> 0 goto bspexit
   	end


---- insert grids that do not exist in PMVG
insert PMVG (ViewName, Form, GridTitle, Hide)
select @viewname, a.Form, a.GridTitle, a.Hide
from PMVG a where a.ViewName = 'Viewpoint'
and not exists(select c.ViewName from PMVG c where c.ViewName=@viewname and c.Form=a.Form)



bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspPMVGInitialize] TO [public]
GO
