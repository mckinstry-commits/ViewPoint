SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE         procedure [dbo].[bspEMLBVal]
/***********************************************************
* CREATED BY:     bc 6/11/99
* MODIFIED By :   bc 04/05/00
*             danf 08/07/00 removed @inuseby which was not being used and had a dropped data type of bUserName
*             bc 04/26/01 - added bspEMLBInDateVal
*             bc 09/24/1 - Checked to make sure that the To Job is not closed.
*             TV 12/15/03 22744 - Removed un-needed code.
*			TV 02/11/04 - 23061 added isnulls
*			CHS	11/05/08 - #130640
*			GF 01/08/2013 TK-20651 added parameters for bspINLBInDateValue
*			GF 02/07/2013 TFS-40186 bspEMLocVal as output param added for active flag
*
*
* USAGE: validates entries in EMLB for location transfers.  no distribution tables.  just the batch table.
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
* INPUT PARAMETERS
*   EMCo        EM Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output
as

set nocount on

declare @rcode int, @errortext varchar(255), @source bSource, @tablename char(20),
@status tinyint, @opencursorEMLB tinyint,
@maxopen tinyint, @accttype char(1), @cnt int, @msg bDesc,
@itemcount int, @deletecount int, @errorstart varchar(50)
/*EMLB declarations*/
declare @seq int, @batchtranstype char(1), @trans bTrans, @equip bEquip,
@fromjcco bCompany, @fromjob bJob,
@tojcco bCompany, @tojob bJob, @fromloc bLoc, @toloc bLoc, @datein bDate, @timein varchar(20)/*smalldatetime*/,
@dateout bDate, @timeout varchar(20) /* smalldatetime*/, @memo bDesc, @estout bDate, @lastbilled bDate,
@oldequip bEquip, @oldfromjcco bCompany, @oldfromjob bJob, @oldtojcco bCompany, @oldtojob bJob,
@oldfromloc bLoc,@oldtoloc bLoc, @olddatein varchar(20) /*smalldatetime*/,
@oldtimein varchar(20) /*smalldatetime*/, @olddateout bDate, @oldtimeout varchar(20) /*smalldatetime*/, @oldmemo bDesc,
@oldestout bDate, @oldlastbilled bDate, @attachedtoseq INT

----TFS-40186
DECLARE @ActiveLoc CHAR(1)


select @rcode = 0, @cnt = 0

/* set open cursor flag to false */
select @opencursorEMLB = 0
/* validate HQ Batch */
exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'EMXfer', 'EMLB', @errmsg output, @status output
if @rcode <> 0
begin
	select @errmsg = @errmsg, @rcode = 1
	goto bspexit
end

if @status < 0 or @status > 3
begin
	select @errmsg = 'Invalid Batch status!', @rcode = 1
	goto bspexit
end

/* set HQ Batch status to 1 (validation in progress) */
update dbo.HQBC
set Status = 1
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
end

/* clear HQ Batch Errors */
delete dbo.HQBE where Co = @co and Mth = @mth and BatchId = @batchid

/*clear and refresh HQCC entries */
delete dbo.HQCC where Co = @co and Mth = @mth and BatchId = @batchid

insert into dbo.HQCC(Co, Mth, BatchId, GLCo)
select distinct Co, Mth, BatchId, GLCo from dbo.EMBF 
where Co=@co and Mth=@mth and BatchId=@batchid

/* declare cursor on EM Batch for validation */
declare bcEMLB cursor for 
select BatchSeq,Source,Equipment,BatchTransType,MeterTrans,FromJCCo,FromJob,
ToJCCo,ToJob,FromLocation,ToLocation,DateIn,TimeIn,DateOut,TimeOut,Memo,EstOut,LastBilled,
OldEquipment,OldFromJCCo,OldFromJob,OldToJCCo,OldToJob,OldFromLocation,OldToLocation,
OldDateIn,OldTimeIn,OldDateOut,OldTimeOut,OldMemo,OldEstOut,OldLastBilled
from dbo.EMLB 
where Co = @co and Mth = @mth and BatchId = @batchid

/* open cursor */
open bcEMLB
/* set open cursor flag to true */
select @opencursorEMLB = 1

nextseq:
/* get first row */
fetch next from bcEMLB into @seq, @source,@equip, @batchtranstype, @trans, @fromjcco, @fromjob,
@tojcco, @tojob, @fromloc, @toloc, @datein, @timein, @dateout, @timeout,@memo, @estout, @lastbilled,
@oldequip, @oldfromjcco, @oldfromjob, @oldtojcco, @oldtojob, @oldfromloc,@oldtoloc,
@olddatein,	@oldtimein, @olddateout, @oldtimeout, @oldmemo,	@oldestout, @oldlastbilled

/* loop through all rows */
while (@@fetch_status = 0)
BEGIN
	/* validate EM Batch info for each entry */
	select @errorstart = 'Seq#' + isnull(convert(varchar(6),@seq),'')
	/* validate batch transaction type */
	if @batchtranstype not in ('A','C','D')
	begin
	select @errortext = isnull(@errorstart,'') + ' -  Invalid transaction type, must be A, C or D.'
	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 
	begin
		goto bspexit 
	end
	goto nextseq
end

/* validation specific to Add types of transactions */
if @batchtranstype = 'A'
Begin
	/* check Trans number to make sure it is null*/
	if not @trans is null
		begin
		select @errortext = isnull(@errorstart,'') + ' - invalid to have transaction number on new entries!'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 
		begin
			goto bspexit 
		end
	end
	if not (@oldequip is null and @oldfromjcco is null and @oldfromjob is null and
	@oldtojcco is null and @oldtojob is null and @oldfromloc is null and @oldtoloc is null and
	@olddatein is null and @oldtimein is null and @olddateout is null and @oldtimeout is null and
	@oldmemo is null and @oldestout is null and @oldlastbilled is null)
	begin
		select @errortext = isnull(@errorstart,'') + ' - all old values must be null for add records!'
		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 
		begin
			goto bspexit 
		end
	end
End  /* type Adds */

/* validation specific to Add and Change types of transactions */
if @batchtranstype in ('A','C')
BEGIN
	/* validate equipment */
	exec @rcode = dbo.bspEMEquipValXfer @co, @mth, @batchid, @seq, @equip, null, null, 'Y', @errmsg = @errmsg output
	if @rcode <> 0
	begin
		select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 
		begin
			goto bspexit 
		end
		goto nextseq
	end
	/* validate the from jcco */
	if @fromjcco is not null
	begin
		exec @rcode = dbo.bspJCCompanyVal @fromjcco, @msg = @errmsg output
		if @rcode <> 0
		begin
			select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 
			begin
				goto bspexit 
			end
			goto nextseq
		end
	end
	/* validate the from job */
	if isnull(@fromjob,'')<>''
	begin
		exec @rcode = dbo.bspJCJMVal @fromjcco, @fromjob, @msg = @errmsg output
		if @rcode <> 0
		begin
			select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 
			begin
				goto bspexit 
			end
			goto nextseq
		end
	end
	---- validate the from job
	---- check soft-closed jobs #130640
	if isnull(@fromjob,'')<>''
	begin
		if exists(select top 1 1 from dbo.JCJM j with (nolock)
		join dbo.JCCO c with (nolock) on c.JCCo = j.JCCo
		where j.JCCo=@tojcco and j.Job=@tojob and c.PostSoftClosedJobs = 'N' and j.JobStatus = 2)
		begin
			select @errortext = isnull(@errorstart,'') + ' To Job: ' + isnull(@tojob, '') + ' is soft-closed and JC does not allow posting to soft-closed jobs.'
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 
			begin
				goto bspexit 
			end
			goto nextseq
		end
	end  
	---- validate the from job
	---- check hard-closed jobs #130640
	if isnull(@fromjob,'')<>''
	begin
		if exists(select top 1 1 from dbo.JCJM j with (nolock)
		join dbo.JCCO c with (nolock) on c.JCCo = j.JCCo
		where j.JCCo=@tojcco and j.Job=@tojob and c.PostSoftClosedJobs = 'N' and j.JobStatus = 3)
		begin
			select @errortext = isnull(@errorstart,'') + ' To Job: ' + isnull(@tojob, '') + ' is hard-closed and JC does not allow posting to hard-closed jobs.'
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 
			begin
				goto bspexit 
			end
			goto nextseq
		end 
	end
	/* validate the from location */
	if isnull(@fromloc,'')<>''
		begin
		----TFS-40186
		exec @rcode = dbo.bspEMLocVal @co, @fromloc, @ActiveLoc OUTPUT, @msg = @errmsg output
		if @rcode <> 0
			begin
			select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 
				begin
				goto bspexit 
				END
			goto nextseq
			END
		END
        
	/* validate the to jcco */
	if @tojcco is not null
	begin
		exec @rcode = dbo.bspJCCompanyVal @tojcco, @msg = @errmsg output
		if @rcode <> 0
		begin
			select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 
			begin
				goto bspexit 
			end
			goto nextseq
		end
	end
	/* the transfer must go to either a job or a location or both */
	if isnull(@tojob,'')='' and isnull(@toloc,'') = ''
	begin
		select @errortext = isnull(@errorstart,'') + ' Both the destination job and location are null.  One of the two must be present.'
		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 
		begin
			goto bspexit 
		end
		goto nextseq
	end
	/* validate the to job */
	if isnull(@tojob,'') <>''
	begin
		exec @rcode = dbo.bspJCJMPostVal @tojcco, @tojob, @msg = @errmsg output
		if @rcode <> 0
		begin
			select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 
			begin
				goto bspexit 
			end
			goto nextseq
		end
	end
	---- validate the to job
	---- check soft-closed jobs #130640
	if isnull(@tojob,'')<>''
	begin
		if exists(select top 1 1 from dbo.JCJM j with (nolock)
		join dbo.JCCO c with (nolock) on c.JCCo = j.JCCo
		where j.JCCo=@tojcco and j.Job=@tojob and c.PostSoftClosedJobs = 'N' and j.JobStatus = 2)
		begin
			select @errortext = isnull(@errorstart,'') + ' To Job: ' + isnull(@tojob, '') + ' is soft-closed and JC does not allow posting to soft-closed jobs.'
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 
			begin
				goto bspexit 
			end
		goto nextseq
		end
	end  
	---- validate the to job
	---- check hard-closed jobs #130640
	if isnull(@tojob,'') <>''
	begin
		if exists(select top 1 1 from dbo.JCJM j with (nolock)
		join dbo.JCCO c with (nolock) on c.JCCo = j.JCCo
		where j.JCCo=@tojcco and j.Job=@tojob and c.PostSoftClosedJobs = 'N' and j.JobStatus = 3)
		begin
			select @errortext = isnull(@errorstart,'') + ' To Job: ' + isnull(@tojob, '') + ' is hard-closed and JC does not allow posting to hard-closed jobs.'
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 
			begin
				goto bspexit 
			end
			goto nextseq
		end 
	end
	/* validate the to location */
	if isnull(@toloc ,'')<>''
		BEGIN
		----TFS-40186  
		exec @rcode = dbo.bspEMLocVal @co, @toloc, @ActiveLoc OUTPUT, @msg = @errmsg output
		if @rcode <> 0
			begin
			select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 
				begin
				goto bspexit 
				end
			goto nextseq
			END
            
  		---- to location must be active
		IF @ActiveLoc = 'N'
			BEGIN
			SELECT @errortext = ISNULL(@errorstart,'') + ' To Location is inactive.'
			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 
				BEGIN
				goto bspexit 
				END
			GOTO nextseq
			END               
		END
        
	/* make sure the transfer dates make sense */
	if @dateout < @datein
	begin
		select @errortext = isnull(@errorstart,'') + ' - the transfer date out is earlier than the transfer date in.'
		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 
		begin
			goto bspexit 
		end
		goto nextseq
	end
	/* make sure the transfer dates make sense */
	if @estout < @datein
	begin
		select @errortext = isnull(@errorstart,'') + ' - the transfer estimated date out is earlier than the transfer date in.'
		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 
		begin
			goto bspexit 
		end
		goto nextseq
	end
	/* make sure the transfer is actually going someplace else */
	if isnull(@fromjcco,0) = isnull(@tojcco,0) and isnull(@fromjob,'') = isnull(@tojob,'') and
	isnull(@fromloc,'') = isnull(@toloc,'')
	begin
		select @errortext = isnull(@errorstart,'') + ' - cannot transfer equipment to its current job/location.'
		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 
		begin
			goto bspexit 
		end
		goto nextseq
	end
	/* validate the InDate/InTime against the most recent transfer in EMLH */
	----TK-20651
	exec @rcode = dbo.bspEMLBInDateVal @co, @mth, @batchid, @seq, @equip, @datein, @timein, @fromjcco, @fromjob, @fromloc, @dateout, @timeout, @msg = @errmsg output
	if @rcode = 1  --@rcode = 2 is a warning only so we can't just check for @rcode to not be equal zero.
	begin
		select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 
		begin
			goto bspexit 
		end
		goto nextseq
	end
END
/* end type Add of Change type lines */

-- Removed TV 22744 12/15/03 - Does not do anything....
/* BEGIN the Change or Delete batch type lines  
if @batchtranstype in ('C','D')
BEGIN
select @errmsg = 'change/delete code'
END*/

/* validation specific for Deletion of a transaction */
if @batchtranstype = 'D'
BEGIN
	select @itemcount = count(*) from dbo.EMLH with(nolock)
	where EMCo=@co and [Month]=@mth and Trans=@trans

	select @deletecount= count(*) from dbo.EMLB with(nolock)
	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and BatchTransType='D'
	if @itemcount <> @deletecount
	begin
		select @errortext = isnull(@errorstart,'') + ' - In order to delete a transaction all entries must be in the current batch and marked for delete! '
		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 
		begin
			goto bspexit 
		end
	end

	select @deletecount= count(*) from dbo.EMLB with(nolock)
	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and BatchTransType <> 'D'
	if  @deletecount  <> 0
	begin
		select @errortext = isnull(@errorstart,'') + ' - In order to delete a transaction you cannot have any Add or Change lines! '
		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 
		begin
			goto bspexit 
		end
	end
end
 /*Delete */

goto nextseq
END /*EMLB LOOP*/

close bcEMLB
deallocate bcEMLB
select @opencursorEMLB=0

/* check HQ Batch Errors and update HQ Batch Control status */
select @status = 3	/* valid - ok to post */
if exists(select 1 from dbo.HQBE with(nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
select @status = 2	/* validation errors */

update dbo.HQBC
set Status = @status
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount <> 1
begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
end

bspexit:
if @opencursorEMLB = 1
begin
	close bcEMLB
	deallocate bcEMLB
end
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspEMLBVal] TO [public]
GO
