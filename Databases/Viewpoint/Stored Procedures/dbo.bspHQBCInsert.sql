SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQBCInsert    Script Date: 8/28/99 9:36:18 AM ******/
   CREATE  procedure [dbo].[bspHQBCInsert]
   /*******************************************************
   * Created: ???
   * Last Modified: 12/18/97 GG
   *
   * Called by Batch Selection form to get next available 
   * BatchId # and add entry to bHQBC. CreatedBy and InUseBy
   * are set to the current user. Status is 0 (open)
   *
   * Input Params: Company, Month, Source, Batch Table Name,
   *	Restrict, Adjust, PR Group, and PR Ending Date
   *
   * Ouput Params: error message if fails to add bHQBC
   *
   * Return code: BatchId if success, 0 if error
   ********************************************************/
   
   	@co bCompany, @month bMonth, @source bSource,
   	@batchtable char(20), @restrict bYN, @adjust bYN, 
   	@prgroup bGroup = null, @prenddate bDate = null,
   	@errmsg varchar(60) output
   
   
   as
   set nocount on
   declare @batchid bBatchID, @date smalldatetime, @rcode int, 
   	 @tablename char(20), @user bVPUserName
   	
   select @rcode = 0
   
   /* get next available BatchId # */
   select @tablename = 'bHQBC'
   exec @batchid = bspHQTCNextTrans @tablename, @co, @month, @errmsg output
   if @batchid = 0
   	begin
   		select @errmsg = 'Unable to get next BatchId #!'
   		goto bspexit
   	end
   	
   /* add HQ Batch Control entry */
   select @date = getdate(), @user = SUSER_SNAME()
   insert into bHQBC (Co, Mth, BatchId, Source, TableName, InUseBy,
   		DateCreated, CreatedBy, Status, Rstrict, Adjust,
   		PRGroup, PREndDate, DatePosted, DateClosed, Notes)
   values (@co, @month, @batchid, @source, @batchtable, @user, @date, @user,
   	 0, @restrict, @adjust, @prgroup, @prenddate, null, null, null)
   if @@rowcount = 0
   	begin
   		select @errmsg = 'Unable to add HQ Batch Control entry!'
   		goto bspexit
   	end
   
   select @rcode = @batchid
   	
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQBCInsert] TO [public]
GO
