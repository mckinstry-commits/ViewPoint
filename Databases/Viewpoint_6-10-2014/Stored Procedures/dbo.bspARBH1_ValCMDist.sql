SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBH1_ValCMDist    Script Date: 8/28/99 9:36:04 AM ******/
CREATE proc [dbo].[bspARBH1_ValCMDist]
/***********************************************************
* CREATED BY: 	 JRE
* MODIFIED By :  JM 6/17/99 - Changed sign for @oldcreditamt from + to - in last insert bARBC
*	statement, approx line 113. Ref Issue 4333.
*		TJL 08/08/03 - Issue #22087, Performance mod, add NoLocks
*		GH 9/19/06 - Issue #122492, Added CMTransType to where clause
*
* USAGE:
* Validates each cm entry for a selected batch - must be called 
* prior to posting the batch. Called by Cash Val
*
* INPUT PARAMETERS
*   co        AR Co 
*   mth       Month of batch
*   batchid    Batch ID to validate                
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/ 
@co bCompany, @mth bMonth, @batchid bBatchID,@transtype char(1),
@cmco bCompany, @cmacct bCMAcct, @cmdeposit bCMRef, @transdate bDate, @creditamt bDollar,
@oldcmco bCompany, @oldcmacct bCMAcct, @oldcmdeposit bCMRef, @oldtransdate bDate, @oldcreditamt bDollar,
@errorstart varchar(50),@errmsg varchar(255) output 
as

set nocount on

declare @rcode int,@errortext varchar(255), @CMSTStatus tinyint
   
select @rcode=0
if @transtype='A' select @oldcreditamt=0  /* dont subtract any amt*/
if @transtype='D' select @creditamt=0  /* dont add amt*/
if IsNull(@creditamt,0)<>0  /* dont check if cash is not being applied */
	begin
	if not exists (select 1 from bCMAC with (nolock) where CMCo=@cmco and CMAcct=@cmacct)
		BEGIN
		select @errortext = isnull(@errorstart,'') + ' - Invalid CM Account CMAcct: ' + isnull(convert(varchar(6),@cmacct),'')
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		goto bspexit
		END
   
   	select @CMSTStatus=max(s.Status)
   	from bCMDT d with (nolock)
   	join bCMST s with (nolock) on s.CMCo=d.CMCo and s.CMAcct=d.CMAcct and s.StmtDate=d.StmtDate
   	where d.CMCo=@cmco and d.Mth=@mth and d.CMAcct=@cmacct and d.CMRef=@cmdeposit
   	if @CMSTStatus>1
   		BEGIN
   		select @errortext = isnull(@errorstart,'') + ' - Invalid CM Reference! '
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		END
   
   	if exists(select top 1 1 from bCMDT with (nolock)
               where CMCo=@cmco and Mth=@mth and CMAcct=@cmacct and CMRef=@cmdeposit
               	and SourceCo<>@cmco and Source<>'AR Receipt' and CMTransType=2)
   		BEGIN
   		select @errortext = isnull(@errorstart,'') + ' - CM Reference not for this Company or AR Receipt! '
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		END
   
   	update bARBC
   	set Amount=Amount + @creditamt,
   		ActualDate = case when ActualDate > @transdate then ActualDate else @transdate end
   	where ARCo=@co and Mth=@mth and BatchId=@batchid and CMCo=@cmco and CMAcct=@cmacct and CMDeposit=@cmdeposit 
	if @@rowcount=0
   		BEGIN
           insert into bARBC(ARCo, Mth, BatchId, CMCo, CMAcct, CMDeposit, OldNew, ActualDate, Amount)  
           values (@co, @mth, @batchid, @cmco, @cmacct, @cmdeposit, 1, @transdate, @creditamt)
   		END
   	END
   
if IsNull(@oldcreditamt,0)<>0  /* dont check if cash is not being applied */
   	begin
   	if not exists (select 1 from bCMAC with (nolock) where CMCo=@oldcmco and CMAcct=@oldcmacct)
       	BEGIN
   		select @errortext = isnull(@errorstart,'') + ' - Invalid old CM Acct! '
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		goto bspexit
   		END
   
   	select @CMSTStatus=max(s.Status)
   	from bCMDT d with (nolock)
   	join bCMST s with (nolock) on s.CMCo=d.CMCo and s.CMAcct=d.CMAcct and s.StmtDate=d.StmtDate
   	where d.CMCo=@oldcmco and d.Mth=@mth and d.CMAcct=@oldcmacct and d.CMRef=@oldcmdeposit
   	if @CMSTStatus>1
   		BEGIN
   		select @errortext = isnull(@errorstart,'') + ' - Invalid old CM Reference! '
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		END
   
	if exists(select top 1 1 from bCMDT with (nolock)
               where CMCo=@oldcmco and Mth=@mth and CMAcct=@oldcmacct and CMRef=@oldcmdeposit
               	and SourceCo<>@cmco and Source<>'AR Receipt' and CMTransType=2)
   		BEGIN
   		select @errortext = isnull(@errorstart,'') + ' - old CM Reference not for this Company or AR Receipt! '
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		END
   
	update bARBC
   	set Amount=Amount - @oldcreditamt
   	where ARCo=@co and Mth=@mth and BatchId=@batchid
       	and CMCo=@oldcmco and CMAcct=@oldcmacct and CMDeposit=@oldcmdeposit
	if @@rowcount=0
       	BEGIN
           insert into bARBC(ARCo, Mth, BatchId, CMCo, CMAcct, CMDeposit, OldNew, ActualDate, Amount)  
           values (@co, @mth, @batchid, @oldcmco, @oldcmacct, @oldcmdeposit, 0, @oldtransdate, -@oldcreditamt)
   		END
   	END
   
bspexit:
   	if @rcode <> 0 select @errmsg = @errmsg			--+ char(13) + char(10) + '[bspARBH1_ValCMDist]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARBH1_ValCMDist] TO [public]
GO
