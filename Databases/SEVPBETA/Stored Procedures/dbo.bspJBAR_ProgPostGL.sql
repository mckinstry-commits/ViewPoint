SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspJBAR_ProgPostGL]
   /***********************************************************
   * CREATED BY  : bc 10/27/99
   * MODIFIED By : TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
   *		TJL 03/17/08 - Issue #125508, Adjust Customer value in GL Description for 10 characters
   *
   * USAGE:
   * 	Posts a validated batch of bJBGL GL Amounts
   * 	and deletes successfully posted bJBGL rows
   *
   * INPUT PARAMETERS
   *   JBCo        JB Co
   *   Month       Month of batch
   *   BatchId     Batch ID to validate
   *   DatePosted  Date Batch is Posted
   *   PostGLtype  Used to determine which detail level to use
   *               must be 'Invoice'
   *
   * OUTPUT PARAMETERS
   *   @errmsg     if something went wrong
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/
   
   (@jbco bCompany, @Mth bMonth, @BatchId bBatchID, @DatePosted bDate = null,
   	@PostGLtype char(10), @Source char(10), @errmsg varchar(255) output)
   as
   
   set nocount on
   declare @rcode int, @tablename char(20)
   
   select @rcode=0
   declare @arco bCompany, @GLCo bCompany, @GLAcct bGLAcct, @BatchSeq int, @ARLine smallint, @OldNew tinyint,
   	@ARTrans bTrans, @CustGroup bGroup, @Customer bCustomer,
   	@SortName varchar(15), @Invoice varchar(10),
   	@Contract bContract, @ContractItem bContractItem, @ActDate bDate,
   	@Description bDesc, @Amount bDollar
   
   declare @glinterfacelvl tinyint, @gltrans bTrans, @Desccontrol varchar(60),
       @gldetaildesc varchar(60), @jrnl bJrnl, @glsummarydesc varchar(60), @Desc varchar(60),
       @findidx int, @found varchar(10), @InterfaceDetail char(1), @glref bGLRef
   
   if @PostGLtype not in ('Invoice')
    	begin
    	select @errmsg = 'Invalid PostGLtype!!', @rcode = 1
    	goto bspexit
    	end
   if @Source is null
    	begin
    	select @errmsg = 'Invalid Source!', @rcode = 1
    	goto bspexit
    	end
   
   if @PostGLtype in ('Invoice')
    	begin
   	/* get the proper AR company */
   	select @arco = ARCo
   	from bJCCO with (nolock)
   	where JCCo = @jbco
   
    	select @glinterfacelvl = GLInvLev,
    		   @jrnl = InvoiceJrnl,
    		   @glsummarydesc = GLInvSummaryDesc,
    		   @gldetaildesc = GLInvDetailDesc
    	from bARCO with (nolock)
    	where ARCo=@arco
    	end
   
   if @glinterfacelvl is null
    	begin
    	select @errmsg = 'GL Interface level may not be null', @rcode = 1
    	goto bspexit
    	end
   
   if @jrnl is null and @glinterfacelvl > 0
    	begin
    	select @errmsg = 'Journal may not be null', @rcode = 1
    	goto bspexit
    	end
   
   /* update GL using entries from bJBGL */
   /* no update */
   if @glinterfacelvl = 0	 /* no update */
   	begin
   	delete bJBGL where JBCo = @jbco and Mth = @Mth and BatchId = @BatchId
   	goto bspexit
   	end
   
   /* set GL Reference using Batch Id - right justified 10 chars */
   select @glref = space(10-datalength(convert(varchar(10),@BatchId))) + convert(varchar(10),@BatchId)
   
   /* summary update */
   if @glinterfacelvl = 1	 /* summary - one entry per GL Co/GLAcct, unless GL Acct flagged for detail */
   	begin
    	select @GLCo=min(GLCo)
     	from bJBGL a with (nolock)
      	where a.JBCo = @jbco and a.Mth = @Mth and a.BatchId = @BatchId
   
    	/* loop through GL Company */
    	while @GLCo is not null
    	  	begin
     	  	select @GLAcct= min(GLAcct)
         	from bJBGL a with (nolock)
         	where a.JBCo = @jbco and a.Mth = @Mth and a.BatchId = @BatchId and a.GLCo=@GLCo
         	/* loop through GL Accounts */
         	while @GLAcct is not null
           	begin
    	    	select @Amount=isnull(sum(a.Amount),0), @InterfaceDetail=min(g.InterfaceDetail)
    	    	from bJBGL a with (nolock)
           	join bGLAC g with (nolock) on a.GLCo = g.GLCo and a.GLAcct = g.GLAcct
    	    	where a.JBCo = @jbco and a.Mth = @Mth and a.BatchId = @BatchId and a.GLCo=@GLCo and a.GLAcct=@GLAcct
           	group by a.GLCo, a.GLAcct
   
            	if @@rowcount=0
      	      		begin
              		select @errmsg = 'Invalid GL Account ' + isnull(@GLAcct,'') + ' !', @rcode = 1
              		rollback
              		goto bspexit
              		end
   
            	if @InterfaceDetail = 'Y' goto gl_summary_posting_loop
   
    	    	begin transaction
   
   
            	/* get next available transaction # for GLDT */
            	select @tablename = 'bGLDT'
            	exec @gltrans = bspHQTCNextTrans @tablename, @GLCo, @Mth, @errmsg output
   
            	if @gltrans = 0 goto gl_summary_posting_error
   
            	insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
    	         	ActDate, DatePosted, Description, BatchId, Amount, RevStatus,
    			  	Adjust, InUseBatchId, Purge)
    	    	values(@GLCo, @Mth, @gltrans, @GLAcct, @jrnl, @glref, @jbco, @Source, @DatePosted,
    			   	@DatePosted, @glsummarydesc, @BatchId, @Amount, 0, 'N', null, 'N')
   
            	if @@rowcount = 0 goto gl_summary_posting_error
   
            	delete bJBGL
            	where JBCo = @jbco and Mth = @Mth and BatchId = @BatchId and GLCo = @GLCo and GLAcct = @GLAcct
   
            	commit transaction
   
            	goto gl_summary_posting_loop
   
            gl_summary_posting_error:	/* error occured within transaction - rollback any updates and continue */
    	    	rollback transaction
   
            gl_summary_posting_loop:
       	    /* get next GL Acct */
            	select @GLAcct=min(GLAcct)
            	from bJBGL a with (nolock)
            	where a.JBCo=@jbco and a.Mth = @Mth and a.BatchId = @BatchId and a.GLCo=@GLCo 
   				and a.GLAcct>@GLAcct
   
            	end /*GLAcct*/
   
    	  	/* get next GLCo */
    	  	select @GLCo=min(GLCo)
          	from bJBGL a with (nolock)
          	where a.JBCo = @jbco and a.Mth = @Mth and a.BatchId = @BatchId and a.GLCo > @GLCo
   
          	end /*GLCo*/
   
   	end /* interface level=1 */
   
   /* detail update to GL for everything remaining in bJBGL */
   
   /* one GLAcct / Trans */
   select @GLCo=min(GLCo)
   from bJBGL a with (nolock)
   where a.JBCo = @jbco and a.Mth = @Mth and a.BatchId = @BatchId
   --- loop through GL Company
   while @GLCo is not null
      	begin
      	select @GLAcct=min(GLAcct)
      	from bJBGL a with (nolock)
      	where a.JBCo = @jbco and a.Mth = @Mth and a.BatchId = @BatchId and a.GLCo=@GLCo
   
      	--- loop through GL Accounts
      	while @GLAcct is not null
        	begin
        	select @BatchSeq=min(BatchSeq)
        	from bJBGL a with (nolock)
        	where a.JBCo = @jbco and a.Mth = @Mth and a.BatchId = @BatchId and a.GLCo=@GLCo 
   			and GLAcct=@GLAcct
        	--- loop through BatchSeq
        	while @BatchSeq is not null
          		begin
          		select @ARTrans = max(ARTrans), @CustGroup = max(CustGroup),
                 	@Customer = max(Customer), @SortName = max(SortName), @Invoice = Max(Invoice),
                 	@Contract = Max(Contract), @ActDate = Max(ActDate),  @Description = Max(Description),
                 	@Amount=IsNull(sum(Amount),0)
          		from bJBGL a with (nolock)
          		where a.JBCo = @jbco and a.Mth = @Mth and a.BatchId = @BatchId and a.GLCo=@GLCo	
   				and a.GLAcct=@GLAcct and a.BatchSeq=@BatchSeq
   
          		begin transaction
          		--- parse out the description
          		select @Desccontrol = isnull(rtrim(@gldetaildesc),''), @Desc = ''
          		while (@Desccontrol <> '')
            		begin
            		select @findidx = charindex('/',@Desccontrol)
            		if @findidx = 0
              			begin
              			select @found = @Desccontrol
              			select @Desccontrol = ''
              			end
            		else
              			begin
              			select @found=substring(@Desccontrol,1,@findidx-1)
              			select @Desccontrol = substring(@Desccontrol,@findidx+1,60)
              			end
   
            		if @found = 'Trans Type' select @Desc = isnull(@Desc,'') + '/' + isnull(convert(varchar(8), 'Invoice'),'')
            		if @found = 'Trans #' select @Desc = isnull(@Desc,'') + '/' + isnull(convert(varchar(10), @ARTrans),'')
            		if @found = 'Cust #' select @Desc = isnull(@Desc,'') + '/' + isnull(convert(varchar(10), @Customer),'')
            		if @found = 'Sort Name'	select @Desc = isnull(@Desc,'') + '/' + isnull(@SortName,'')
            		if @found = 'Invoice' select @Desc = isnull(@Desc,'') + '/' + isnull(convert(varchar(10), @Invoice),'')
            		if @found = 'Contract' select @Desc = isnull(@Desc,'') + '/' + isnull(@Contract,'')
            		if @found = 'Desc' select @Desc = isnull(@Desc,'') + '/' + isnull(@Description,'')
   
    				end 
   
          		-- remove leading '/'
          		if substring(@Desc,1,1)='/' select @Desc = substring(@Desc,2,datalength(@Desc))
   
          		/* get next available transaction # for GLDT */
          		select @tablename = 'bGLDT'
          		exec @gltrans = bspHQTCNextTrans @tablename, @GLCo, @Mth, @errmsg output
   
          		if @gltrans = 0 goto gl_detail_posting_error
   
          		insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
    				ActDate, DatePosted, Description, BatchId, Amount, RevStatus,
    				Adjust, InUseBatchId, Purge)
          		values(@GLCo, @Mth, @gltrans, @GLAcct, @jrnl, @glref, @jbco, @Source,
    			 	@ActDate, @DatePosted, @Desc, @BatchId, @Amount, 0, 'N', null, 'N')
   
          		if @@rowcount = 0 goto gl_detail_posting_error
   
          		--- delete from bJBGL ---
          		delete bJBGL
          		where JBCo=@jbco and Mth = @Mth and BatchId = @BatchId and GLCo=@GLCo and GLAcct=@GLAcct 
   				and BatchSeq=@BatchSeq
   
          		commit transaction
   
          		goto gl_detail_posting_loop
   
          	gl_detail_posting_error: /* error occured within transaction - rollback any updates and continue */
          		rollback transaction
   
          	gl_detail_posting_loop:	/* no more rows to process */
          		--- get next BatchSeq
          		select @BatchSeq=min(BatchSeq)
          		from bJBGL a with (nolock)
          		where a.JBCo = @jbco and a.Mth = @Mth and a.BatchId = @BatchId and a.GLCo=@GLCo 
   				and GLAcct=@GLAcct and a.BatchSeq > @BatchSeq
          		end /* Batch Seqs */
   
        	--- get next GL Acct
        	select @GLAcct=min(GLAcct)
        	from bJBGL a with (nolock)
        	where a.JBCo=@jbco and a.Mth = @Mth and a.BatchId = @BatchId and a.GLCo = @GLCo	
   			and a.GLAcct > @GLAcct
        	end /* GLAccts */
   
      	--- get next GLCo
      	select @GLCo=min(GLCo)
      	from bJBGL a with (nolock)
      	where a.JBCo=@jbco and a.Mth = @Mth and a.BatchId = @BatchId and a.GLCo > @GLCo
      	end /* GLCos */
   
   --- make sure GL Audit is empty
   if exists(select 1 from bJBGL with (nolock) where JBCo = @jbco and Mth = @Mth and BatchId = @BatchId)
    	begin
    	select @errmsg = 'Not all updates to GL were posted - unable to close batch!', @rcode = 1
    	goto bspexit
    	end
   
   bspexit:
    	if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspJBAR_ProgPostGL]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBAR_ProgPostGL] TO [public]
GO
