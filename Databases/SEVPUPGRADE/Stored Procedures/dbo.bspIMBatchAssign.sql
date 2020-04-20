SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMBatchAssign]
    /************************************************************************
    * CREATED:   mh 3/18/03    
    * MODIFIED:  bc 5/11/03 - Restrict updates to tmp_table and IMWE to specific @co  
    *			 rbt 5/15/03 - Validate batch month (issue 17507).  Also fixed exec calls
    *					to use 'OUTPUT' keyword for return messages.
    *			 rbt 6/6/03 - Issue #20071, changed Co_curs definition to use ImportTemplate.
    *			 rbt 06/30/03 - Issue #21226, use existing batch number if open batch found for given
    *					import id and table.
    *			 rbt 10/20/03 - Issue #22733, make sure day part of batch month is 1.
    * 			 DANF 09/14/2004 - Issue 19246 added new login
    *	         DANF 12/21/04 - Issue #26577: Changed reference on DDUP 
    *			 rbt 08/25/05 - Issue #29656, change source parameter for call to bspHQBatchMonthVal.
    *			 DANF 12/19/06 - Corrections for 6.x related to DDUP
	*			 CC	10/09/08 - Issue #130044 Correct check for batch month day
	*			 DAN SO 06/02/09 - Issue #133887 - changed hard code @co value to @coident
    * 
    * Purpose of Stored Procedure
    *
    *	Cycle through IMWE for an ImportID/Template combination and assign
    *	Batch ID numbers to the various Company/Month combinations.  Allows 
    *	for imports into mulitiple companies.    
    *    
    *       
    *	Parameters
    *	--------------------------    
    *	@importid = ID of import
    *	@template = Import Template
    *	@form = Destination form for import
    *	@coident = Identifier for the Company field
    *	@errmsg = any error message to be returned
    *
    * Notes about Stored Procedure
    * 
    *
    * returns 0 if successfull 
    * returns 1 and error msg if failed
    *
    *************************************************************************/
    
    	(@importid varchar(20), @template varchar(10), @rectype varchar(30), 
    		@form varchar(30), @coident int, @errmsg varchar(255) output)
    
    as
    set nocount on
    
    	declare @co bCompany, @mth_ident int, @batch_ident int, 
    	@batchseq_ident int, @source bSource, @recseq int, 
    	@recseqlist varchar(8000), @rcode int, @sql varchar(8000), 
    	@treqseq int, @batchmth varchar(10), @batchid int, 
    	@slash int, @restrict bYN, @adjust bYN, @prgroup bGroup, 
    	@prenddate bDate, @cocursorflag int, @recseqcursorflag int, 
    	@batchcursorflag int, @rc int, @batchstatus int, @batchdateday varchar(2)
    
    	--Initialize return code and cursorflags
    	select @rcode = 0
    	select @cocursorflag = 0, @recseqcursorflag = 0, @batchcursorflag = 0
    
    	--get identifier that holds Month
    	select @mth_ident = Identifier from DDUD with (nolock) where Form = @form and ColumnName = 'Mth'
    
    	--get identifier that holds BatchId
    	select @batch_ident = Identifier from DDUD with (nolock) where Form = @form and ColumnName = 'BatchId'
     
    	--get identifier that holds BatchSeq
    	select @batchseq_ident = Identifier from DDUD with (nolock) where Form = @form and ColumnName = 'BatchSeq'
    
    	--get source for batch from DDUF
    	select @source = BatchSource from DDUF with (nolock) where Form = @form
    
    	--create a set of companies
    
    	declare Co_curs cursor local fast_forward for
    	select distinct UploadVal 
    	from IMWE with (nolock)
    	where ImportId = @importid and RecordType = @rectype and Identifier = @coident -- Issue: #133887
    	and ImportTemplate = @template	--#Issue 20071, Added ImportTemplate
    	order by UploadVal
    
    	open Co_curs
    	select @cocursorflag = 1
    	fetch next from Co_curs into @co
    
    	--loop through each company in cursor
    	while @co is not null
    	begin
    
    		--create a temporary table to hold the records for this company
    		if object_id('tempdb.dbo.#temp_tbl') is not null drop table #temp_tbl
    
    		create table #temp_tbl (Co tinyint null,
                                    ImportId varchar(30) null, 
                                    RecordSeq int null, 
    			                    BatchMth varchar(30) null, 
                                    BatchId int null)
    
            --populate temp_tbl for one company at a time.  
            --the most important part of issue #21252 is the join statement
     		insert #temp_tbl 
            Select @co, e1.ImportId, e1.RecordSeq, e1.UploadVal, null 
     		from IMWE e1 with (nolock)
            join IMWE e2 with (nolock) on e2.ImportId = e1.ImportId and e2.RecordType = e1.RecordType and e2.RecordSeq = e1.RecordSeq
            where e1.ImportId = @importid and e1.RecordType = @rectype and e1.Identifier = @mth_ident and 
                  e2.Identifier = @coident and e2.UploadVal = @co /* #21252 */ -- Issue: #133887
            Order By e1.UploadVal 
    
    		declare Batch_curs cursor for 
    		select RecordSeq, BatchMth, BatchId 
            from #temp_tbl 
            where BatchId is null
    
    		open Batch_curs
    		select @batchcursorflag = 1
    
    		fetch next from Batch_curs into @treqseq, @batchmth, @batchid
    
    		while @treqseq is not null
    		begin
    
    			if @batchmth is not null
        	    begin
    				--make sure @batchmth is in proper format
            		select @slash = charindex('/', @batchmth)

    	            if @slash = 3 OR @slash = 2   --we have a valid 'month/year' and not some junk
    				begin
                        select @restrict = 'N', @adjust = 'N', @prgroup = null, @prenddate = null
    				  	/* Get Restricted batch default from DDUP */
    					select @restrict = isnull(RestrictedBatches,'N')
    					from dbo.vDDUP with (nolock)
    					where VPUserName = SUSER_SNAME() 
    					if @@rowcount <> 1 and (SUSER_SNAME()<>'bidtek' and SUSER_SNAME()<>'viewpointcs' )
    					 	begin
    						select @rcode = 1, @errmsg = 'Missing user: ' + SUSER_SNAME() + ' from User Profile in VA.'
    						goto bspexit
    						end
    					--RT #22733 - make sure day part of date is = 1
						select @batchdateday = substring(@batchmth, @slash+1, charindex('/',@batchmth, @slash+1)-@slash-1)
    					--select @batchdateday = substring(@batchmth, @slash+1, charindex('/',@batchmth, @slash+1)-1)

    					if @batchdateday <> '01' and @batchdateday <> '1'
    					begin
    						select @rcode = 1
    						select @errmsg = 'Batch month error: Day must be "01".  Check work edit.'
    						goto bspexit
    					end
    					--Validate the month (issue #17507)
   					--Call bspHQBatchMonthVal and pass "GLDB" if that's the source.
   					if @rectype = 'GLDB'
    						exec @rc = bspHQBatchMonthVal @co, @batchmth, 'GL Jrnl', @errmsg output
   					else
   						exec @rc = bspHQBatchMonthVal @co, @batchmth, 'IM Upload', @errmsg output
   
    					if @rc <> 0
    					begin	 
    						select @rcode = 1
    						goto bspexit
    					end
    
    					--RT 21226 Look for existing open batch...
    					exec @rc = bspIMGetImportBatchInfo @co, @importid, @batchmth, @batchid output, @batchstatus output, @errmsg output
    					if @rc <> 0
    					begin
    						select @rcode = 1
    						goto bspexit
    					end
    					if @batchstatus <> 0 or @batchstatus is null	--matching open batch does not exist
    					begin
    						--shell out to procedure to create the batch
    	                    exec @rc = bspIMCreateBatch  @co, @batchmth, @form, @source, @restrict, @adjust,
    	                        @prgroup, @prenddate, @batchid output, @errmsg output
    						--error checking
    						if @rc <> 0
    						begin
    							select @rcode = 1
    							goto bspexit
    						end
    					end
    
    					--update all applicable records in temp table for this batch month
    					update #temp_tbl 
                        set BatchId = @batchid 
                        where Co = @co /* #21252 */ and BatchMth = @batchmth
    				end
    				else
    				begin
    					select @errmsg = 'Batch month was not in proper format.', @rcode = 1
    					goto bspexit
    				end
    			end
    			else
    			begin
    				select @errmsg = 'Batch month was null.', @rcode = 1
    				goto bspexit
    			end
    
    			fetch next from Batch_curs into @treqseq, @batchmth, @batchid
    
    			if @@fetch_status <> 0
    				select @treqseq = null
    		end
    
    		close Batch_curs
    		deallocate Batch_curs 
    		select @batchcursorflag = 0
    
    		--Batches have been assigned in temp table.  Now join temp table
    		--to IMWE and update applicable ImportId/Template/Record Sequence/Identifier 
    		--records in IMWE
    
     		Update IMWE 
     		set UploadVal = t.BatchId
     		from IMWE i with (nolock)
     		join #temp_tbl t on t.Co = @co /* #21252 */ and i.ImportId = t.ImportId and i.RecordSeq = t.RecordSeq
     		where i.ImportId = @importid and 
     			i.ImportTemplate = @template and 
     			i.Identifier = @batch_ident and
     			i.RecordType = @rectype
    
    		--Onto next company.  Repeat the whole process.	
    		fetch next from Co_curs into @co
    
    		if @@fetch_status <> 0
    			select @co = null
    
    	end
    
    	close Co_curs
    	deallocate Co_curs
    	select @cocursorflag = 0
    
    bspexit:
    
    	--make sure to clean up the cursors.
    	if @cocursorflag = 1
    	begin
    		close Co_curs
    		deallocate Co_curs 
    	end
    
    	if @batchcursorflag = 1
    	begin
    		close Batch_curs
    		deallocate Batch_curs 
    	end
    
    	if @recseqcursorflag = 1
    	begin
    		close RecSeq_curs
    		deallocate RecSeq_curs
    	end
    
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMBatchAssign] TO [public]
GO
