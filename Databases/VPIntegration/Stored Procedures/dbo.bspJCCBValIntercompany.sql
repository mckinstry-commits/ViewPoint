SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCCBValIntercompany    Script Date: 8/28/99 9:36:01 AM ******/
   
CREATE    procedure [dbo].[bspJCCBValIntercompany]
/*********************************************
* Created:	DANF 03/27/00
*			DANF 03/28/02 Corrected Intercompany accounts.
*			TV - 23061 added isnulls
*			CHS	04/29/2009	-	#131939
*
* Usage:
*  Called from the JC Transaction Batch validation procedure (bspJCCBVal)
*  to validate GL Intercompany information.
*
* Input:
*  @glco               Job cost Inventory Company
*  @inglco             Inventroy GL Company
*  @msg                Error message
*
* Return:
*  0                   success
*  1                   error
*************************************************/

@glco bCompany, @inglco bCompany, @co bCompany, @mth bMonth, @batchid bBatchID, @seq int, @oldnew int,
@costtrans bTrans, @job bJob, @phase bPhase, @costtype bJCCType, @jctranstype varchar(2), @actualdate bDate,
@description bItemDesc, @amt bDollar, @inco bCompany, @loc bLoc, @material bMatl, @msg varchar(255) output
   
   as
   
   set nocount on
   
   declare @intercoapglacct bGLAcct, @intercoarglacct  bGLAcct, @rcode int
   
   select @rcode = 0
   
    if @glco <> @inglco
        begin
      	 select @intercoarglacct = ARGLAcct, @intercoapglacct = APGLAcct
        from bGLIA
        where ARGLCo = @inglco and APGLCo = @glco
      	if @@rowcount = 0
            begin
      		select @msg = 'Intercompany AR/AP Accounts not setup in GL. From:' +
                isnull(convert(varchar(3),@inglco),'') + ' To: ' + isnull(convert(varchar(3),@glco),''), @rcode = 1
      		     goto bspexit
            end
      	-- validate intercompany GL Accounts
        exec @rcode = bspGLACfPostable @inglco, @intercoarglacct, 'R', @msg output
        if @rcode <> 0
            begin
      	      select @msg = 'Intercompany AR Account:' + isnull(@intercoarglacct,'') + ':  ' + isnull(@msg,''), @rcode = 1
      	  	  goto bspexit
          	 end
      	exec @rcode = bspGLACfPostable @glco, @intercoapglacct, 'P', @msg output
        if @rcode <> 0
       	begin
      		 select @msg = 'Intercompany AP Account:' + isnull(@intercoapglacct,'') + ':  ' + isnull(@msg,'')
      		 goto bspexit
      		end
   
    	--Insert Intercompany payable
       update bJCDA
       Set Amount = Amount - @amt
       where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@inglco and GLAcct=@intercoarglacct and BatchSeq=@seq and OldNew=@oldnew
       if @@rowcount = 0
          begin
            insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
   	      		CostTrans, Job, Phase, CostType, JCTransType,
   	        	ActDate, Description, Amount, INCo, Loc, Material)
    		 values (@co, @mth, @batchid, 'CST', @inglco, @intercoarglacct, @seq, @oldnew,
      				    @costtrans, @job, @phase, @costtype, @jctranstype,
   				    @actualdate, @description, (-1*@amt), @inco, @loc, @material)
    		 if @@rowcount = 0
   			  begin
   		  		select @msg = 'Unable to JC Detail audit!', @rcode = 1
   		   		goto bspexit
   			  end
          end
       -- Intercompany Receivables - Debit in AP GL Co#
       update bJCDA
       Set Amount = Amount + @amt
       where JCCo=@co and Mth=@mth and BatchId=@batchid and GLType='CST' and GLCo=@glco and GLAcct=@intercoapglacct and BatchSeq=@seq and OldNew=@oldnew
       if @@rowcount = 0
          begin
            insert into bJCDA (JCCo, Mth, BatchId, GLType, GLCo, GLAcct, BatchSeq, OldNew,
   	      		CostTrans, Job, Phase, CostType, JCTransType,
   	        	ActDate, Description, Amount, INCo, Loc, Material)
    		 values (@co, @mth, @batchid, 'CST', @glco, @intercoapglacct, @seq, @oldnew,
      				    @costtrans, @job, @phase, @costtype, @jctranstype,
   				    @actualdate, @description, (@amt), @inco, @loc, @material)
    		 if @@rowcount = 0
   			  begin
   		  		select @msg = 'Unable to JC Detail audit!', @rcode = 1
   		   		goto bspexit
   			  end
         end
    end
   
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCBValIntercompany] TO [public]
GO
