SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPMInterfacePost    Script Date: 8/28/99 9:36:24 AM ******/
CREATE proc [dbo].[vspPMInterfaceBatchPost]
/*************************************
* Created By:	GF 05/20/2011 TK-05347
* Modified By:	GF 04/09/2012 TK-13873 #145073 if error during post no error message displayed.
*
*
*
* USAGE:
* used by PMInterface to post a project or change order from PM to PO, SL, MO, MS
*
* Pass in :
*	PMCo, Options, Project, Mth, ACO, INCo
*
* Output
*  POBatchid, POCBBatchId, SLBatchid, SLCBBatchId, MOBatchid, MSBatchid, Status, errmsg
*
* Returns
*	Error message and return code
*******************************/
(@pmco bCompany=0, @project bJob = NULL, @mth bMonth = NULL,
 @aco bACO = NULL, @apco bCompany = NULL, @inco bCompany = 0,
 @pobatchid int=0 output, @pocbbatchid int=0 output, 
 @slbatchid int=0 output, @slcbbatchid int=0 output, 
 @mobatchid int=0 output, @msbatchid int=0 output, @status tinyint=0 output,
 @InterfaceType VARCHAR(50) = NULL, @Id VARCHAR(50) = NULL,
 @errmsg varchar(255) output)
 
AS
SET NOCOUNT ON

DECLARE @rcode int, @porcode int, @slrcode int, @morcode int, @msrcode int,
   		@errtext varchar(255), @DatePosted bDate, @Contract bContract,
   		@pmbeseq INT, @msg varchar(255), @pcotype bDocType,
   		@pco bPCO, @EMsg VARCHAR(255)
		 
		 
SET @rcode = 0
SET @porcode = 0
SET @slrcode = 0
SET @morcode = 0
SET @msrcode = 0
SET	@DatePosted = dbo.vfDateOnly() 
---- for now null out PCO info
SET	@pcotype = NULL
SET @pco = NULL


-- validate parameters
If isnull(@pmco,0) = 0 or isnull(@mth,'') = '' or isnull(@project,'') = ''
	BEGIN
	select @errmsg = 'Missing Company, Project, or Month'
	goto vspexit
	END	

---- get contract for project
SELECT @Contract = [Contract]
FROM dbo.bJCJM
WHERE JCCo = @pmco and Job = @project


---- Need to update the Contract Status to open if still set to pending
Update dbo.bJCCM SET ContractStatus = 1
where JCCo = @pmco
		AND [Contract] = @Contract
		AND ContractStatus = 0

---- Need to update the Job Status to open if still set to pending
UPDATE dbo.bJCJM set JobStatus = 1
WHERE JCCo = @pmco
		AND Job = @project
		AND JobStatus = 0


---- if we are interfacing an ACO then do now. there will be no accounting 
---- batches with an ACO interface. so with completion we are done.
IF ISNULL(@aco,'') <> '' AND @InterfaceType = 'Approved Change Order'
	BEGIN
	EXEC @rcode = dbo.vspPMInterfaceACOPost @pmco, @project, @mth, @aco, @errmsg output
	IF @rcode <> 0
		BEGIN
		SELECT @errmsg = isnull(@errmsg,'') + ' - Cannot interface data. ', @status = 2
		GOTO vspexit
		END
		
		
	---- we are done - exit procedure
	select @errmsg = 'ACO Interface completed successfully! ', @rcode = 0, @status = 5
	GOTO vspexit
	END

---- if aco we are done
IF ISNULL(@aco,'') <> '' GOTO vspexit

---- Need to update JCCH entries where sourcestatus = Y, set it to I and change active flag to Y
UPDATE dbo.bJCCH SET SourceStatus = 'I',
					 ActiveYN = 'Y',
					 InterfaceDate = dbo.vfDateOnly()
WHERE JCCo = @pmco 
		AND Job = @project
		AND SourceStatus = 'Y'
	
	
---- if project update we are done
IF @InterfaceType IN ('Project Update', 'Project Pending') GOTO vspexit


---- get APCO from PMCO
select @apco=APCo from dbo.bPMCO where PMCo=@pmco

---- delete batch errors
delete dbo.bHQBE 
where Co=@apco and Mth=@mth and BatchId in (@pobatchid, @slbatchid, @pocbbatchid, @slcbbatchid)


-- PO Originals
if isnull(@pobatchid,0) <> 0
BEGIN
	select @status=[Status]
	from dbo.bHQBC 
	where Co=@apco and Mth=@mth and BatchId=@pobatchid
	if @status = 3/*Valid*/ or @status = 4/*PostInProgress*/
		begin
			exec @porcode = dbo.bspPOHBPost @apco, @mth, @pobatchid, @DatePosted, 'PM Intface', @errmsg output
			if @porcode <> 0
				BEGIN
					----TK-13873
					select @errtext = ISNULL(@errmsg,'')
					exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pobatchid, @errtext, @EMsg output
				end
			else
				begin
					delete dbo.bPMBC 
					where Co=@pmco and Project=@project and Mth=@mth and BatchTable='POHB'
							and BatchId=@pobatchid and BatchCo=@apco
				end
		end
	else
		begin
			select @errmsg = 'Invalid POHB batch status. ', @porcode = 1
			----TK-13873
			exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pobatchid, @errmsg, @EMsg output
		END
END

-- PO Change Orders
if isnull(@pocbbatchid,0) <> 0
	BEGIN
	select @status=[Status] 
	from dbo.bHQBC 
	where Co=@apco and Mth=@mth and BatchId=@pocbbatchid
	if @status = 3/*valid*/ or @status = 4/*PostInProgress*/
		begin
			exec @porcode = dbo.bspPOCBPost @apco, @mth, @pocbbatchid, @DatePosted, 'PM Intface', @errmsg output
			if @porcode <> 0
				BEGIN
				----TK-13873
				select @errtext = ISNULL(@errmsg,'')
				exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pocbbatchid, @errtext, @EMsg OUTPUT
				GOTO vspexit
				end
			else
				begin
				delete dbo.bPMBC
				where Co=@pmco and Project=@project and Mth=@mth and BatchTable='POCB' 
						and BatchId=@pocbbatchid and BatchCo=@apco
				end
		end
	ELSE
		begin
		select @errmsg = 'Invalid POCB batch status. ', @porcode = 1
		----TK-13873
		exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pocbbatchid, @errmsg, @EMsg output
		end
	END

---- we are done with PO interface types
IF @InterfaceType IN ('Purchase Order - Original', 'Purchase Order CO') GOTO post_done

-- SL Originals
if isnull(@slbatchid,0) <> 0
BEGIN
	select @status=[Status]
	from dbo.HQBC 
	where Co=@apco and Mth=@mth and BatchId=@slbatchid
	if @status = 3/*Valid*/or @status = 4 /*PostInProgress*/
		begin
			exec @slrcode = dbo.bspSLHBPost @apco, @mth, @slbatchid, @DatePosted, 'PM Intface', @errmsg output
			if @slrcode <> 0
				BEGIN
				----TK-13873
					select @errtext = ISNULL(@errmsg,'')
					exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slbatchid, @errtext, @EMsg output
				end
			else
				begin
					delete dbo.PMBC 
					where Co=@pmco and Project=@project and Mth=@mth and BatchTable='SLHB' 
						and BatchId=@slbatchid and BatchCo=@apco
				end
		end
	else
		begin
			select @errmsg = 'Invalid SLHB batch status. ', @slrcode = 1
			----TK-13873
			exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slbatchid, @errmsg, @EMsg output
		end
END

-- SL change orders
if isnull(@slcbbatchid,0) <> 0
BEGIN
	select @status=[Status]
	from dbo.HQBC 
	where Co=@apco and Mth=@mth and BatchId=@slcbbatchid
	if @status = 3/*Valid*/ or @status = 4/*PostInProgress*/
		begin
			exec @slrcode = dbo.bspSLCBPost @apco, @mth, @slcbbatchid, @DatePosted, 'PM Intface', @errmsg output
			if @slrcode <> 0
				BEGIN
				----TK-13873
					select @errtext = ISNULL(@errmsg,'')
					exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slcbbatchid, @errtext, @EMsg output
				end
			else
				begin
					delete dbo.PMBC 
					where Co=@pmco and Project=@project and Mth=@mth and BatchTable='SLCB' 
						and BatchId=@slcbbatchid and BatchCo=@apco
				end
		end
	else
		begin
			select @errmsg = 'Invalid SLCB batch status. ', @slrcode = 1
			----TK-13873
			exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slcbbatchid, @errmsg, @EMsg output
		end
END

IF @InterfaceType IN ('Subcontract - Original', 'Subcontract CO') GOTO post_done

-- MO
if isnull(@mobatchid,0) <> 0
BEGIN
	select @status=[Status]
	from dbo.HQBC 
	where Co=@inco and Mth=@mth and BatchId=@mobatchid
	if @status = 3/*Valid*/ or @status = 4/*PostInProgress*/
		begin
			exec @morcode = dbo.bspINMBPost @inco, @mth, @mobatchid, @DatePosted, 'PM Intface', @errmsg output
			if @morcode <> 0
				BEGIN
				----TK-13873
					select @errtext = isnull(@errmsg,'')
					exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @EMsg output
				end
			else
				begin
					delete dbo.PMBC 
					where Co=@pmco and Project=@project and Mth=@mth
					and BatchTable='INMB' and BatchId=@mobatchid and BatchCo=@inco
				end
			end
	else
		begin
			select @errmsg = 'Invalid MO batch status. ', @morcode = 1
			----TK-13873
			exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errmsg, @EMsg output
		end
END

-- MS Quotes - no MS Quote batch. If error occurs update PMBE
IF @InterfaceType = 'Quote'
	BEGIN
	
	EXEC @msrcode = dbo.vspPMInterfaceMS @pmco, @project, @mth, 'N', @inco, @Id, NULL, @errmsg output
	if @msrcode <> 0
		begin
			select @errtext = @errmsg
			-- get PMBE sequence
			select @pmbeseq = isnull(max(Seq),0) + 1
			from dbo.PMBE 
			where Co=@pmco and Project=@project and Mth=@mth
			
			insert into dbo.PMBE (Co, Project, Mth, Seq, ErrorText)
			select @pmco, @project, @mth, @pmbeseq, @errtext
		end
	else
		begin
			delete dbo.PMBE 
			where Co=@pmco and Project=@project and Mth=@mth
		END
	GOTO post_done
	END


post_done:
if @porcode <> 0 or @slrcode <> 0 or @morcode <> 0 or @msrcode <> 0
	begin
		select @errmsg = isnull(@errmsg,'') + '- Cannot interface data. ', @rcode = 1, @status = 2
	end
else
	begin
		select @errmsg = 'Interface completed successfully! ', @rcode = 0, @status = 5
	END
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMInterfaceBatchPost] TO [public]
GO
