SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspEMBFPostRB    Script Date: 8/28/99 9:34:24 AM ******/
   CREATE    procedure [dbo].[bspEMBFPostRB]
   /***********************************************************
    * CREATED BY  : bc 04/05/99
    * MODIFIED By :TV 02/11/04 - 23061 added isnulls
	*				GF 01/19/2013 TK-20836 write out GLCo and Account to EMRB from EMBC
	*
    *
    * USAGE:
    * Posts a validated batch of bEMRB Revenue breakdown amount
    * and deletes successfully posted bEMRB rows
    *
    * INPUT PEMAMETERS
    *   EMCo        EM Co
    *   Month       Month of batch
    *   BatchId     Batch ID to validate
   
    *
    * OUTPUT PEMAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   
   (@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output)
   as
   
   set nocount on
   declare @rcode int, @openEMRBcursor tinyint
   
   declare @seq int, @emtrans int, @emgroup bGroup, @equip bEquip, @revcode bRevCode, @bdowncode varchar(10),
           @amount bDollar
		   ----TK-20836
		   ,@GLCo bCompany, @Account bGLAcct

   
   select @rcode=0, @openEMRBcursor = 0
   
   /* update EM using entries from bEMBC */
   /*****  update ******/
       declare bcEMRB cursor for
   
       select BatchSeq, EMTrans, EMGroup, Equipment, RevCode, RevBdownCode, BdownRate
				----TK-20836
				,GLCo, RTRIM(Account)
       from bEMBC
       where EMCo = @co and Mth = @mth and BatchId = @batchid and OldNew = 1
   
       /* open cursor */
       open bcEMRB
       select @openEMRBcursor = 1
   
       /* loop through all rows in cursor */
           EM_posting_loop:
           fetch next from bcEMRB into @seq, @emtrans, @emgroup, @equip, @revcode, @bdowncode, @amount
					----TK-20836
					,@GLCo, @Account
   
           if @@fetch_status = -1 goto EM_posting_end
           if @@fetch_status <> 0 goto EM_posting_loop
   
   
   /* begin transaction */
       begin transaction
   
   /* insert EMRB record */
       insert into bEMRB (EMCo, Mth, Trans, EMGroup, RevBdownCode, Equipment, RevCode, Amount
					----TK-20836
					,GLCo, Account)
       values (@co, @mth, @emtrans, @emgroup, @bdowncode, @equip, @revcode, @amount
					----TK-20836
					,@GLCo, @Account)

       if @@rowcount = 0 goto EM_posting_error
   
           /* delete current row from cursor */
     	    delete bEMBC
           where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and EMGroup = @emgroup and
                 Equipment = @equip and RevCode = @revcode and RevBdownCode = @bdowncode and OldNew = 1
           if @@rowcount <> 1
               begin
    	        select @errmsg = 'Unable to remove posted distributions from EMBC.', @rcode = 1
     	        goto EM_posting_error
    	        end
   
           commit transaction
   
           goto EM_posting_loop
   
       EM_posting_error:
           rollback transaction
           goto bspexit
   
       EM_posting_end:
           close bcEMRB
           deallocate bcEMRB
   
           select @openEMRBcursor = 0
   
   /* old rev breakdown codes are not backed out of EMRB.  the old values are only used for GL purposes. */
   delete bEMBC
   where EMCo = @co and Mth = @mth and BatchId = @batchid and OldNew = 0
   
   /* make sure EM Audit is empty */
   if exists(select 1 from bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid)
   	begin
   	select @errmsg = 'Not all updates to EM were posted - unable to close batch!', @rcode = 1
   	goto bspexit
   	end
   



   bspexit:
    	if @openEMRBcursor = 1
             begin
    	  close bcEMRB
    	  deallocate bcEMRB
    	  end
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMBFPostRB] TO [public]
GO
