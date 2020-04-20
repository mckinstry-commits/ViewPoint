SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMVCTableViewVal    Script Date:  ******/
CREATE proc [dbo].[bspPMVCTableViewVal]
/*************************************
 * Created By:	GF 03/29/2004
 * Modified By: GF 01/26/2005 - issue #26892,#119583,#122665,#29238 add totals views to SL,PO,MO,PCO,ACO grid forms
 *				GF 02/14/2008 - issue #126933 added JCJPDescGet for PMDocTrackPMSM
 *
 *
 *
 * validates PM Document Tracking Grid Table View by Grid Name
 *
 * Pass:
 * PM View Name
 * PM View Grid
 * PM Grid Table View
 *
 *
 * Success returns:
 *	0 and Template & Description
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@viewname varchar(10) = null, @form varchar(30) = null, @tableview varchar(20) = null,
 @msg varchar(255) output)
as 
set nocount on

declare @rcode int, @validlist varchar(100)

select @rcode = 0

---- validate View Name
if @viewname <> 'Viewpoint'
	begin
   	if not exists(select ViewName from PMVM where ViewName=@viewname)
   		begin
   		select @msg = 'Invalid Document Tracking View Name!', @rcode = 1
   		goto bspexit
   		end
   
   	---- validate Grid Form
   	if not exists(select Form from PMVG where ViewName=@viewname and Form=@form)
   	    begin
   	    select @msg = 'Invalid Document Tracking View Grid!', @rcode=1
   		goto bspexit
   	    end
   	end


---- PMSM Tables
if @form = 'PMDocTrackPMSM'
   	begin
   	set @validlist = '(PMSM,PMIM,PMSC,PMFMSub,PMFMResp,PMFMArch,PMPMSub,PMPMResp,PMPMArch,JCPM,JCJPDescGet)'
   	if @tableview not in ('PMSM','PMIM','PMSC','PMFMSub','PMFMResp','PMFMArch','PMPMSub','PMPMResp','PMPMArch','JCPM','JCJPDescGet')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end

---- PMRI Tables
if @form = 'PMDocTrackPMRI'
   	begin
   	set @validlist = '(PMRI,PMRIGrid,PMIM,PMSC,PMFMReq,PMFMSend,PMFMResp,PMPMResp,PMPMReq,PMPMSend)'
   	if @tableview not in ('PMRI','PMRIGrid','PMIM','PMSC','PMFMReq','PMFMSend','PMFMResp','PMPMResp','PMPMReq','PMPMSend')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMOP Tables
if @form = 'PMDocTrackPMOP'
   	begin
   	set @validlist = '(PMOP,PMOPTotals,PMIM)'
   	if @tableview not in ('PMOP','PMOPTotals','PMIM')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMRQ tables
if @form = 'PMDocTrackPMRQ'
   	begin
   	set @validlist = '(PMRQ,PMSC,PMFMResp,PMPMResp,PMRQGrid)'
   	if @tableview not in ('PMRQ','PMSC','PMFMResp','PMPMResp','PMRQGrid')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMOH tables
if @form = 'PMDocTrackPMOH'
   	begin
   	set @validlist = '(PMOH,PMOHTotals,PMIM)'
   	if @tableview not in ('PMOH','PMOHTotals','PMIM')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMOD tables
if @form = 'PMDocTrackPMOD'
   	begin
   	set @validlist = '(PMOD,PMSC,PMIM,PMFMRel,PMFMResp,PMPMResp)'
   	if @tableview not in ('PMOD','PMSC','PMIM','PMFMRel','PMFMResp','PMPMResp')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMIM Tables
if @form = 'PMDocTrackPMIM'
   	begin
   	set @validlist = '(PMIM,PMFM,PMPM2)'
   	if @tableview not in ('PMIM','PMFM','PMPM2')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- SLHD tables
if @form = 'PMDocTrackSLHD'
   	begin
   	set @validlist = '(SLHDPM,APVM,PMSLTotal)'
   	if @tableview not in ('SLHDPM','APVM','PMSLTotal')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- POHD tables
if @form = 'PMDocTrackPOHD'
   	begin
   	set @validlist = '(POHDPM,APVM,PMPOTotal)'
   	if @tableview not in ('POHDPM','APVM','PMPOTotal')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMPU List Tables
if @form = 'PMDocTrackPMPU'
   	begin
   	set @validlist = '(PMPU)'
   	if @tableview not in ('PMPU')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMMM Tables
if @form = 'PMDocTrackPMMM'
   	begin
   	set @validlist = '(PMMM,PMFM,PMPM2)'
   	if @tableview not in ('PMMM','PMFM','PMPM2')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMDL Tables
if @form = 'PMDocTrackPMDL'
   	begin
   	set @validlist = '(PMDL)'
   	if @tableview not in ('PMDL')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMDG Tables
if @form = 'PMDocTrackPMDG'
   	begin
   	set @validlist = '(PMDG,PMDGGrid,PMSC)'
   	if @tableview not in ('PMDG','PMDGGrid','PMSC')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMTL Tables
if @form = 'PMDocTrackPMTL'
   	begin
   	set @validlist = '(PMTL, PMSC, PMDT, PMIM, PMFMTest, PMPMTest, PMPL)'
   	if @tableview not in ('PMTL','PMSC','PMDT','PMIM','PMFMTest','PMPMTest','PMPL')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMIL Tables
if @form = 'PMDocTrackPMIL'
   	begin
   	set @validlist = '(PMIL, PMSC, PMDT, PMIM, PMFMInsp, PMPMInsp, PMPL)'
   	if @tableview not in ('PMIL','PMSC','PMDT','PMIM','PMFMInsp','PMPMInsp','PMPL')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMTM Tables
if @form = 'PMDocTrackPMTM'
   	begin
   	set @validlist = '(PMTM,PMIM,PMFMResp,PMPMResp)'
   	if @tableview not in ('PMTM','PMIM','PMFMResp','PMPMResp')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMPN Tables
if @form = 'PMDocTrackPMPN'
   	begin
   	set @validlist = '(PMPN, PMSC, PMIM, PMFM, PMPM2)'
   	if @tableview not in ('PMPN','PMSC','PMIM','PMFM','PMPM2')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- PMPF Tables #29238
if @form = 'PMDocTrackPMPF'
   	begin
   	set @validlist = '(PMPF, PMFM, PMPM2)'
   	if @tableview not in ('PMPN','PMFM','PMPM2')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end


---- INMO tables #26892
if @form = 'PMDocTrackINMO'
   	begin
   	set @validlist = '(INMOPM,PMMOTotal)'
   	if @tableview not in ('INMOPM','PMMOTotal')
   		begin
   		select @msg = 'Invalid table view ' + isnull(@tableview,'') + ' must be in ' + isnull(@validlist,'') + ' !', @rcode = 1
   		goto bspexit
   		end
   	goto bspexit
   	end




bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMVCTableViewVal] TO [public]
GO
