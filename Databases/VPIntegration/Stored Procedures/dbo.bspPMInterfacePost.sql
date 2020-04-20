SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMInterfacePost    Script Date: 8/28/99 9:36:24 AM ******/
CREATE  proc [dbo].[bspPMInterfacePost]
/*************************************
 * Created By:  LM 04/24/1998
 * Modified By: LM 04/30/1999 - adding interfacing pending change order addons to jcod
 *              GF 03/30/2000 - adding interfacing force phase for change orders.
 *              GF 08/17/2000 - use @mth as JCOI Approved Month
 *              GF 08/28/2000 - update Internal/External flag from PMOH to JCOH
 *              GF 01/07/2001 - fix for add-ons w/same phase cost type bJCOD duplicate key error
 *              GF 02/06/2001 - enhancement to send bill group from PMOI to JCOI
 *              TV 04/05/2001 - Moving ChangeDays from Header to Line level
 *              GF 04/23/2001 - When interfacing addons, if exists in JCOD update - currently does insert only.
 *				GF 02/28/2002 - Added interface for MO and MS quotes.
 *				GF 01/15/2003 - issue #20976 added parameters for pending change orders to interface to SL.
 *				GF 11/02/2004 - issue #25054 update the PMOI.InterfacedDate when ACO is interfaced.
 *				GF 02/09/2005 - issue #27065 do not update JCOH.ChangeDays here, handled in JCOI triggers.
 *				GF 09/01/2006 - issue #121954 update JCOH with PMOH like named user memos.
 *				GF 12/30/2008 - issue #129669 cost add-ons enhancement
 *				GF 01/02/2009 - issue #130929 update PMOI.InterfacedBy
 *				GF 08/14/2009 - issue #135150 removed useless check in SLCB and POCB when aco is null
 *				GF 12/23/2009 - issue #137117 added join to PMOI so that only PMOL ACO detail with ACO item insert
 *				GF 09/12/2010 - issue #141031 changed to use function vfDateOnly
				AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
 *
 *
 *
 * USAGE:
 * used by PMInterface to post a project or change order from PM to PO, SL, MO, MS
 *
 * Pass in :
 *	PMCo, Mth, Project, ACO, Options, INCo
 *
 * Output
 *  POBatchid, POCBBatchId, SLBatchid, SLCBBatchId, MOBatchid, MSBatchid, Status, errmsg
 *
 * Returns
 *	Error message and return code
 *
 *******************************/
(@pmco bCompany=0, @mth bMonth=null, @project bJob=null, @aco bACO=null, @options varchar(10)=null, 
 @inco bCompany=0, @pcotype bDocType, @pco bPCO=null, @pobatchid int=0 output, @pocbbatchid int=0 output, 
 @slbatchid int=0 output, @slcbbatchid int=0 output, @mobatchid int=0 output, @msbatchid int=0 output, 
 @status tinyint=0 output, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @porcode int, @slrcode int, @morcode int, @msrcode int, @opencursor tinyint,
   		@errtext varchar(255), @dateposted bDate, @apco bCompany, @contract bContract,
   		@totalcount int, @updatecount int, @insertcount int, @forcephase bYN,
   		@pmoapcotype bDocType, @pmoapco bPCO, @pmoapcoitem bPCOItem, @addonamount bDollar,
   		@pmoiaco bACO, @pmoiacoitem bACOItem, @phasegroup bGroup, @phase bPhase, @costtype bJCCType,
   		@jcchum bUM, @addon int, @pmbeseq int, @pmoh_jcoh_ud_flag bYN, @columnname varchar(120),
		@joins varchar(2000), @where varchar(1000), @msg varchar(255), @pmoi_jcoi_ud_flag bYN

select @rcode = 0, @porcode = 0, @slrcode = 0, @morcode = 0, @msrcode = 0, @opencursor = 0,
   	   @pmoh_jcoh_ud_flag = 'N', @pmoi_jcoi_ud_flag = 'N'
   	   
----#141031
SET @dateposted = dbo.vfDateOnly() 

---- validate parameters
If isnull(@pmco,0) = 0 or isnull(@mth,'') = '' or isnull(@project,'') = ''
   	begin
   	select @errmsg = 'Missing Company, Project, or Month'
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

---- pseudo cursor to check for like named user memos in PMOH and JCOH to be updated
select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.bPMOH')
while @columnname is not null
begin

	if exists(select * from syscolumns where name = @columnname and id = object_id('dbo.bJCOH'))
		begin
		select @pmoh_jcoh_ud_flag = 'Y'
		goto jcohudcheck_done
		end
   
select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.PMOH') and name > @columnname
if @@rowcount = 0 select @columnname = null
end
jcohudcheck_done:

---- pseudo cursor to check for like named user memos in PMOI and JCOI to be updated
select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.bPMOI')
while @columnname is not null
begin

	if exists(select * from syscolumns where name = @columnname and id = object_id('dbo.bJCOI'))
		begin
		select @pmoi_jcoi_ud_flag = 'Y'
		goto jcoiudcheck_done
		end
   
select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.PMOi') and name > @columnname
if @@rowcount = 0 select @columnname = null
end
jcoiudcheck_done:



---- get APCO from PMCO
select @apco=APCo from bPMCO WITH (NOLOCK) where PMCo=@pmco
---- delete batch errors
delete bHQBE where Co=@apco and Mth=@mth and BatchId in (@pobatchid, @slbatchid, @pocbbatchid, @slcbbatchid)

---- Need to update the Contract Status to open if still set to pending
Select @contract=Contract from bJCJM WITH (NOLOCK) where JCCo=@pmco and Job=@project
Update bJCCM set ContractStatus=1 where JCCo=@pmco and Contract=@contract and ContractStatus=0

---- Need to update the Job Status to open if still set to pending
Update bJCJM set JobStatus=1 where JCCo=@pmco and Job=@project and JobStatus=0

---- Need to update JCCH entries - where sourcestatus = Y, set it to I and change active flag to Y 
if isnull(@aco,'') = ''
   	begin
   	-- For Orig Est. - Send Flag = Y and Not in a batch
   	--#142278
    UPDATE  bJCCH
    SET     SourceStatus = 'I',
            ActiveYN = 'Y',
            InterfaceDate = dbo.vfDateOnly() ----#141031
    WHERE   JCCo = @pmco
            AND Job = @project
            AND SourceStatus = 'Y'
            AND NOT EXISTS ( SELECT 1
                             FROM   dbo.bPOIB p
                                    JOIN dbo.bJCCH j ON p.PostToCo = j.JCCo
                                                        AND p.Job = j.Job
                                                        AND p.PhaseGroup = j.PhaseGroup
                                                        AND p.Phase = j.Phase
                                                        AND p.JCCType = j.CostType
                             WHERE  p.Co = @apco
                                    AND p.Mth = @mth
                                    AND p.BatchId = @pobatchid )
   	--#135150
   	----and Not exists (select top 1 1 from bPOCB with (nolock) where Co=@apco and Mth=@mth and BatchId=@pocbbatchid and ChangeOrder=@aco)
            AND NOT EXISTS ( SELECT 1
                             FROM   dbo.bSLIB s 
                                    JOIN dbo.bJCCH j ON s.JCCo = j.JCCo
														AND s.Job = j.Job
														AND s.PhaseGroup = j.PhaseGroup
														AND s.Phase = j.Phase
														AND s.JCCType = j.CostType
                             WHERE  s.Co = @apco
                                    AND s.Mth = @mth
                                    AND s.BatchId = @slbatchid )
   	--#135150
   	----and Not exists (select top 1 1 from bSLCB with (nolock) where Co=@apco and Mth=@mth and BatchId=@slcbbatchid and AppChangeOrder=@aco)
	
   	---- For est attached to PO - match with records in PO batches 
   	--#142278
   	IF (SELECT CHARINDEX('0',@options)) > 0
   		BEGIN
			 UPDATE bJCCH
			 SET    SourceStatus = 'I',
					ActiveYN = 'Y',
					InterfaceDate = dbo.vfDateOnly() ----#141031
			 WHERE  JCCo = @pmco
					AND Job = @project
					AND SourceStatus = 'Y'
					AND EXISTS ( SELECT 1
								 FROM   dbo.bPOIB p
											JOIN dbo.bJCCH j ON p.PostToCo = j.JCCo
																AND p.Job = j.Job
																AND p.PhaseGroup = j.PhaseGroup
																AND p.Phase = j.Phase
																AND p.JCCType = j.CostType
								 WHERE  p.Co = @apco
										AND p.Mth = @mth
										AND p.BatchId = @pobatchid )
   		--#135150
   		----or exists (select 1 from bPOCB with (nolock) where Co=@apco and Mth=@mth and BatchId=@pocbbatchid and ChangeOrder=@aco))
   		END
   
   	---- For est attached to SL - match with records in SL batches
   	--#142278
    IF ( SELECT CHARINDEX('1', @options)) > 0 
        BEGIN
            UPDATE  bJCCH
            SET     SourceStatus = 'I',
                    ActiveYN = 'Y',
                    InterfaceDate = dbo.vfDateOnly() ----#141031
            WHERE   JCCo = @pmco
                    AND Job = @project
                    AND SourceStatus = 'Y'
                    AND EXISTS ( SELECT 1
                                 FROM   dbo.bSLIB p 
                                        JOIN dbo.bJCCH j ON p.JCCo = j.JCCo
															AND p.Job = j.Job
															AND p.PhaseGroup = j.PhaseGroup
															AND p.Phase = j.Phase
															AND p.JCCType = j.CostType
                                 WHERE  p.Co = @apco
                                        AND p.Mth = @mth
                                        AND p.BatchId = @slbatchid )
   		--#135150
   		----or exists (select 1 from bSLCB with (nolock) where Co=@apco and Mth=@mth and BatchId=@slcbbatchid and AppChangeOrder=@aco))
        END
   
   	---- For est attached to MO - match with records in MO batches
   	--#142278
    IF ( SELECT CHARINDEX('2', @options)) > 0 
        BEGIN
            UPDATE  bJCCH
            SET     SourceStatus = 'I',
                    ActiveYN = 'Y',
                    InterfaceDate = dbo.vfDateOnly() ----#141031
            WHERE   JCCo = @pmco
                    AND Job = @project
                    AND SourceStatus = 'Y'
                    AND EXISTS ( SELECT 1
                                 FROM   dbo.bINIB p
                                        JOIN dbo.bJCCH j ON	p.JCCo = j.JCCo
															AND p.Job = j.Job
															AND p.PhaseGroup = j.PhaseGroup
															AND p.Phase = j.Phase
															AND p.JCCType = j.CostType
                                 WHERE  p.Co = @inco
                                        AND p.Mth = @mth
                                        AND p.BatchId = @mobatchid )
        END
	end

---- approved change order
if isnull(@aco,'') <> ''
	begin
   	---- update JCCH
	Update bJCCH set SourceStatus='I', ActiveYN='Y', InterfaceDate = dbo.vfDateOnly() ----#141031
	from bJCCH jcch with (nolock), bPMOL pmol with (nolock) 
	Where jcch.JCCo=@pmco and jcch.Job=@project and jcch.JCCo=pmol.PMCo
	and jcch.Job=pmol.Project and jcch.PhaseGroup=pmol.PhaseGroup
	and jcch.Phase=pmol.Phase and jcch.CostType=pmol.CostType
	and pmol.ACO=@aco and jcch.SourceStatus = 'Y' and pmol.SendYN = 'Y'

	---- update contract item if force phase flag is yes
	Update bJCJP set Item=pmoi.ContractItem
	from bJCJP jcjp with (nolock), bPMOL pmol with (nolock), bPMOI pmoi with (nolock) 
	where jcjp.JCCo=@pmco and jcjp.Job=@project and jcjp.JCCo=pmol.PMCo
	and jcjp.Job=pmol.Project and jcjp.PhaseGroup=pmol.PhaseGroup
	and jcjp.Phase=pmol.Phase and pmol.ACO=@aco and pmol.SendYN='Y'
	and pmoi.PMCo=pmol.PMCo and pmoi.Project=pmol.Project
	and pmoi.ACO=pmol.ACO and pmoi.ACOItem=pmol.ACOItem and pmoi.ForcePhaseYN='Y'
	end

 
---- PO Originals
if isnull(@pobatchid,0) <> 0
	BEGIN
   	select @status=Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@pobatchid
   	if @status = 3 or @status = 4
   		begin
   		exec @porcode = dbo.bspPOHBPost @apco, @mth, @pobatchid, @dateposted, 'PM Intface', @errmsg output
           if @porcode <> 0
   			begin
               select @errtext = isnull(@errmsg,'') + 'apco: ' + CONVERT(varchar(3),@apco) + ' Mth: ' + convert(varchar(12),@mth,1) + ' POBatchId: ' + convert(varchar(10),@pobatchid) + ' Status: ' + convert(varchar(3),@status)
               exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pobatchid, @errtext, @errmsg output
               end
   		else
   			begin
   			delete bPMBC where Co=@pmco and Project=@project and Mth=@mth and BatchTable='POHB'
   			and BatchId=@pobatchid and BatchCo=@apco
               end
   		end
   	ELSE
   		begin
   		select @errtext = 'Invalid POHB batch status. ', @porcode = 1
   		exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pobatchid, @errtext, @errmsg output
   		end
	END

---- PO Change Orders
if isnull(@pocbbatchid,0) <> 0
   	BEGIN
   	select @status=Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@pocbbatchid
   	if @status = 3 or @status = 4
   		begin
           exec @porcode = dbo.bspPOCBPost @apco, @mth, @pocbbatchid, @dateposted, 'PM Intface', @errmsg output
           if @porcode <> 0
   			begin
               select @errtext = @errmsg
               exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pocbbatchid, @errtext, @errmsg output
               end
   		else
   			begin
   			delete bPMBC where Co=@pmco and Project=@project and Mth=@mth
   			and BatchTable='POCB' and BatchId=@pocbbatchid and BatchCo=@apco
   			end
   		end
   	ELSE
   		begin
           select @errtext = 'Invalid POCB batch status. ', @porcode = 1
           exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pocbbatchid, @errtext, @errmsg output
           end
   	END

---- SL Originals
if isnull(@slbatchid,0) <> 0
   	BEGIN
   	select @status=Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@slbatchid
   	if @status = 3 or @status = 4
   		begin
   		exec @slrcode = dbo.bspSLHBPost @apco, @mth, @slbatchid, @dateposted, 'PM Intface', @errmsg output
   		if @slrcode <> 0
   			begin
   			select @errtext = @errmsg
   			exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slbatchid, @errtext, @errmsg output
   			end
   		else
   			begin
   			delete bPMBC where Co=@pmco and Project=@project and Mth=@mth
   			and BatchTable='SLHB' and BatchId=@slbatchid and BatchCo=@apco
   			end
   		end
   	ELSE
   		begin
   		select @errtext = 'Invalid SLHB batch status. ', @slrcode = 1
   		exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slbatchid, @errtext, @errmsg output
   		end
   	END

---- SL change orders
if isnull(@slcbbatchid,0) <> 0
   	BEGIN
   	select @status=Status from bHQBC with (nolock) where Co=@apco and Mth=@mth and BatchId=@slcbbatchid
   	if @status = 3 or @status = 4
   		begin
   		exec @slrcode = dbo.bspSLCBPost @apco, @mth, @slcbbatchid, @dateposted, 'PM Intface', @errmsg output
   		if @slrcode <> 0
   			begin
   			select @errtext = @errmsg
   			exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slcbbatchid, @errtext, @errmsg output
   			end
   		else
   			begin
   			delete bPMBC where Co=@pmco and Project=@project and Mth=@mth
   			and BatchTable='SLCB' and BatchId=@slcbbatchid and BatchCo=@apco
   			end
   		end
   	ELSE
   		begin
   		select @errtext = 'Invalid SLCB batch status. ', @slrcode = 1
   		exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slcbbatchid, @errtext, @errmsg output
   		end
   	END

---- MO
if isnull(@mobatchid,0) <> 0
   	BEGIN
   	select @status=Status from bHQBC with (nolock) where Co=@inco and Mth=@mth and BatchId=@mobatchid
   	if @status = 3 or @status = 4
   		begin
   		exec @morcode = dbo.bspINMBPost @inco, @mth, @mobatchid, @dateposted, 'PM Intface', @errmsg output
   		if @morcode <> 0
   			begin
   			select @errtext = isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
   			end
   		else
   			begin
   			delete bPMBC where Co=@pmco and Project=@project and Mth=@mth
   			and BatchTable='INMB' and BatchId=@mobatchid and BatchCo=@inco
   			end
   		end
   	ELSE
   		begin
   		select @errtext = 'Invalid MO batch status. ', @morcode = 1
   		exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
   		end
   	END

---- MS Quotes - no MS Quote batch. If error occurs update PMBE
if (select charindex('3',@options)) > 0
   BEGIN
   	exec @msrcode = dbo.bspPMMSInterface @pmco, @project, @mth, @aco, 'N', @dateposted, null, @errmsg output
   	if @msrcode <> 0
   		begin
   		select @errtext = @errmsg
   		-- get PMBE sequence
   		select @pmbeseq = isnull(max(Seq),0) + 1 from bPMBE with (nolock) where Co=@pmco and Project=@project and Mth=@mth
   		insert into bPMBE (Co, Project, Mth, Seq, ErrorText)
   		select @pmco, @project, @mth, @pmbeseq, @errtext
   		end
   	else
   		begin
   		delete bPMBE where Co=@pmco and Project=@project and Mth=@mth
   		end
   END


---- If a Change Order, insert Approved Change Order into JCOH, JCOI and JCOD
if isnull(@aco,'') <> ''
   BEGIN
   	BEGIN TRANSACTION
   	---- First try to update the change order
   	---- Update Change Order Header
   	update bJCOH set Description=p.Description, NewCmplDate=p.NewCmplDate,
   					 BillGroup=p.BillGroup, IntExt=isnull(p.IntExt,'E')
   	from bPMOH p with (nolock), bJCOH j with (nolock) where p.PMCo=j.JCCo and p.Project=j.Job and p.ACO=j.ACO and p.PMCo=@pmco
   	and p.Project=@project and p.ACO=@aco
   	if @@rowcount = 0
   		begin
   		---- If does not exist then Insert Change Order Header
   		insert into bJCOH (JCCo,Job,ACO,ACOSequence,Contract,Description,ApprovedBy,ApprovalDate,
					ChangeDays,NewCmplDate,BillGroup,IntExt)
   		select PMCo,Project, ACO, ACOSequence, Contract, Description, ApprovedBy, ApprovalDate,
					0, NewCmplDate, BillGroup, isnull(IntExt,'E')
   		from bPMOH with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco

		------ copy user memos if any
		if @pmoh_jcoh_ud_flag = 'Y'
			begin
			-- build joins and where clause
			select @joins = ' from PMOH join JCOH z on z.JCCo = ' + convert(varchar(3),@pmco) +
   					' and z.Job = ' + CHAR(39) + @project + CHAR(39) +
   					' and z.ACO = ' + CHAR(39) + @aco + CHAR(39)
			select @where = ' where PMOH.PMCo = ' + convert(varchar(3),@pmco) + +
   					' and PMOH.Project = ' + CHAR(39) + @project + CHAR(39) +
   					' and PMOH.ACO = ' + CHAR(39) + @aco + CHAR(39)
			------ execute user memo update
			exec @rcode = dbo.bspPMPCOApproveUserMemoCopy 'PMOH', 'JCOH', @joins, @where, @msg output
			end
   		end

   		---- we have to update notes seperately
		update bJCOH set Notes=p.Notes
		from bPMOH p with (nolock), bJCOH j with (nolock) 
   		where p.PMCo=j.JCCo and p.Project=j.Job and p.ACO=j.ACO and p.PMCo=@pmco
		and p.Project=@project and p.ACO=@aco

   		---- update interfaced date, interfaced by in bPMOI for ACO Items that exist in bJCOI and will be updated
   		update bPMOI set InterfacedBy = SUSER_SNAME(), InterfacedDate = dbo.vfDateOnly() ----#141031 
   		from bPMOI p join bJCOI j on j.JCCo=p.PMCo and j.Job=p.Project and j.ACO=p.ACO and j.ACOItem=p.ACOItem
   		where p.PMCo=@pmco and p.Project=@project and p.ACO=@aco and (j.Description<>p.Description 
   		or j.Item<>p.ContractItem or j.ContractUnits<>p.Units or j.ContUnitPrice<>p.UnitPrice 
   		or j.ContractAmt<>p.ApprovedAmt or j.BillGroup<>p.BillGroup or j.ChangeDays<>p.ChangeDays)
   
   		---- update interfaced date, interfaced by in bPMOI for ACO Items that do not exist in bJCOI
   		update bPMOI set InterfacedBy = SUSER_SNAME(), InterfacedDate = dbo.vfDateOnly() ----#141031
   		from bPMOI p where p.PMCo=@pmco and p.Project=@project and p.ACO=@aco
   		and not exists(select * from bJCOI j where j.JCCo=p.PMCo and j.Job=p.Project and j.ACO=p.ACO
   						and j.ACOItem=p.ACOItem)

		---- Update Change Order Items
		select @totalcount=(select count(*) from bPMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco)
		update bJCOI set Description=p.Description, Item=p.ContractItem, ContractUnits=isnull(p.Units,0), 
   						 ContUnitPrice=isnull(p.UnitPrice,0), ContractAmt=isnull(p.ApprovedAmt,0), 
   						 BillGroup=p.BillGroup, ChangeDays = p.ChangeDays
   		from bPMOI p join bJCOI j on j.JCCo=p.PMCo and j.Job=p.Project and j.ACO=p.ACO and j.ACOItem=p.ACOItem 
   		where p.PMCo=@pmco and p.Project=@project and p.ACO=@aco
		select @updatecount = @@rowcount
   
		---- insert Change Order Items if update does not work
		insert into bJCOI (JCCo, Job, ACO, ACOItem, Contract, Item, Description, ApprovedMonth, ContractUnits,
   				ContUnitPrice, ContractAmt, BillGroup, ChangeDays, Notes)
		select p.PMCo, p.Project, p.ACO, p.ACOItem, p.Contract, p.ContractItem, p.Description,@mth,
   				isnull(p.Units,0), isnull(p.UnitPrice,0), isnull(p.ApprovedAmt,0), p.BillGroup,
   				p.ChangeDays, p.Notes
   		from bPMOI p with (nolock) 
   		LEFT JOIN bJCOI j with (nolock) ON j.JCCo=p.PMCo and j.Job=p.Project and j.ACO=p.ACO and j.ACOItem=p.ACOItem
   		where p.PMCo=@pmco and p.Project=@project and p.ACO=@aco and j.Job is null
   		select @insertcount = @@rowcount

   		---- check counts
   		if @updatecount + @insertcount <> @totalcount
   			begin
   			ROLLBACK TRANSACTION
   			select @errmsg = 'Error inserting Change Order Items.', @rcode=1
   			goto bspexit
			end

   		---- we have to update notes seperately
   		----update bJCOI set Notes = p.Notes
   		----from bPMOI p join bJCOI j on p.PMCo=j.JCCo and p.Project=j.Job and p.ACO=j.ACO and p.ACOItem=j.ACOItem
   		----where p.PMCo=@pmco and p.Project=@project and p.ACO=@aco

   		---- Update Change Order Items Detail
   		set @totalcount = 0
   		select @totalcount = (select count(*)
   		from dbo.bPMOL l with (nolock)
   		join dbo.bPMOI i with (nolock) on i.PMCo=l.PMCo and i.Project=l.Project and i.ACO=l.ACO and i.ACOItem=l.ACOItem
   		where l.PMCo=@pmco and l.Project=@project and l.ACO=@aco and l.SendYN='Y' and l.InterfacedDate is null)
   			
		----select @totalcount = (select count(*) from bPMOL where PMCo=@pmco and Project=@project and ACO=@aco and SendYN='Y' and InterfacedDate is null)
		---- update existing detail in JCOD
		update bJCOD set UnitCost=isnull(p.UnitCost,0), EstHours=isnull(p.EstHours,0), EstUnits=isnull(p.EstUnits,0),
                            EstCost=isnull(p.EstCost,0), MonthAdded=@mth
   		from bPMOL p with (nolock)
   		join bJCOD j with (nolock) on j.JCCo=p.PMCo and j.Job=p.Project and j.ACO=p.ACO and j.ACOItem=p.ACOItem
   		and p.PhaseGroup=j.PhaseGroup and p.Phase=j.Phase and p.CostType=j.CostType
   		--join bJCOD j with (nolock) where p.PMCo=j.JCCo and p.Project=j.Job and p.ACO=j.ACO and p.ACOItem=j.ACOItem
   		--and p.PhaseGroup=j.PhaseGroup and p.Phase=j.Phase and p.CostType=j.CostType
   		where p.PMCo=@pmco and p.Project=@project and p.ACO=@aco and p.SendYN='Y' and p.InterfacedDate is null
   		----and p.PMCo=@pmco and p.Project=@project and p.ACO=@aco and p.SendYN='Y' and p.InterfacedDate is null
   		select @updatecount = @@rowcount

   		---- insert Change Order Items Detail
   		insert into bJCOD (JCCo, Job, ACO, ACOItem, PhaseGroup, Phase, CostType,  MonthAdded, UM, UnitCost,
   						EstHours, EstUnits, EstCost)
   		select p.PMCo, p.Project, p.ACO, p.ACOItem, p.PhaseGroup, p.Phase, p.CostType,  @mth, p.UM, isnull(p.UnitCost,0),
   						isnull(p.EstHours,0), isnull(p.EstUnits,0), isnull(p.EstCost,0)
   		from bPMOL p with (nolock) 
   		join bPMOI i with (nolock) on i.PMCo=p.PMCo and i.Project=p.Project and i.ACO=p.ACO and i.ACOItem=p.ACOItem
   		left join bJCOD j with (nolock) ON p.PMCo=j.JCCo and p.Project=j.Job and p.ACO=j.ACO and p.ACOItem=j.ACOItem
   		and p.PhaseGroup=j.PhaseGroup and p.Phase=j.Phase and p.CostType=j.CostType
   		where p.PMCo=@pmco and p.Project=@project and p.ACO=@aco and p.SendYN='Y'
   		and p.InterfacedDate is null and j.Job is null
   		select @insertcount = @@rowcount

   		---- check counts
   		if @updatecount + @insertcount <> @totalcount
   			begin
   			ROLLBACK TRANSACTION
   			select @errmsg = 'Error inserting Change Order Detail.', @rcode=1
   			goto bspexit
   			end

   		----  update interface in PMOL
   		update bPMOL set InterfacedDate = dbo.vfDateOnly() ----#141031
   		from bPMOL p with (nolock)
   		join bPMOI i with (nolock) on i.PMCo=p.PMCo and i.Project=p.Project and i.ACO=p.ACO and i.ACOItem=p.ACOItem
   		where p.PMCo=@pmco and p.Project=@project and p.ACO=@aco and p.SendYN='Y' and p.InterfacedDate is null
   
   		---- declare cursor on PMOA for ACO to update into JCOD status <> Y
   		declare bcPMOA cursor LOCAL FAST_FORWARD
   			for select p.PhaseGroup, p.Phase, p.CostType, i.ACOItem, a.AddOn, a.PCOType, a.PCO, a.PCOItem, isnull(a.AddOnAmount,0)
   		from bPMOA a with (nolock) 
   		join bPMOI i with (nolock) on a.PMCo=i.PMCo and a.Project=i.Project and a.PCOType=i.PCOType and a.PCO=i.PCO and a.PCOItem=i.PCOItem
   		join bPMPA p with (nolock) on a.PMCo=p.PMCo and a.Project=p.Project and a.AddOn=p.AddOn
   		where i.PMCo=@pmco and i.Project=@project and i.ACO=@aco and a.Status <> 'Y'
   		and p.Phase is not null and p.CostType is not null ---- #129669
		and not exists(select 1 from bPMOL l with (nolock) where l.PMCo=a.PMCo and l.Project=a.Project
				and l.ACO=i.ACO and l.ACOItem=i.ACOItem and l.Phase=p.Phase and l.CostType=p.CostType)

   		---- open cursor
   		open bcPMOA
   		set @opencursor = 1

   		---- loop through PMOA addons
   		PMOA_loop:
   		fetch next from bcPMOA into @phasegroup, @phase, @costtype, @pmoiacoitem, @addon, @pmoapcotype, @pmoapco,
									@pmoapcoitem, @addonamount

   		if (@@fetch_status <> 0) goto PMOA_end

   		---- get UM from bJCCH - project phases
   		select @jcchum=UM from bJCCH with (nolock) 
   		where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype

   		---- check if addon exists in bJCOD update or insert
   		if exists(select 1 from bJCOD with (nolock) where JCCo=@pmco and Job=@project and ACO=@aco and ACOItem=@pmoiacoitem
   				and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype)
   			begin
   			update bJCOD set EstCost=EstCost+@addonamount
   			where JCCo=@pmco and Job=@project and ACO=@aco and ACOItem=@pmoiacoitem
   			and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
   			end
   		else
   			begin
   			insert into bJCOD (JCCo, Job, ACO, ACOItem, PhaseGroup, Phase, CostType, MonthAdded,
   					UM, UnitCost, EstHours, EstUnits, EstCost)
   			select @pmco, @project, @aco, @pmoiacoitem, @phasegroup, @phase, @costtype, @mth,
   					@jcchum, 0, 0, 0, @addonamount
   			end

   		---- update status flag in PMOA
   		----update bPMOA set Status='Y'
   		----where PMCo=@pmco and Project=@project and PCOType=@pmoapcotype and PCO=@pmoapco
   		----and PCOItem=@pmoapcoitem and AddOn=@addon
   
   		goto PMOA_loop
   
   		PMOA_end:
   
   		COMMIT TRANSACTION
   		end

---- close and deallocate cursor
if @opencursor = 1
	begin
	close bcPMOA
	deallocate bcPMOA
	set @opencursor = 0
	end

---- undo everything????
if @porcode <> 0 or @slrcode <> 0 or @morcode <> 0 or @msrcode <> 0
   	begin
   	select @errmsg = isnull(@errmsg,'') + '- Cannot interface data. ', @rcode = 1, @status = 2
   	end
else
   	begin
   	select @errmsg = 'Interface completed successfully! ', @rcode = 0, @status = 5
   	end




bspexit:
   	if @rcode<>0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMInterfacePost] TO [public]
GO
