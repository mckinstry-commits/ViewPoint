SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCPPVal    Script Date: 8/28/99 9:36:22 AM ******/
CREATE   procedure [dbo].[bspJCPPVal]
/***********************************************************
* CREATED BY:   LM 04/25/97
* MODIFIED By : SR 07/06/02 17738 added @PhaseGroup to bspJCVPHASE and COSTTYPE
*				 GF 05/21/2003 - issue #21312 need to check JCCH.ActiveYN flag. Error if 'N'
*				 TV - 23061 added isnulls
*				GF 07/20/2008 - issue #129040 no validation if units and pct cmplt are zero
*				GF 01/27/2009 - issue #132030 only check @units for validation.
*
*
* USAGE:
* Validates each entry in bJCPP for a selected batch - must be called 
* prior to posting the batch. 
*
* After initial Batch and JC checks, bHQBC Status set to 1 (validation in progress)
* bHQBE (Batch Errors) entries are deleted.
*
* Creates a cursor on bJCPP to validate each entry individually.
*

* Errors in batch added to bHQBE using bspHQBEInsert
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
* INPUT PARAMETERS
*   JCCo        JC Co 
*   Month       Month of batch
*   BatchId     Batch ID to validate                
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/ 
@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output 
as
set nocount on

declare @rcode int, @errortext varchar(255), @status tinyint, @opencursor tinyint,
		@job bJob, @PhaseGroup tinyint, @phase bPhase, @costtype bJCCType,
		@ctstring varchar(5), @units bUnits, @pctcmplt bPct

   
   select @rcode = 0, @opencursor = 0, @status = 0, @job=null, @PhaseGroup=0, @phase=null, @costtype=0
   
   -- validate HQ Batch 
   exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'JC Progres', 'JCPP', @errmsg output, @status output
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
   		
   -- set HQ Batch status to 1 (validation in progress)
   update bHQBC set Status = 1
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end
   
   -- clear HQ Batch Errors
   delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
   
   
-- declare cursor on JC Progress Batch for validation
declare bcJCPP cursor for select Job, PhaseGroup, Phase, CostType, ActualUnits, ProgressCmplt
from bJCPP where Co = @co and Mth = @mth and BatchId = @batchid

-- open cursor
open bcJCPP
select @opencursor = 1

-- get first row
fetch next from bcJCPP into @job, @PhaseGroup, @phase, @costtype, @units, @pctcmplt

-- loop through all rows
while (@@fetch_status = 0)
begin

	---- do not validate if @units = 0 and @pctcmplt = 0 #129040 #132030
	if isnull(@units,0) = 0 goto nextrec ----and isnull(@pctcmplt,0) = 0 goto nextrec

   	-- validate job
   	if not exists (select * from bJCJM with (nolock) where JCCo = @co and Job = @job)
   		begin
   		select @errortext = 'Job ' + isnull(@job,'') + ' - is invalid.' 
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto nextrec	-- if invalid then skip all related validation
   		end
   
   	-- validate PhaseGroup
   	if not exists (select * from bHQGP with (nolock) where Grp=@PhaseGroup)
   		begin
   		select @errortext = 'Phase Group ' + isnull(convert(varchar(3),@PhaseGroup),'') + ' - is invalid.' 
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto nextrec	-- if invalid then skip all related validation
   		end
   
   	-- validate phase
   	exec @rcode = bspJCVPHASE @co, @job, @phase, @PhaseGroup, 'N', 
   					null, null, null, null, null, null, null, null, @errmsg output
   	if @rcode = 1
   		begin
   		select @errortext = 'Phase: ' + isnull(@phase,'') + ' - ' + isnull(@errmsg,'') 
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto nextrec	-- if invalid then skip all related validation
   		end
   
   	-- validate CostType
   	select @ctstring=convert(varchar(5),@costtype)
   	exec @rcode = bspJCVCOSTTYPE @co, @job, @PhaseGroup, @phase, @ctstring, 'N', 
   					null, null, null, null, null, null, null, null, null, @errmsg output
   	if @rcode = 1
   		begin
   		select @errortext = 'Phase: ' + isnull(@phase,'') + ' CostType: ' + isnull(convert(varchar(3),@costtype),'') + ' - ' + isnull(@errmsg,'') 
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto nextrec	-- if invalid then skip all related validation
   		end
   
   
   nextrec:            
   fetch next from bcJCPP into @job, @PhaseGroup, @phase, @costtype, @units, @pctcmplt
   
   end
   
   -- check HQ Batch Errors and update HQ Batch Control status
   select @status = 3	-- valid - ok to post
   if exists(select * from bHQBE with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
   	begin
   	select @status = 2	-- validation errors
   	end
   
   -- update bHQBC with status
   update bHQBC set Status = @status
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount <> 1
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
   	if @opencursor = 1
   		begin
   		close bcJCPP
   		deallocate bcJCPP
   		select @opencursor = 0
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPPVal] TO [public]
GO
