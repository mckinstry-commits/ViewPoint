SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMPost_Cost_SummaryGLUpdate    Script Date: 8/28/99 9:36:13 AM ******/
   CREATE   procedure [dbo].[bspEMPost_Cost_SummaryGLUpdate]
   /***********************************************************
    * CREATED BY: JM 2/12/99
    * MODIFIED By : 4/13/99 - Broken out of main posting procedure as a
    *		sub-procedure.
    *               5/2/00 DANF - Do not update GLDT with zero amounts.
    *				 TV 02/11/04 - 23061 added isnulls
    *
    * USAGE:
    *	Called by bspEMPost_Cost_Main to write Summary GL Descriptions
    *	to GLDT where applicable.
    *
    * INPUT PARAMETERS
    *   	EMCo        	EM Co
    *   	Month       	Month of batch
    *   	BatchId     	Batch ID to validate
    *   	PostingDate 	Posting date to write out if successful
    *	GLJrnl		GLJournal
    *	GLSummDesc Summary GL Description
    *
    * OUTPUT PARAMETERS
    *   	@errmsg     	If something went wrong
    *
    * RETURN VALUE
    *   	0   		Success
    *   	1   		fail
    *****************************************************/
   (@co bCompany,
   @mth bMonth,
   @batchid bBatchID,
   @dateposted bDate = null,
   @source bSource = null,
   @gljrnl bJrnl = null,
   @glsumdesc varchar(30) = null,
   @errmsg varchar(60) output)
   
   as
   
   set nocount on
   
   declare @amount bDollar,
   	@glacct bGLAcct,
   	@glco bCompany,
   	@glref bGLRef,
   	@gltrans bTrans,
   	@rcode int
   
   select @rcode = 0
   
   /* Set GL Reference using BatchId - right justified 10 chars. */
   select @glref = isnull(space(10-datalength(convert(varchar(10),@batchid))),'') +
   	isnull(convert(varchar(10),@batchid),'')
   
   /* debug */
   --select @errmsg = 'GLRef=' + @glref, @rcode = 1
   --goto bspexit
   /* debug */
   
   /* Summary - one entry per GL Co/GLAcct, unless GL Acct flagged for detail. */
   /* Spin through each GLCo. */
   select @glco=min(GLCo)
   from bEMGL
   where EMCo = @co and Mth = @mth and BatchId = @batchid
   while @glco is not null
   	begin
   
   	/* Spin through each GLAcct. */
   	select @glacct=min(GLAcct) from bEMGL
   	where EMCo = @co and Mth = @mth and BatchId = @batchid and GLCo=@glco
   	while @glacct is not null
   		begin
   
   		/* Perform insertion only if interface flag in bGLAC = 'N'. */
   		if (select InterfaceDetail from bGLAC where GLCo = @glco
   			and GLAcct = @glacct)='N'
   			begin
   			select @amount=sum(c.Amount)
   			from bEMGL c
   			where c.EMCo = @co and c.Mth = @mth
   				and c.BatchId = @batchid
   				and GLCo=@glco and GLAcct=@glacct
   
   		       	BEGIN TRANSACTION
   
   	             	/* Get next available transaction # for GLDT. */
   	         	exec @gltrans = dbo.bspHQTCNextTrans 'bGLDT', @glco, @mth,
   	         		@errmsg output
   	          	if @gltrans = 0 /* Rollback update and continue. */
   	          		begin
   
   	           		ROLLBACK TRANSACTION
   	           		goto get_next_glacct
   	           		end
   			else
   				begin
                      If @amount <> 0
                       begin
   		           	/* Insert record into bGLDT. */
   		           	insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl,
   		           		GLRef, SourceCo, Source, ActDate, DatePosted,
   		           		Description, BatchId, Amount, RevStatus,
   		           		Adjust, InUseBatchId, Purge)
   				     values(@glco, @mth, @gltrans, @glacct, @gljrnl,
         					@glref, @co, @source, @dateposted, @dateposted,
         					@glsumdesc, @batchid, @amount, 0,
         					'N', null, 'N')
   				     if @@rowcount = 0 /* Rollback update and continue. */
   		          		begin
   		           		ROLLBACK TRANSACTION
   		           		goto get_next_glacct
   		           		end
   				     else
   					  begin
   				     	/* If insertion successful, delete record from
   					    bEMGL and commit transaction. */
   		  	           	delete bEMGL where EMCo = @co and Mth = @mth
   		  	           		and BatchId = @batchid
   	 	               			and GLCo = @glco and GLAcct = @glacct
   		                  	COMMIT TRANSACTION
   		              end
                       end
  
                      else
                        begin
   				     	/* amount is zero, delete record from
   					    bEMGL and commit transaction. */
   		  	           	delete bEMGL where EMCo = @co and Mth = @mth
   		  	           		and BatchId = @batchid
   	 	               			and GLCo = @glco and GLAcct = @glacct
   		                  	COMMIT TRANSACTION
   		             end
   				end
   			end /* bGLDT update. */
   
   get_next_glacct:
   		/* Get next GLAcct for the GLCo. */
   		select @glacct=min(GLAcct)
   		from bEMGL
   		where EMCo = @co and Mth = @mth and BatchId = @batchid
   			and GLCo=@glco and GLAcct>@glacct
   		end /* GLAccts for the GLCo. */
   
   get_next_glco:
   	/* Get the next GLCo. */
   	select @glco=min(GLCo)
   	from bEMGL
   	where EMCo = @co and Mth = @mth and BatchId = @batchid and GLCo>@glco
   	end /* GLCos. */
   
   bspexit:
   	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMPost_Cost_SummaryGLUpdate]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMPost_Cost_SummaryGLUpdate] TO [public]
GO
