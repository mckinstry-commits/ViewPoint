SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMBatchAssignPR]
/************************************************************************
* CREATED:  MH 12/29/99
* MODIFIED: DANF 05/17/01 Increased Batchid from four to six.
*			mh 5/9/02 Issue 17289
*			DANF 02/14/03 - Issue #20127: Pass restricted batch default to bspHQBCInsert
*			RBT 05/16/03 - Issue #17507: Add error checking for bspIMCreateBatch, and
*					moved cursor close and deallocate to bspexit, and do validation on
*					batch month.
*			DANF 11/03/03 - Issue #22910 Correct bspIMCreateBatch batchid to @batch_id as output and 
*							 if an Error occurs during import of month validation or Batch creation do not
*							 not exit store procedure.
*			RBT 11/10/03 - Issue #22934 Use week ending dates from IMWE, not IMPR.
*			RBT 03/18/04 - Issue #24104 Create batch with GLCo instead of PRCo.
*			RBT 05/07/04 - Issue #24490 Add more error checking and better messages.
*			DANF 09/14/2004 - Issue 19246 added new login
*			DANF 11/02/2004 - Issue 25901 preformance enhancement.
*	        DANF 12/21/04 - Issue #26577: Changed reference on DDUP
*			DANF 11/07/2006 - Issue 122982 Improve query preformance
*			DANF 12/19/2006 - Corrections for 6.x related to DDUP
*			GG 04/24/08 - #128000 - replaced slow performing query
*			TJL 08/07/09 - Issue #133852, Upload give "Missing Group in 1 or more..." error when PR Group = 0
*
* Determines if a batch must created for an ImportId.  If so, will create
* appropriate batch id's for each month within the domain of a specific
* ImportId.  A specific ImportId may encompass more than one month's
* data.
*
* Notes about Stored Procedure
*
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
    
            @form varchar(30), @importid varchar(20), @errmsg varchar(255) output
    
    as
    set nocount on
    
    --Need to resolve these.  Should they be parameters or locals
    declare @restrict bYN, @adjust bYN, @prgroup bGroup, @prenddate bDate, @prco bCompany, @glco bCompany
    select @restrict = null, @adjust = null, @prgroup = null, @prenddate = null, @glco = null
    
    --Local Variables
    declare @complete int, @inner_complete int, @slash int, @mth_ident int, @batch_ident int,
            @batchseq_ident int, @source bSource, @batchmth varchar(20), @batchid int,
            @update_stmt varchar(8000), @rec_seq_range varchar(8000), @batch_id varchar(20),
            @uploadval varchar(60), @rc int, @co_ident int, @group_ident int, @enddate_ident int,
   		 @openbatchcursor int, @rcode int, @errtxt varchar(255)
    
    --Cursor Variables
    declare @new_mth bMonth, @batch_id_rec varchar(10),
            @imweco bCompany, @imwegroup bGroup, @imweenddate bDate
    
    --initialize
    select @rc = 0,@openbatchcursor = 0
    
    --get identifier that holds Month
    select @mth_ident = Identifier from DDUD with (nolock) where Form = @form and ColumnName = 'Mth'
    
    --get identifier that holds BatchId
    select @batch_ident = Identifier from DDUD with (nolock)  where Form = @form and ColumnName = 'BatchId'
    
    --get identifier that holds BatchSeq
    select @batchseq_ident = Identifier from DDUD with (nolock)  where Form = @form and ColumnName = 'BatchSeq'
    
    --get identifier that holds Company
    select @co_ident = Identifier from DDUD with (nolock)  where Form = @form and ColumnName = 'Co'
    
    --get identifier that holds group
    select @group_ident = Identifier from DDUD with (nolock)  where Form = @form and ColumnName = 'PRGroup'
    
    --get identifier that holds enddate
    select @enddate_ident = Identifier from DDUD with (nolock)  where Form = @form and ColumnName = 'PREndDate'
    
    --get source for batch from DDUF
    select @source = BatchSource from DDUF with (nolock)  where Form = @form
    
    --Issue #22934
    declare @batchdata table(
      Co tinyint null,
  	PRGroup tinyint null,
  	PREndDate smalldatetime null)
    
    --Issue #22934
    insert into @batchdata(Co, PRGroup, PREndDate)
  	select a.UploadVal, b.UploadVal, c.UploadVal
 
  	from IMWE a with (nolock) JOIN IMWE b with (nolock) on a.ImportId = b.ImportId and a.RecordSeq = b.RecordSeq
  	and a.RecordType = b.RecordType JOIN IMWE c with (nolock) on a.ImportId = c.ImportId and a.RecordSeq = c.RecordSeq
  	and a.RecordType = c.RecordType 
 
  	where a.ImportId = @importid and a.Identifier = @co_ident and b.Identifier = @group_ident 
  	and c.Identifier = @enddate_ident
  	order by a.RecordSeq
  
    declare Batch_curs cursor local fast_forward
    for
    --these are the months that will need batches
    --Issue #22934 Changed to use table variable of values from IMWE instead of IMPR.
    select distinct Co, PRGroup, PREndDate
    from @batchdata
  
    Open Batch_curs
    select @openbatchcursor = 1
    fetch next from Batch_curs into @prco, @prgroup, @prenddate
    
    select @complete = 0
    
 	if isnull(convert(varchar(max),@prco),'') = ''
 	begin
 		select @errmsg=isnull(@errmsg,'') + '  Import is missing PRCo in 1 or more records.',@rc=1
 		goto next_prenddate
 	end
 
 	if isnull(convert(varchar(max),@prgroup),'') = ''
 	begin
 		select @errmsg=isnull(@errmsg,'') + '  Import is missing PRGroup in 1 or more records.',@rc=1
 		goto next_prenddate
 	end
 
    select @new_mth = BeginMth
    from PRPC with (nolock)
    where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    if @@rowcount <>1
  	begin
  		select @errmsg=isnull(@errmsg,'') + '  Import Contains Invalid Payroll Ending Dates.',@rc=1
  		goto next_prenddate
  	end
  
    while @complete = 0
    begin
    
        if @@fetch_status = 0
            begin
                    --Creating new batch id....probably should place some error trapping here
                    --month format should be taken care of prior to arriving here
                    --select @batchmth = substring(@new_mth, 1, 2)
                    --select @batchmth = @batchmth + '/1/' + substring(@new_mth, 4, 2)
                    select @restrict = 'N', @adjust = 'N'
   				 /* Get Restricted batch default from DDUP */
   				 select @restrict = isnull(RestrictedBatches,'N')
   				 from dbo.vDDUP with (nolock)
   				 where VPUserName = SUSER_SNAME() 
   				 if @@rowcount <> 1 and (SUSER_SNAME()<> 'bidtek' and SUSER_SNAME()<> 'viewpointcs')
   				 	begin
   					select @rc = 1, @errmsg = 'Missing: ' + SUSER_SNAME() + ' from DDUP.'
   					goto bspexit
   					end
   				--Validate the month (issue #17507).
  				--Pass GLCo instead of PRCo (issue #24104).
  				--get the GLCo for this PRCo
  				select @glco = GLCo from PRCO with (nolock) where PRCo = @prco
  				select @glco = isnull(@glco, @prco)	--in case glco is null, use prco.
   				exec @rcode = bspHQBatchMonthVal @glco, @new_mth, 'bspIMBatchAssignPR', @errtxt output
   				if @rcode <> 0
   				begin	 
  					select @rc = 1, @errmsg=@errtxt
   					goto next_prenddate
   				end
                    --exec @batch_id = bspIMCreateBatch  @co, @batchmth, @form, @source, @restrict, @adjust,
                    --    @prgroup, @prenddate, @batchid, @errmsg
                    exec @rcode = bspIMCreateBatch  @prco, @new_mth, @form, @source, @restrict, @adjust,
                        @prgroup, @prenddate, @batch_id output, @errtxt output
    					
   				 --DO ERROR CHECKING! (issue 17507) Seems like an error should return a value
   				 --that could not be a possibly valid batch id....
   				 if @rcode <> 0
   				 begin
  					select @rc = 1, @errmsg=@errtxt
   				    goto next_prenddate
   				 end
   
                    --these are the record sequences that need updating.
                    declare Batch_ID_curs cursor local fast_forward
                    for
                    select distinct (RecordSeq) from IMWE where ImportId = @importid
    
                    --print 'contents of Batch_ID_curs'
                    --select RecordSeq from IMWE where ImportId = @importid
    
                    open Batch_ID_curs
    
                    nxtrec_seq:
                    fetch next from Batch_ID_curs into @batch_id_rec
    
                        if @@fetch_status = 0
                            begin
-- #128000 commented out slow performing query
-- 					select @imweco=Co.Co, @imwegroup=PRGroup.PRGroup,@imweenddate=EndDate.EndDate
-- 					from bIMWE w with (nolock)
-- 					left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'Co' from bIMWE with (nolock) 
-- 							where Identifier=@co_ident and ImportId = @importid and RecordSeq=@batch_id_rec
-- 					           group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
-- 						     as Co on Co.ImportId=w.ImportId and Co.ImportTemplate=w.ImportTemplate and Co.RecordType=w.RecordType and Co.RecordSeq=w.RecordSeq
-- 					 left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'PRGroup' from bIMWE with (nolock) 
-- 							where Identifier=@group_ident and ImportId = @importid and RecordSeq=@batch_id_rec
-- 					           group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
-- 						     as PRGroup on PRGroup.ImportId=w.ImportId and PRGroup.ImportTemplate=w.ImportTemplate and PRGroup.RecordType=w.RecordType and PRGroup.RecordSeq=w.RecordSeq
-- 					 left join (select  ImportId, ImportTemplate, RecordType, Identifier, RecordSeq, UploadVal AS 'EndDate' from bIMWE with (nolock) 
-- 							where Identifier=@enddate_ident and ImportId = @importid and RecordSeq=@batch_id_rec
-- 					           group by ImportId,ImportTemplate, Form,  RecordType, Identifier, RecordSeq, UploadVal) 
-- 						     as EndDate on EndDate.ImportId=w.ImportId and EndDate.ImportTemplate=w.ImportTemplate and EndDate.RecordType=w.RecordType and EndDate.RecordSeq=w.RecordSeq
-- 					 where w.ImportId = @importid and w.RecordSeq=@batch_id_rec
-- 					group by Co.Co, PRGroup.PRGroup,EndDate.EndDate
 					
-- #128000 - replaced with 3 quick hits to pull PRCo#, PRGroup, and PREndDate
select  @imweco = UploadVal
from dbo.bIMWE with (nolock) 
where Identifier=@co_ident and ImportId = @importid and RecordSeq=@batch_id_rec 

select  @imwegroup = UploadVal
from dbo.bIMWE with (nolock) 
where Identifier=@group_ident and ImportId = @importid and RecordSeq=@batch_id_rec 

select  @imweenddate = UploadVal
from bIMWE with (nolock) 
where Identifier=@enddate_ident and ImportId = @importid and RecordSeq=@batch_id_rec
--

 
            if @imweco = @prco and @imwegroup = @prgroup and @imweenddate = @prenddate
               begin
                  Update IMWE
                  Set UploadVal = convert(varchar(6), @batch_id)
                  where ImportId = @importid and RecordSeq = @batch_id_rec and Identifier = @batch_ident

                  Update IMWE
                  Set UploadVal = convert(varchar(20), @new_mth)
                  where ImportId = @importid and RecordSeq = @batch_id_rec and Identifier = @mth_ident
               end
    
			goto nxtrec_seq
			end
    
                          select @inner_complete = 1
                          close Batch_ID_curs
                          deallocate Batch_ID_curs
  				
  				  next_prenddate:
    
                    fetch next from Batch_curs into @prco, @prgroup, @prenddate
          			if @@fetch_status = 0
           			 begin
 
 						if isnull(convert(varchar(max),@prco),'') = ''
 						begin
 							select @errmsg=isnull(@errmsg,'') + '  Import is missing PRCo in 1 or more records.',@rc=1
 							goto next_prenddate
 						end
 					
 						if isnull(convert(varchar(max),@prgroup),'') = ''
 						begin
 							select @errmsg=isnull(@errmsg,'') + '  Import is missing PRGroup in 1 or more records.',@rc=1
 							goto next_prenddate
 						end
 
                    		--mark 8/10/00
                    		select @new_mth = BeginMth
                    		from PRPC with (nolock)
                    		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    						if @@rowcount <>1
  						begin
  							select @errmsg=isnull(@errmsg,'') + '  Import Contains Invalid Payroll Ending Dates.',@rc=1
  							goto next_prenddate
  						end
                    		--end mark 8/10/00
  					 end
    
            end
        else
            select @complete = 1
    
    
    end
    
    
    --update the batch sequence numbers
   --mh 5/9 Issue 17289 - Cannot assume that the next available BatchSeq will be the 
   --next sequential number.  Some insert triggers may add additional BatchSeq...see bMSTBi
   -- update IMWE set UploadVal = RecordSeq where ImportId = @importid and Identifier = @batchseq_ident
    
    
    bspexit:
    -- 5/16/03 - Moved these to bspexit so the cursor will be closed and deallocated in case of error.
    if @openbatchcursor = 1
    begin
   	 close Batch_curs
   	 deallocate Batch_curs
    end
  
    return @rc


GO
GRANT EXECUTE ON  [dbo].[bspIMBatchAssignPR] TO [public]
GO
