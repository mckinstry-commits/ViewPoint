SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[cvsp_CMS_PMSLInitConversion]  (@pmco bCompany=null, @project bJob=null, 
		@rectype char(1)=null, @cotype bDocType=null,
		@co bACO=null, @coitem bACOItem=null, @pmslseqlist varchar(2000) = '', 
		@CMSContract varchar(10)='',@msg varchar(255) output)
as
set nocount on
/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Called by cvsp_CGC_SLNumbers to initialize SL's
	Created on:	10.12.09
	Author:     JJH    
	Revisions:	1. None
**/





declare @rcode int, @retcode int, @validcnt int, @slno varchar(1), @sigpartjob bYN, @validpartjob varchar(30),
		@slcharsproject tinyint, @slcharsvendor tinyint, @vendor bVendor, @seq int,
		@projectpart bProject, @vendorPart varchar(30), @SL bSL, @apco bCompany, @slitem bItem,
		@formattedsl varchar(10), @tmpsl varchar(30), @phase bPhase, @itemtype int,
		@slseqlen int, @subco int, @phasegroup bGroup, @mseq int,
		@slitemfrompm bItem, @paddedstring varchar(60), @addon tinyint, @addonpct bPct,
		@addonamt bDollar, @sladdonamt bDollar, @pmaddonamt bDollar, @addonseq int,
		@usephasedesc bYN, @slrcode int, @slmsg varchar(60), @defpcotype bDocType, @defpco bPCO,
		@defpcoitem bPCOItem,@defaco bACO, @defacoitem bACOItem, @tmpseq varchar(30),
		@sigchars smallint, @partseq int, @tmpproject varchar(30), @actchars smallint,
		@defrecordtype char(1), @sllength varchar(10), @slmask varchar(30), @dummy_sl varchar(30),
		@slitemdescription bItemDesc, @lastslseq int, @tmpsl1 bSL, @i int, @value varchar(1),
		@tmpseq1 varchar(10), @active bYN, @phasemsg varchar(100), @opencursor int, @recordtype varchar(1),
		@pcotype bDocType, @pco bACO, @pcoitem bACOItem, @aco bACO, @acoitem bACOItem,
		@lastvendor bVendor, @slstartseq smallint, @lastCMSCont varchar(10), @cmscontract varchar(10)

select @rcode = 0, @opencursor = 0, @slrcode = 0, @lastslseq = 0, @lastvendor = null,
		@phasemsg = '', @msg = ''

if @pmco is null or @project is null
	begin
	select @msg = 'Missing information!', @rcode = 1
	goto bspexit
	end

----if @rectype = 'C' and isnull(@cotype,'') = ''  select @rectype='A'
----if @rectype = 'C' and isnull(@cotype,'') <> '' select @rectype = 'P'

if @rectype <> 'O' and @rectype <> 'P' and @rectype <> 'A'
       begin
       select @msg = 'Missing Record Type!', @rcode = 1
       goto bspexit
       end

------ get input mask for bSL
select @slmask=InputMask, @sllength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bSL'
if isnull(@slmask,'') = '' select @slmask = 'L'
if isnull(@sllength,'') = '' select @sllength = '10'
if @slmask in ('R','L')
   	begin
   	select @slmask = @sllength + @slmask + 'N'
   	end

------ get HQ company info
select @apco=p.APCo, @slno=p.SLNo, @sigpartjob=p.SigPartJob, @sigchars= p.SigCharsSL,
          @slcharsproject=p.SLCharsProject, @slcharsvendor=p.SLCharsVendor, @slseqlen=p.SLSeqLen,
          @usephasedesc=p.PhaseDescYN, @slstartseq=p.SLStartSeq
from bHQCO h with (nolock) 
	join bPMCO p with (nolock) on h.HQCo=p.APCo where p.PMCo=@pmco

------ check significant characters of job, if null or zero then not valid.
if @sigchars is null or @sigchars = 0 select @sigpartjob = 'N'

------ set valid part job
if @sigpartjob = 'Y'
       begin
       if @sigchars > len(@project) select @sigchars = len(@project)
       select @validpartjob = substring(@project,1,@sigchars)
       end
else
       begin
       select @validpartjob = @project, @sigchars = len(@project)
       end

select @tmpproject = rtrim(ltrim(@validpartjob)), @actchars = len(@tmpproject)
------ get rid of leading spaces
select @projectpart = substring(ltrim(@project),1,@slcharsproject)
select @itemtype = 0
select @slitemfrompm = 0
--select @slitem = 1
select @mseq = 0

------ need to reset @slcharsproject to project part without any leading spaces
select @slcharsproject = datalength(ltrim(@projectpart))



declare bcPMSL cursor LOCAL FAST_FORWARD
	for 
select Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem, Vendor , SLItem, udSLContractNo
from bPMSL where PMCo=@pmco and Project=@project and isnull(SL,'') = '' and Vendor is not null
	and udSLContractNo=@CMSContract
	and bPMSL.Phase is not null
Order By Vendor, SLItemType, udSLContractNo, Seq--jh

-- open cursor
open bcPMSL
select @opencursor = 1

PMSL_loop:
fetch next from bcPMSL into @seq, @recordtype, @pcotype, @pco, @pcoitem, @aco, @acoitem, @vendor, @slitem, @cmscontract
if @@fetch_status <> 0 goto PMSL_end

---- first check record type 'O' - original or 'C' - change order ('A','P')
if @recordtype <> 'O' and @rectype = 'O' goto PMSL_loop -- originals only
if @recordtype = 'O' and @rectype <> 'O' goto PMSL_loop -- change orders only


---- if initalizing selected sequences check sequence list to the sequence, if not in list goto next
if isnull(@pmslseqlist,'') <> ''
	begin
	if charindex(';' + convert(varchar(6),@seq) + ';', @pmslseqlist) = 0 goto PMSL_loop
	end

---- if @rectype = 'P' pending change order PMSL data must match CO data if we are
---- restricting to a selected PCO and PCO Item
if @rectype = 'P'
	begin
	---- pending values must exist
	if isnull(@pcotype,'') = '' goto PMSL_loop
	if isnull(@pco,'') = '' goto PMSL_loop
	if isnull(@pcoitem,'') = '' goto PMSL_loop
	---- ACO and ACO item must be empty
	if isnull(@aco,'') <> '' goto PMSL_loop
	if isnull(@acoitem,'') <> '' goto PMSL_loop
	---- pending values must equal restrictions
	if isnull(@cotype,'') <> ''
		begin
		if isnull(@pcotype,'') <> isnull(@cotype,'') goto PMSL_loop
		if isnull(@pco,'') <> isnull(@co,'') goto PMSL_loop
		if isnull(@pcoitem,'') <> isnull(@coitem,'') goto PMSL_loop
		end
	end

-- if @rectype = 'A' approved change order PMSL data must match CO data if we are
-- restricting to a selected ACO and ACO Item
if @rectype = 'A'
	begin
	-- approved values must exist
	if isnull(@aco,'') = '' goto PMSL_loop
	if isnull(@acoitem,'') = '' goto PMSL_loop
	-- approved values must equal restrictions
	if isnull(@co,'') <> ''
		begin
		if isnull(@aco,'') <> isnull(@co,'') goto PMSL_loop
		if isnull(@acoitem,'') <> isnull(@coitem,'') goto PMSL_loop
		end
	end

-- valid record, now try to create subcontract
select @subco = null

-- reset values when vendor changes
if isnull(@lastvendor,'') <> @vendor 
	begin
	select @slitemfrompm = 0
	select @mseq = @mseq + 1
	--select @slitem = 1
	end
else
	if isnull(@lastCMSCont,'')<>@CMSContract
	begin
	select @slitemfrompm = 0
	select @mseq = @mseq + 1
	end


--select 'Sequence: ' + convert(varchar(6),@seq)
--goto PMSL_loop

select @lastvendor = @vendor, @lastCMSCont=@CMSContract
-- read PMSL data
select @phasegroup=PhaseGroup, @phase=Phase, @addon=SLAddon, @addonpct=SLAddonPct,
		@itemtype=SLItemType, @defpcotype=PCOType, @defpco=PCO, @defpcoitem=PCOItem,
		@defaco=ACO, @defacoitem=ACOItem, @defrecordtype=RecordType, @slitemdescription=SLItemDescription
from bPMSL with (nolock) where PMCo=@pmco and Project=@project and Vendor=@vendor and Seq=@seq
	and udSLContractNo=@CMSContract
-- if phase is inactive do not initialize - btPMSLu trigger will error out.
select @active=ActiveYN from bJCJP with (nolock)
where JCCo = @pmco and Job = @project and Phase = @phase
if @@rowcount = 1 and @active = 'N'
	begin
	select @phasemsg = 'One or more subcontract phases are inactive, will not be initialized, ' + isnull(@phase,'') + '.', @rcode = 1
	goto PMSL_loop
	end

-- get SLItem description
if isnull(@slitemdescription,'') = ''
	begin
   	exec @slrcode = dbo.bspPMSLItemDescDefault @pmco, @project, @phasegroup, @phase, @defpcotype,
   					@defpco, @defpcoitem, @defaco, @defacoitem, @seq, @slmsg output
   	if @slrcode <> 0
   	    begin
   	    select @slitemdescription='Description not found'
   	    end
   	else
   	    begin
   	    select @slitemdescription=@slmsg
   	    end
   	end



-- if we are building the subcontract by seq, then we need to retreive the last seq
-- used to build the last subcontract number, then add one to it
select @tmpsl = null, @tmpsl1 = null
if @slno='P'
	begin
	if exists(select 1 from bPMSL WITH (NOLOCK) where SLCo=@apco and PMCo=@pmco
				and substring(Project,1,@sigchars)=@validpartjob and SL is not null
			) 
		begin
		-- max from PMSL
		select @tmpsl = max(SL) from bPMSL WITH (NOLOCK)
		where SLCo=@apco and PMCo=@pmco and substring(Project,1,@sigchars)=@validpartjob
		and SL is not null and substring(SL,1,len(@projectpart)) = @projectpart
		and datalength(rtrim(SL)) = len(@projectpart) + @slseqlen
		--and udSLContractNo=@CMSContract --need to leave remmed out or only pulls first subcontract
		-- now use highest to get next sequence
		if isnull(@tmpsl,'') <> '' and isnull(@tmpsl1,'') = '' select @tmpsl1 = @tmpsl
		-- now parse out the seq part by using company definitions
		select @tmpseq = substring(reverse(rtrim(@tmpsl)),1, @slseqlen), @i = 1, @tmpseq1 = ''
		while @i <= len(@tmpseq)
			begin
			select @value = substring(@tmpseq,@i,1)
			if @value not in ('0','1','2','3','4','5','6','7','8','9')
				select @i = len(@tmpseq)
			else
				select @tmpseq1 = @tmpseq1 + @value
					
			select @i = @i + 1
			end
		-- check if numeric
		if isnumeric(@tmpseq1) = 1 select @mseq = convert(int,reverse(@tmpseq1)+1)
		end
	else
		begin
		---- no subcontracts exist for project so use the @slstartseq if there is one
		if @slstartseq is not null select @mseq = @slstartseq
		end
	end

update bSLHD set udSLContractNo=bPMSL.udSLContractNo
from bSLHD
	join bPMSL on bSLHD.SLCo=bPMSL.SLCo and bSLHD.SL=bPMSL.SL and bSLHD.Job=bPMSL.Project and bSLHD.Vendor=bPMSL.Vendor
where bSLHD.SLCo=@pmco and bSLHD.Job=@project and bSLHD.Vendor=@vendor


-- convert Vendor based on Co parameters
select @vendorPart = reverse(substring(reverse('0000000000000000000' + ltrim(str(@vendor))),1,@slcharsvendor))
-- need to pad the seq with leading zeros to the amount specified in company file @slseqlen
select @paddedstring = reverse(substring(reverse('0000000000000000000' + ltrim(str(@mseq))),1,@slseqlen))
select @formattedsl = null



if @slno = 'P' select @lastslseq = @mseq
-- Need to see if there are any subcontracts set up already for this vendor.
-- This must be done in two parts depending on how the subcontract is being created.
-- If creating using project/seq (P), then consider subcontract status.
-- Remember that the subcontract is added to SL in the PMSL triggers.
-- If a valid subcontract is found then use.
if @slno = 'P'
	begin
	select @formattedsl = max(SL) from bSLHD with (nolock) 
	where SLCo=@apco and JCCo=@pmco and Vendor=@vendor and substring(Job,1,@sigchars)=@validpartjob and Status in (0,3)
		and udSLContractNo=@CMSContract
	if @@rowcount = 0 select @formattedsl = null
	end

if @slno = 'V'
	begin
	select @formattedsl = max(SL) from bSLHD with (nolock) 
	where SLCo=@apco and JCCo=@pmco and Vendor=@vendor and substring(Job,1,@sigchars)=@validpartjob
		and udSLContractNo=@CMSContract
	if @@rowcount = 0 select @formattedsl = null
	end

-- if no valid subcontract found then build using appropiate value
if @formattedsl is null
	begin
   	if @slno = 'V'
   		begin
   		set @dummy_sl = ltrim(rtrim(@projectpart)) + @vendorPart
   		exec @retcode = dbo.bspHQFormatMultiPart @dummy_sl, @slmask, @formattedsl output
   		end
   	else
   		begin
   		set @dummy_sl = ltrim(rtrim(@projectpart)) + @paddedstring
   		exec @retcode = dbo.bspHQFormatMultiPart @dummy_sl, @slmask, @formattedsl output
   		end
	end



-- check if subcontract already set up under a different job
if exists(select 1 from bSLHD with (nolock) where SLCo=@apco and JCCo=@pmco and SL=@formattedsl
           and substring(Job,1,@sigchars)<>@validpartjob )
	begin
	select @msg = 'One or more subcontracts are already set up under a different project.', @rcode = 1
	goto PMSL_loop
	end

-- check if subcontract already setup under a different vendor
if exists(select 1 from bSLHD with (nolock) where SLCo=@apco and JCCo=@pmco and SL=@formattedsl and Vendor<>@vendor
			)
	begin
	select @msg = 'One or more subcontracts are already set up under a different vendor.' + isnull(@formattedsl,''), @rcode = 1
	goto PMSL_loop
	end



-- Check to see if it is an Approved change order, if so then fill in SUBCo if necessary
select @subco = null
if @defrecordtype = 'C' and isnull(@defaco,'') <> ''
	begin
   	if @itemtype in (1,2,4)
       	begin
       	exec @slrcode = dbo.bspPMSLSubCoGet @pmco, @project, @apco, @formattedsl, @slitem, @itemtype,
					@seq, @subco output, @defaco, @defacoitem, @vendor, @slmsg output
       	if @slrcode <> 0 or @subco = 0 select @subco = null
       	end
	end


-- update PMSL with formatted SL and item
begin transaction
update bPMSL set SL=@formattedsl,SubCO=@subco, SLItemDescription=@slitemdescription
where PMCo=@pmco and Project=@project and Seq=@seq and udSLContractNo=@CMSContract
if @@rowcount = 0
	begin
	select @msg = 'Error updating PMSL', @rcode=1
	rollback transaction
	goto bspexit
	end

commit transaction


goto PMSL_loop

PMSL_end:
	if @opencursor = 1
		begin
		close bcPMSL
		deallocate bcPMSL
		select @opencursor = 0
		end






bspexit:
	if @opencursor = 1
		begin
		close bcPMSL
		deallocate bcPMSL
		select @opencursor = 0
		end

	if @rcode <> 0
		begin
		if isnull(@phasemsg,'') <> '' select @msg = isnull(@msg,'') + char(13) + char(10) + @phasemsg
		select @msg = isnull(@msg,'')
		end


GO
