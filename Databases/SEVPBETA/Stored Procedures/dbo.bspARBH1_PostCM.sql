SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBH1_PostCM    Script Date: 8/28/99 9:36:03 AM ******/
   CREATE procedure [dbo].[bspARBH1_PostCM]
   /***********************************************************
   * CREATED BY  : JRE 8/28/97
   * MODIFIED By : JM 7/1/98 - changed line 132 to hardcode CMTransType 2
   *		rather than 1
   * 		GH 7/19/99 - Corrected where clause that checked for Source of 'AR Deposit'
   *               when it should have checked for Source of 'AR Receipt'
   *  		GR 6/15/00 updated the ActDate on update of CMDT issue 6669
   *	    TJL 2/23/01 Adjustment when updating existing CMTrans#
   *		TJL 08/08/03 - Issue #22087, Performance mods add NoLocks
   *		TJL 08/29/08 - Issue #129600, "Select" from table bCMDT rather then from view CMDT
   * USAGE:
   * Posts a validated batch of bARBC CM Amounts
   * and deletes successfully posted bARBC rows
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
   (@arco bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null,  @errmsg varchar(60) output)
   
   as
   
   set nocount on
   
   declare @actdate bDate,
       @amount bDollar,
       @cmacct bCMAcct,
       @cmco bCompany,
       @cmdeposit bCMRef,
       @cmdetaildesc varchar(60),
       @cminterface tinyint,
       @cmsummarydesc varchar(60),
       @cmtrans bTrans,
       @jrnl bJrnl,
       @nextcmrefseq tinyint,
       @rcode int,
       @source bSource,
       @tablename char(20)
   
   select @rcode=0,
       @source='AR Receipt'
   
   select @cminterface =CMInterface, @cmsummarydesc = CMSummaryDesc
   from bARCO with (nolock) 
   where ARCo=@arco
   
   if @cminterface not in (0,1)
   	begin
   	select @errmsg = 'Invalid CM Interface level', @rcode = 1
   	goto bspexit
   	end
   
   /* update CM using entries from bARBC */
   /****** no update *****/
   if @cminterface = 0	 /* no update */
       begin
       delete bARBC where ARCo = @arco and Mth = @mth and BatchId = @batchid
       goto bspexit
       end
   
   /***** summary update ******/
   /* get first CMCo */
   select @cmco=min(CMCo)
   from bARBC a with (nolock)
   where a.ARCo = @arco and a.Mth = @mth and a.BatchId = @batchid
   
   /* loop through CM Company */
   while @cmco is not null
       begin
       select @cmacct=min(CMAcct)
       from bARBC a with (nolock)
       where a.ARCo = @arco and a.Mth = @mth and a.BatchId = @batchid and a.CMCo=@cmco
   
       /* loop through CM Accounts */
       while @cmacct is not null
           begin
           select @cmdeposit=min(CMDeposit)
           from bARBC a with (nolock)
           where a.ARCo = @arco and a.Mth = @mth and a.BatchId = @batchid
               and a.CMCo=@cmco and CMAcct=@cmacct
   
           /* loop through CMDeposit */
           while @cmdeposit is not null
               begin
               select @actdate = max(ActualDate), @amount=isnull(sum(a.Amount),0)
           	from bARBC a with (nolock)
           	where a.ARCo = @arco and a.Mth = @mth and a.BatchId = @batchid and
                   a.CMCo=@cmco and a.CMAcct=@cmacct and a.CMDeposit=@cmdeposit
   
               /* update amount in CMDT if customer is referencing an existing deposit -
               *  otherwise insert new CMDT record */
               /* begin trans */
               begin transaction
              	select @cmtrans = CMTrans 
   			from bCMDT with (nolock)
           	where CMCo = @cmco and Mth = @mth and CMAcct = @cmacct
                	and StmtDate is null and CMTransType = 2
               	and SourceCo = @arco and Source = 'AR Receipt'
                	and CMRef = @cmdeposit and Void = 'N'
   
               If @@rowcount = 1
                   begin
                   /* update bCMDT.Amount to ARBC.Amount */
                   update bCMDT
                   set Amount = Amount + @amount, ActDate = @actdate, PostedDate = @dateposted, BatchId = @batchid
                   where CMCo = @cmco and Mth = @mth and CMTrans = @cmtrans
                   end
               else
                   begin
                   /* get next available transaction # for CMDT */
                   select @tablename = 'bCMDT'
                   exec @cmtrans = bspHQTCNextTrans @tablename, @cmco, @mth, @errmsg output
                   if @cmtrans = 0 goto CM_summary_posting_error
   
                   /* insert CMDT record */
              	    select @nextcmrefseq = IsNull(MAX(CMRefSeq) + 1,0)
                   from bCMDT with (nolock)
                   where CMCo = @cmco and CMAcct = @cmacct and	CMTransType = 2 and CMRef = @cmdeposit
   
                   insert bCMDT(CMCo,Mth,CMTrans,CMAcct,CMTransType,SourceCo,Source,
                       ActDate,PostedDate,Description,Amount,ClearedAmt,BatchId,CMRef,
                       CMRefSeq, GLCo,CMGLAcct,Void,Purge)
                   select @cmco, @mth, @cmtrans, @cmacct, 2,@arco, @source, @actdate,
                       @dateposted, @cmsummarydesc, @amount, 0, @batchid, @cmdeposit,
                       @nextcmrefseq, GLCo, GLAcct, 'N','N'
                   from bCMAC with (nolock) 
   				where CMCo=@cmco and CMAcct=@cmacct
   
                   if @@rowcount = 0 goto CM_summary_posting_error
               	end
   
               /* delete batch record */
               delete bARBC
               where ARCo = @arco and Mth = @mth and BatchId = @batchid
                   and CMCo = @cmco and CMAcct = @cmacct and CMDeposit=@cmdeposit
   
               /* commit trans */
               commit transaction
               goto CM_summary_posting_loop
   
   		CM_summary_posting_error:	/* error occured within transaction - rollback any updates and continue */
               rollback transaction
   
   		CM_summary_posting_loop:
           	/* get next CMDeposit */
           	select @cmdeposit=min(CMDeposit) 
   			from bARBC a with (nolock)
           	where a.ARCo = @arco and a.Mth = @mth and a.BatchId = @batchid
           		and a.CMCo=@cmco and CMAcct=@cmacct and a.CMDeposit>@cmdeposit
   
           	end /*CMDeposit */
   
       	/* get next CM Acct */
       	select @cmacct=min(CMAcct) 
   		from bARBC a with (nolock)
       	where a.ARCo=@arco and a.Mth=@mth and a.BatchId=@batchid
       		and a.CMCo=@cmco and a.CMAcct>@cmacct
   
       	end /*CMAcct*/
   
   	/* get next CMCo */
   	select @cmco=min(CMCo) 
   	from bARBC a with (nolock)
   	where a.ARCo = @arco and a.Mth = @mth and a.BatchId = @batchid and a.CMCo>@cmco
   	end /*CMCo*/
   
   /* make sure CM Audit is empty */
   if exists(select top 1 1 from bARBC with (nolock) where ARCo = @arco and Mth = @mth and BatchId = @batchid)
   	begin
   	select @errmsg = 'Not all updates to CM were posted - unable to close batch!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspARBH1_PostCM]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARBH1_PostCM] TO [public]
GO
