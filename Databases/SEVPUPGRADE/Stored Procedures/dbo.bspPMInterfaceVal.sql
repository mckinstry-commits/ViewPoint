SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************/
 CREATE    proc [dbo].[bspPMInterfaceVal]
 /*************************************
  * CREATED BY:	LM   4/15/98
  * MODIFIED By: LM   4/15/98
  *				GF 02/27/2002 - Added validation for material orders and material quotes
  *				GF	02/03/2003 - #19951 - use @msbatchid to signify quotes to interface
  *				GF 06/04/2003 - #21419 - check for inactive phase in JCJP and JCCH.SourceStatus = 'Y'
  *				GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
  *				GF 01/15/2003 - #20976 - added PCO parameters for pending CO to SL interface
  *				GF 03/17/2004 - #24094 - added checks to make sure POCO and SLCO records exist
  *				GF 11/03/2004 - #24409 added input parameter for internal approval date for SL/PO change orders.
  *				GF 12/01/2004 - #26332 - when error occurs do not delete bPMBC here - let bspPMInterfaceBatchClear cleanup
  *				GF 08/25/2005 - #29619 - added check for inactive phase/cost types for ACO
  *				GF 01/10/2005 - #119792 - check for inactive phase cost types needs to include interface date in where clause
  *				GF 03/27/2007 - #124142 - when interfacing original check both @aco, @pco are null.
  *				GF 12/12/2007 - issue #25569 use separate post closed job flags in JCCO enhancement.
  *				GF 12/23/2009 - issue #137117 added join to PMOI so that only PMOL ACO detail with ACO item insert
  *				GF 05/18/2010 - issue #139655 checking wrong return code for MO's
  *				JG 10/04/2010 - tfs# 491 - PM SL In/Exclusions
  *
  *
  *
  *
  * USAGE:
  * used by PMInterface to interface a project or change order from PM to other mods as specified
  *
  * Pass in :
  *	PMCo, Project, Mth, Options, ACO, INCo
  *
  * Output
  *  POBatchid, SLBatchid, MOBatchid, MSBatchid, errmsg
  *
  * Returns
  *	Error message and return code
  *
 *******************************/
 (@pmco bCompany, @project bJob, @mth bMonth, @options varchar(10), @aco bACO=null, @inco bCompany, 
  @pcotype bDocType, @pco bPCO=null, @internal_date bDate, @pobatchid int output, 
  @pocbbatchid int output, @slbatchid int output, @slcbbatchid int output, @mobatchid int output, 
  @msbatchid int output, @status tinyint output, @errmsg varchar(255) output)
 as
 set nocount on
 
declare @rcode int, @porcode int, @slrcode int, @morcode int, @msrcode int, @postatus int, @slstatus int,
		@mostatus int, @msstatus int, @errtext varchar(255), @apco bCompany, @postclosedjobs bYN,
		@jobstatus tinyint, @glco bCompany, @contract bContract, @startmonth bMonth, @pocbstatus int,
		@slcbstatus int, @mscbstatus int, @ApprovedAmt bDollar, @IntExt char(1), @coitem bACOItem,
		@phase bPhase, @costtype bJCCType, @validcnt int, @inactive_check varchar(2000),
		@postsoftclosedjobs bYN

select @rcode = 0, @porcode = 0, @slrcode = 0, @morcode = 0, @msrcode = 0,@postatus = 99,
		@slstatus = 99, @mostatus = 99, @msstatus = 99, @pocbstatus = 99, @slcbstatus = 99,
		@validcnt = 0

-- Validate and check to make sure Job is not closed
select @postclosedjobs=PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs, @glco=GLCo
from bJCCO with (nolock) where JCCo=@pmco
if @@rowcount = 0
	begin
	select @errmsg = 'Company ' + convert(varchar(3),@pmco) + ' is not a valid JC Company', @rcode=1
	goto bspexit
 	end

-- check project
select @jobstatus=JobStatus, @contract=Contract
from bJCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount=0
	begin
	select @errmsg='Job ' + isnull(@project,'') + ' must be setup in JC Job Master ' + convert(varchar(3),@pmco), @rcode=1
	goto bspexit
 	end
---- check job status and post closed job flags
if @jobstatus = 2 and @postsoftclosedjobs = 'N'
	begin
	select @errmsg='Job ' + isnull(@project,'') + ' is soft-closed and you are not allowed to post to soft-closed jobs in company ' + convert(varchar(3),@pmco), @rcode=1
	goto bspexit
 	end
---- check job status and post closed job flags
if @jobstatus = 3 and @postclosedjobs = 'N'
	begin
	select @errmsg='Job ' + isnull(@project,'') + ' is hard-closed and you are not allowed to post to hard-closed jobs in company ' + convert(varchar(3),@pmco), @rcode=1
	goto bspexit
 	end


if isnull(@aco,'') <> ''
 	begin
 	select @pcotype = null, @pco = null
 	end

if isnull(@pcotype,'') <> ''
 	begin
 	select @aco = null
 	if isnull(@pco,'') = ''
 		begin
 		select @errmsg = 'Missing pending change order.', @rcode = 1
 		goto bspexit
 		end
 	end
 
 
 -- Check the contract start month.  For originals, mth is entered in JCCH trigger;
 -- for Change Orders, POs, SLs, must be equal or after
 select @startmonth=StartMonth
 from bJCCM with (nolock) where JCCo=@pmco and Contract=@contract
 if @mth < @startmonth
 	begin
 	select @errmsg='The month must be equal to or after the contract start month. ' + convert(varchar(12),@startmonth), @rcode=1
 	goto bspexit
 	end
 
 --Check to make sure that if the IntExt flag is set to I, that the contract item amount is 0
 if isnull(@aco,'') <> ''
 	begin
	if exists(select ACOItem from bPMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco)
		begin
 		select @ApprovedAmt = max(ApprovedAmt), @coitem=(ACOItem)
 		from bPMOI with (nolock) where PMCo = @pmco and Project = @project and ACO = @aco
		group by ApprovedAmt, ACOItem
 		select @IntExt = IntExt
 		from bPMOH with (nolock) where PMCo = @pmco and Project = @project and ACO = @aco
 		if @ApprovedAmt <> 0  and @IntExt = 'I'
 			begin
 			select @rcode = 1,@errmsg = 'The change order being interfaced is flagged as internal, but change order item: ' + isnull(@coitem,'') + ' has an approved amount. Approved amount must be zero.'
 			goto bspexit
 			end
		end
		
 	-- -- -- need to check for inactive phase/cost types. JCOD insert trigger will not allow
	-- -- -- #119792 added l.InterfacedDate is null to where clause
 	set @inactive_check = ''
 	select @inactive_check = @inactive_check + 'Phase: ' + h.Phase + ' CostType: ' + convert(varchar(3),h.CostType) + ', '
 	from PMOL l
 	join JCCH h on l.PMCo=h.JCCo and l.Project=h.Job and l.PhaseGroup=h.PhaseGroup and l.Phase=h.Phase and l.CostType=h.CostType
 	where l.PMCo=@pmco and l.Project=@project and l.ACO=@aco and l.InterfacedDate is null and h.ActiveYN='N'
 	if @@rowcount <> 0
 		begin
 		select @errmsg = 'Inactive phase cost types found for ACO. ' + @inactive_check, @rcode = 1
 		goto bspexit
 		end
 	
 	---- check for PMOL detail records for a ACO Item and the Item does not exist. We need to delete
 	---- these lines so that the interface post does not error out during post. This is cleanup for
 	---- a prior problem where we could have orphan ACO detail records. #137117
 	set @validcnt = 0
	select @validcnt = (select count(*)
	from dbo.bPMOL l with (nolock)
	where l.PMCo=@pmco and l.Project=@project and l.ACO=@aco and l.SendYN='Y' and l.InterfacedDate is null
	and not exists(select 1 from dbo.bPMOI i with (nolock) where i.PMCo=l.PMCo and i.Project=l.Project
			and i.ACO=l.ACO and i.ACOItem=l.ACOItem and i.ACOItem is not null))
	if @validcnt > 0
		begin
		---- if we have orphans in PMOL, delete
		delete from dbo.bPMOL
		from dbo.bPMOL l with (nolock)
		where l.PMCo=@pmco and l.Project=@project and l.ACO=@aco and l.SendYN='Y' and l.InterfacedDate is null
		and not exists(select 1 from dbo.bPMOI i with (nolock) where i.PMCo=l.PMCo and i.Project=l.Project
					and i.ACO=l.ACO and i.ACOItem=l.ACOItem and i.ACOItem is not null)
		if @@rowcount <> @validcnt
			begin
			select @errmsg = 'There is existing PM ACO Item Phase Detail and the ACO Item is missing. Cannot Interface.', @rcode = 1
 			goto bspexit
 			end
 		end
 	end
 
 
 -- Get the AP Company from the PM Company
 select @apco = APCo from bPMCO with (nolock) where PMCo=@pmco
 
 -- check SLCo and POCo make sure companies exist
 if (select charindex('0',@options)) > 0
 	begin
 	if not exists(select * from bPOCO with (nolock) where POCo=@apco)
 		begin
 		select @errmsg = 'PO Company is not set up. Cannot interface Purchase Orders.', @rcode = 1
 		goto bspexit
 		end
 	end
 
 if (select charindex('1',@options)) > 0
 	begin
 	if not exists(select * from bSLCO with (nolock) where SLCo=@apco)
 		begin
 		select @errmsg = 'SL Company is not set up. Cannot interface Subcontracts.', @rcode = 1
 		goto bspexit
 		end
 	end
 
 
 -- Delete previous error entries in the interface error table
 delete bHQBE where Co=@apco and Mth=@mth and (BatchId=@pobatchid or BatchId=@slbatchid or BatchId=@pocbbatchid
                    or BatchId=@slcbbatchid or BatchId=@mobatchid)
 
 
---- check original
if isnull(@aco,'') = '' and isnull(@pco,'') = ''
	BEGIN
 	-- check JCJP.Active = 'N' with JCCH.SourceStatus='Y' ready to interface. Do not allow
 	select @phase=a.Phase, @costtype=a.CostType
 	from bJCCH a with (nolock)
 	join bJCJP b with (nolock) on b.JCCo=a.JCCo and b.Job=a.Job and b.Phase=a.Phase
 	where a.JCCo=@pmco and a.Job=@project and a.SourceStatus='Y' and b.ActiveYN='N'
 	if @@rowcount <> 0
 		begin
 		select @errmsg = 'Phase: ' + isnull(@phase,'') + ' is inactive. Activate Phase before interfacing.', @rcode=1
 		goto bspexit
 		end
 
 	-- PO
 	if (select charindex('0',@options)) > 0
 		begin
         -- validate data to be interfaced and insert it into the batch tables
 		exec @porcode = dbo.bspPMPOInterface @pmco,@project,@mth,@glco,@pobatchid output, @postatus output, @errmsg output
 
 		if @postatus = 0 and @porcode = 0 and @pobatchid <> 0
 			begin
 			-- if batch tables were successfully created, validate the batch
 			exec @porcode = dbo.bspPOHBVal @apco, @mth, @pobatchid, 'PM Intface', @errmsg output
 			select @postatus = Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@pobatchid
 			if @postatus <> 3
 				begin
 				select @errtext = 'POHB Batch Status is not 3 for PO Batch: ' + convert(varchar(6),@pobatchid)
 				exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pobatchid, @errtext, @errmsg output
 				select @porcode = 1
 				end
 			end
 		end
 
 	-- SL
 	if (select charindex('1',@options)) > 0
 		begin
 		exec @slrcode = dbo.bspPMSLInterface @pmco,@project,@mth,@glco, @slbatchid output, @slstatus output,
 						@slcbbatchid output, @slcbstatus output, @errmsg output
 
 		if @slstatus = 0 and @slrcode = 0 and @slbatchid <> 0
 			begin
 			exec @slrcode = dbo.bspSLHBVal @apco, @mth, @slbatchid, 'PM Intface', @errmsg output
 			select @slstatus=Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@slbatchid
 			if @slstatus <> 3
 				begin
 				select @errtext = 'SLHB Batch Status is not 3 for SL Batch: ' + convert(varchar(6),@slbatchid)
 				exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slbatchid, @errtext, @errmsg output
 				select @slrcode = 1
 				end
 			end
 
 		if @slcbstatus = 0 and @slrcode = 0 and @slcbbatchid <> 0
 			begin
 			exec @slrcode = dbo.bspSLCBVal @apco, @mth, @slcbbatchid, 'PM Intface', @errmsg output
 			select @slcbstatus=Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@slcbbatchid
             if @slcbstatus <> 3
 				begin
 				select @errtext = 'SLCB Batch Status is not 3 for SL Batch: ' + convert(varchar(6),@slcbbatchid)
 				exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slcbbatchid, @errtext, @errmsg output
 				select @slrcode = 1
 				end
 			end
 		end
 
 	-- MO
 	if (select charindex('2',@options)) > 0
 		begin
 		----139655
 		exec @morcode = dbo.bspPMMOInterface @pmco, @project, @mth, @glco, @inco, null, 
 						@mobatchid output, @mostatus output, @errmsg output
		----139655
 		if @mostatus = 0 and @morcode = 0 and @mobatchid <> 0
 			begin
 			exec @morcode = dbo.bspINMBVal @inco, @mth, @mobatchid, 'PM Intface', @errmsg output
 			select @mostatus=Status from bHQBC with (nolock) where Co=@inco and Mth=@mth and BatchId=@mobatchid
 			if @mostatus <> 3
 				begin
 				select @errtext = 'INMB Batch Status is not 3 for MO Batch: ' + convert(varchar(6),@mobatchid)
 				exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
 				select @morcode = 1
 				end
 			end
 		end
 
 	-- MS Quotes
 	if (select charindex('3',@options)) > 0
 		begin
 		exec @msrcode = dbo.bspPMMSInterface @pmco, @project, @mth, null, 'Y', null, @msbatchid output, @errmsg output
 		end
 END
 
 -- change order
 if isnull(@aco,'') <> ''
 BEGIN
 	-- PO
 	if (select charindex('0',@options)) > 0
 		begin
 		exec @porcode = dbo.bspPMPOACOInterface @pmco, @project, @mth, @aco, @glco, @pobatchid output,
 						@pocbbatchid output, @postatus output, @pocbstatus output, @errmsg output
 
 		if @postatus = 0 and @porcode = 0 and @pobatchid <> 0
 			begin
 			exec @porcode = dbo.bspPOHBVal @apco, @mth, @pobatchid, 'PM Intface', @errmsg output
 			select @postatus=Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@pobatchid
 			if @postatus <> 3
 				begin
 				select @errtext = 'POHB Batch Status is not 3 for PO Batch: ' + convert(varchar(6),@pobatchid)
 				exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pobatchid, @errtext, @errmsg output
 				select @porcode = 1
 				end
 			end
 
 		if @pocbbatchid <> 0 and @pocbstatus = 0
 			begin
 			exec @porcode = dbo.bspPOCBVal @apco, @mth, @pocbbatchid, 'PM Intface', @errmsg output
 			select @pocbstatus=Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@pocbbatchid
 			if @pocbstatus <> 3
 				begin
 				select @errtext = 'POCB Batch Status is not 3 for PO Batch: ' + convert(varchar(6),@pocbbatchid)
 				exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pocbbatchid, @errtext, @errmsg output
 				select @porcode = 1
 				end
 			end
 		end
 
 	-- SL
 	if (select charindex('1',@options)) > 0
 		begin
 		exec @slrcode = dbo.bspPMSLACOInterface @pmco, @project, @mth, @aco, @glco, null, null, null,
 						@slbatchid output, @slcbbatchid output, @slstatus output, @slcbstatus output, @errmsg output
 
 		if @slstatus = 0 and @slrcode = 0 and @slbatchid <> 0
 			begin
 			exec @slrcode = dbo.bspSLHBVal @apco, @mth, @slbatchid, 'PM Intface', @errmsg output
 			select @slstatus=Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@slbatchid
 			if @slstatus <> 3
 				begin
 				select @errtext = 'SLHB Batch Status is not 3 for SL Batch: ' + convert(varchar(6),@slbatchid)
 				exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slbatchid, @errtext, @errmsg output
 				select @slrcode = 1
 				end
 			end
 
 		if @slcbstatus = 0 and @slcbbatchid <> 0
 			begin
 			exec @slrcode = dbo.bspSLCBVal @apco, @mth, @slcbbatchid, 'PM Intface', @errmsg output
 			select @slcbstatus=Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@slbatchid
 			if @slcbstatus <> 3
 				begin
 				select @errtext = 'SLCB Batch Status is not 3 for SL Batch: ' + convert(varchar(6),@slcbbatchid)
 				exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slcbbatchid, @errtext, @errmsg output
 				select @slrcode = 1
 				end
 			end
 		end
 
 	-- MO
 	if (select charindex('2',@options)) > 0
 		begin
 		----139655
 		exec @morcode = dbo.bspPMMOInterface @pmco, @project, @mth, @glco, @inco, @aco,
 						@mobatchid output, @mostatus output, @errmsg output
		----139655
 		if @mostatus = 0 and @morcode = 0 and @mobatchid <> 0
 			begin
 			exec @morcode = dbo.bspINMBVal @inco, @mth, @mobatchid, 'PM Intface', @errmsg output
 			select @mostatus=Status from bHQBC with (nolock) where Co=@inco and Mth=@mth and BatchId=@mobatchid
 			if @mostatus <> 3
 				begin
 				select @errtext = 'INMB Batch Status is not 3 for MO Batch: ' + convert(varchar(6),@mobatchid)
 				exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
 				select @morcode = 1
 				end
 			end
 		end
 
 	-- MS Quotes
 	if (select charindex('3',@options)) > 0
 		begin
 		exec @msrcode = dbo.bspPMMSInterface @pmco, @project, @mth, @aco, 'Y', null, @msbatchid output, @errmsg output
 		end
 END
 
 -- pending change order
 if isnull(@pco,'') <> ''
 BEGIN
 	-- SL
 	if (select charindex('1',@options)) > 0
 		begin
 		exec @slrcode = dbo.bspPMSLACOInterface @pmco, @project, @mth, null, @glco, @pcotype, @pco, @internal_date,
 						@slbatchid output, @slcbbatchid output, @slstatus output, @slcbstatus output, @errmsg output
 		if @slstatus = 0 and @slrcode = 0 and @slbatchid <> 0
 			begin
 			exec @slrcode = dbo.bspSLHBVal @apco, @mth, @slbatchid, 'PM Intface', @errmsg output
 			select @slstatus=Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@slbatchid
 			if @slstatus <> 3
 				begin
 				select @errtext = 'SLHB Batch Status is not 3 for SL Batch: ' + convert(varchar(6),@slbatchid)
 				exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slbatchid, @errtext, @errmsg output
 				select @slrcode = 1
 				end
 			end
 
 		if @slcbstatus = 0 and @slcbbatchid <> 0
 			begin
 			exec @slrcode = dbo.bspSLCBVal @apco, @mth, @slcbbatchid, 'PM Intface', @errmsg output
 			select @slcbstatus=Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@slbatchid
 			if @slcbstatus <> 3
 				begin
 				select @errtext = 'SLCB Batch Status is not 3 for SL Batch: ' + convert(varchar(6),@slcbbatchid)
 				exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slcbbatchid, @errtext, @errmsg output
 				select @slrcode = 1
 				end
 			end
 		end
 END
 
 
 -- -- -- if errors have occurred need to cleanup
 if isnull(@porcode,0) <> 0 or isnull(@slrcode,0) <> 0 or isnull(@morcode,0) <> 0 or @msrcode <> 0
 BEGIN
 	-- -- -- POHB/POIB
 	if isnull(@pobatchid,0) <> 0
 		begin
 		delete bPOIB where Co=@apco and Mth=@mth and BatchId=@pobatchid
 		delete bPOHB where Co=@apco and Mth=@mth and BatchId=@pobatchid
 		exec @rcode = dbo.bspHQBCExitCheck @apco, @mth, @pobatchid, 'PM Intface', 'POHB', @errmsg output
 		if @rcode <> 0
 			begin
 			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel POHB batch '
 			end
 -- -- -- 		delete bPMBC where Co=@pmco and Project=@project and Mth=@mth and BatchTable='POHB'
 -- -- -- 				and BatchId=@pobatchid and BatchCo=@apco
 		end
 
 	-- -- -- POCB
 	if isnull(@pocbbatchid,0) <> 0
 		begin
 		delete bPOCB where Co=@apco and Mth=@mth and BatchId=@pocbbatchid
 		exec @rcode = dbo.bspHQBCExitCheck @apco, @mth, @pocbbatchid, 'PM Intface', 'POCB', @errmsg output
 		if @rcode <> 0
 			begin
 			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel POCB batch '
 			end
 -- -- -- 		delete bPMBC where Co=@pmco and Project=@project and Mth=@mth and BatchTable='POCB'
 -- -- -- 				and BatchId=@pocbbatchid and BatchCo=@apco
 		end
 
 	-- -- -- SLHB/SLIB
 	if isnull(@slbatchid,0) <> 0
 		begin
 		delete bSLIB where Co=@apco and Mth=@mth and BatchId=@slbatchid
 		delete bSLHB where Co=@apco and Mth=@mth and BatchId=@slbatchid
 		delete vSLInExclusionsBatch where Co=@apco and Mth=@mth and BatchId=@slbatchid -- JG TFS# 491
 		exec @rcode = dbo.bspHQBCExitCheck @apco, @mth, @slbatchid, 'PM Intface', 'SLHB', @errmsg output
 		if @rcode <> 0
 			begin
 			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel SLHB batch '
 			end
 -- -- -- 		delete bPMBC where Co=@pmco and Project=@project and Mth=@mth and BatchTable='SLHB'
 -- -- -- 				and BatchId=@slbatchid and BatchCo=@apco
 		end
 
 	-- -- -- SLCB
 	if isnull(@slcbbatchid,0) <> 0
 		begin
 		delete bSLCB where Co=@apco and Mth=@mth and BatchId=@slcbbatchid
 		exec @rcode = dbo.bspHQBCExitCheck @apco, @mth, @slcbbatchid, 'PM Intface', 'SLCB', @errmsg output
 		if @rcode <> 0
 			begin
 			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel SLCB batch '
 			end
 -- -- -- 		delete bPMBC where Co=@pmco and Project=@project and Mth=@mth and BatchTable='SLCB'
 -- -- -- 				and BatchId=@slcbbatchid and BatchCo=@apco
 		end
 
 
 	-- -- -- INMB/INIB
 	if isnull(@mobatchid,0) <> 0
 		begin
 		delete bINIB where Co=@inco and Mth=@mth and BatchId=@mobatchid
 		delete bINMB where Co=@inco and Mth=@mth and BatchId=@mobatchid
 		exec @rcode = dbo.bspHQBCExitCheck @inco, @mth, @mobatchid, 'PM Intface', 'INMB', @errmsg output
 		if @rcode <> 0
 			begin
 			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel INMB batch '
 			end
 -- -- -- 		delete bPMBC where Co=@pmco and Project=@project and Mth=@mth and BatchTable='INMB'
 -- -- -- 				and BatchId=@mobatchid and BatchCo=@inco
 		end
 
 	select @rcode = 1
 	select @errmsg = ' Errors exist - cannot interface data. '
 	select @status=2
 END
 
 
 -- everything is valid
 if isnull(@porcode,0) = 0 and isnull(@slrcode,0) = 0 and isnull(@morcode,0) = 0 and isnull(@msrcode,0) = 0
 	begin
 	select @errmsg = 'Interface data validated. ', @status = 3
 	end
 
 
 
 bspexit:
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMInterfaceVal] TO [public]
GO
