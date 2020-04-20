SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBH1_PostJCContract    Script Date: 8/28/99 9:36:03 AM ******/
   CREATE procedure [dbo].[bspARBH1_PostJCContract]
   /***********************************************************
   * CREATED BY  : JRE 8/28/97
   * MODIFIED By : JRE 4/29/99 - wrapped amounts in isnull
   *		TJL 04/30/04 - Issue #24480, Added 'with (nolock)' 
   *
   * USAGE:
   * Posts a validated batch of bARBI JC Amounts
   * and deletes successfully posted bARBI rows
   
   * 
   * INPUT PARAMETERS
   *   ARCo        AR Co 
   *   Month       Month of batch
   *   BatchId     Batch ID to validate
                 
   *
   * OUTPUT PARAMETERS
   *   @errmsg     if something went wrong
   * RETURN VALUE
   *   0   success
   
   *   1   fail
   *****************************************************/ 
   
   (@ARCo bCompany, @Mth bMonth, @BatchId bBatchID, @DatePosted bDate = null,@Source bSource,
   	@errmsg varchar(60) output)
   as
   
   set nocount on
   declare @rcode int, @tablename char(20)
   
   declare @JCCo bCompany, @Contract bContract, @Item bContractItem, @BatchSeq int, @ARTrans bTrans,
      @ARLine smallint, @OldNew tinyint, @Invoice char(10), @CheckNo char(10),
      @BilledUnits bUnits, @BilledTax bDollar, @BilledAmt bDollar, @RecvdAmt bDollar, @Retainage bDollar
   
   declare @JCInterface tinyint, @JCTrans bTrans, @ActDate bDate
   
   select @rcode=0 
   
   if @Source not in ('AR Receipt','AR Invoice', 'ARFinanceC', 'ARRelease')
   	begin
   	select @errmsg = 'Invalid Source', @rcode = 1
   	goto bspexit
   	end
   
   select @JCInterface =JCInterface 
   from bARCO with (nolock)
   where ARCo=@ARCo
   
   if @JCInterface not in (0,1)
   	begin
   	select @errmsg = 'Invalid JC Interface level', @rcode = 1
   	goto bspexit
   	end
   
   /* check for date posted */
   if @DatePosted is null
   	begin
   	select @errmsg = 'Missing posting date!', @rcode = 1
   	goto bspexit
   	end
   
   /* update JC using entries from bARBI */
   /****** no update *****/
   if @JCInterface = 0	 /* no update */
       begin
       delete bARBI where ARCo = @ARCo and Mth = @Mth and BatchId = @BatchId
       goto bspexit
       end
   
   /*****  update ******/
   /* loop through JCCo  */
   select @JCCo=min(JCCo) 
   from bARBI a with (nolock)
   where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId
   while @JCCo is not null
   	begin
   	/* loop through Contract  */
   	select @Contract=min(Contract) 
   	from bARBI a with (nolock)
   	where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId and a.JCCo=@JCCo
   	while @Contract is not null
   		begin
   		/* loop through Item */
   		select @Item=min(Item) 
   		from bARBI a with (nolock)
   		where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId and a.JCCo=@JCCo and Contract=@Contract
   		while @Item is not null
   			begin
   			/* loop through BatchSeq  */
   			select @BatchSeq=min(BatchSeq) 
   			from bARBI a with (nolock)
      			where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId and a.JCCo=@JCCo and Contract=@Contract
        			and Item=@Item
   			while @BatchSeq is not null
   				begin
   				/* loop through each line */
   				select @ARLine=min(ARLine) 
   				from bARBI a with (nolock)
      				where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId and a.JCCo=@JCCo and Contract=@Contract
        				and Item=@Item and BatchSeq=@BatchSeq 
   				while @ARLine is not null 
   					begin
   					/*** loop through old and new ****/
   					select @OldNew=min(OldNew) 
   					from bARBI a with (nolock)
      					where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId and a.JCCo=@JCCo and Contract=@Contract
        					and Item=@Item and BatchSeq=@BatchSeq and ARLine=@ARLine
   					while @OldNew is not null
       					begin 
   
   						/* begin transaction */
       					begin transaction
   
   						/* get next available transaction # for JCID */
       					select @tablename = 'bJCID'
       					exec @JCTrans = bspHQTCNextTrans @tablename, @JCCo, @Mth, @errmsg output
       					if @JCTrans = 0 goto JC_posting_error
   
   						/* insert JCID record */
       					insert into bJCID (JCCo,Mth,ItemTrans,Contract,Item,JCTransType,TransSource,
   							Description,PostedDate,ActualDate,BilledUnits,BilledTax,BilledAmt,ReceivedAmt,CurrentRetainAmt,
   							BatchId,GLCo,GLTransAcct,ReversalStatus,ARCo,ARTrans,ARTransLine,ARInvoice,ARCheck)
   						select JCCo, @Mth, @JCTrans, Contract,Item,'AR',@Source,
         						Description, @DatePosted,ActualDate, IsNull(BilledUnits,0), IsNull(BilledTax,0),
         						IsNull(BilledAmt,0),IsNull(RecvdAmt,0),IsNull(Retainage,0),
         						@BatchId,GLCo,GLAcct,0,ARCo,ARTrans,ARLine,Invoice,CheckNo
   						from bARBI a with (nolock)
       					where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId
   							and a.JCCo=@JCCo and a.Contract=@Contract and a.Item=@Item and BatchSeq=@BatchSeq
   							and a.ARLine=@ARLine and a.OldNew=@OldNew
   
   						if @@rowcount = 0 goto JC_posting_error
   		
   						/* delete batch record */
       					delete bARBI
           				where ARCo = @ARCo and Mth = @Mth and BatchId = @BatchId
             					and BatchSeq=@BatchSeq and ARLine=@ARLine and OldNew=@OldNew
                                  
   						/* commit trans */ 	
       					commit transaction              			
       					goto JC_posting_loop
   
       				JC_posting_error:	/* error occured within transaction - rollback any updates and continue */
       					rollback transaction
   
       				JC_posting_loop:	
   
   						/*set next OldNew */
       					select @OldNew=min(OldNew) 
   						from bARBI a with (nolock)
         					where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId and a.JCCo=@JCCo
           					and Contract=@Contract and Item=@Item and BatchSeq=@BatchSeq and ARLine=@ARLine and OldNew>@OldNew
   						end
   					/*set next Line */
       				select @ARLine=min(ARLine) 
   					from bARBI a with (nolock)
         				where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId and a.JCCo=@JCCo
           				and Contract=@Contract and Item=@Item and BatchSeq=@BatchSeq and ARLine>@ARLine
   					end   /* loop through each line */
   				/* set next BatchSeq */
   				select @BatchSeq=min(BatchSeq) 
   				from bARBI a with (nolock)
   				where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId and a.JCCo=@JCCo
           			and Contract=@Contract and Item=@Item and BatchSeq>@BatchSeq          
   				end   /* loop through BatchSeq  */
   			/* set next Item */
   			select @Item=min(Item) 
   			from bARBI a with (nolock)	
         		where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId and a.JCCo=@JCCo
           		and Contract=@Contract and Item>@Item         
   			end   /* loop through Item  */
   		/* set next Contract */
   		select @Contract=min(Contract) 
   		from bARBI a with (nolock)
         	where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId and a.JCCo=@JCCo
           	and Contract>@Contract         
   		end   /* loop through Contract  */
   	/* set next JCCo */
   	select @JCCo=min(JCCo) 
   	from bARBI a with (nolock)
   	where a.ARCo = @ARCo and a.Mth = @Mth and a.BatchId = @BatchId
       	and JCCo>@JCCo         
   	end   /* loop through JCCo  */
   
   /* make sure JC Audit is empty */
   if exists(select 1 from bARBI with (nolock) where ARCo = @ARCo and Mth = @Mth and BatchId = @BatchId)
   	begin
   	select @errmsg = 'Not all updates to JC were posted - unable to close batch!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	if @rcode <> 0 select @errmsg = @errmsg			--+ char(13) + char(10) + '[bspARBH1_PostJCContract]'	
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARBH1_PostJCContract] TO [public]
GO
