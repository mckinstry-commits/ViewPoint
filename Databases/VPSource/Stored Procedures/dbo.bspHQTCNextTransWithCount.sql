SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspHQTCNextTransWithCount]
   /*********************************************************
    * Created By:	GF 10/03/2003
    * Modified By:
   			RM 03/26/04 - Issue# 23061 - Added IsNulls
    *
    * This SP is currently used by bspMSTBPost only. Passes in number of transactions
    * that is needed. Does one update to bHQTC for this count.
    *
    *
    * Usage:
    *	Called to inserts/updates entries in bHQTC for next available trans #
    *
    * 	Transaction #s are unique within Table, Company, and Month
    *
    * Inputs:
    *	@tablename		Table to get next trans# from
    *	@co				Company
    *	@mth			Month
    *
    * Output:
    *	@errmsg			Error message
    *
    * Return code:
    *	0				Error, no trans# available
    *	######			Next available trans#
    *
    ****************************************************************/
   (@tablename char(20) = null, @co bCompany = 0, @mth bMonth = null, @count bTrans = null, @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @errno int
   
   select @rcode = 0
   	
   if @tablename is null
   	begin
   	select @errmsg = 'Missing Table Name!'
   	goto bspexit
   	end
   
   if @co = 0 
   	begin
   	select @errmsg = 'Missing Company #!'
   	goto bspexit
   	end
   
   if @mth is null
   	begin
   	select @errmsg = 'Missing month!'
   	goto bspexit
   	end
   
   if @count is null
   	begin
   	select @errmsg = 'Missing transaction increment count!'
   	goto bspexit
   	end
   
   --exec @errno = bspHQCompanyVal @co, @errmsg output
   --if @errno <> 0 goto bspexit
   
   -- update last trans# - add HQTC entry if needed 
   begin tran
   update bHQTC
   set LastTrans = LastTrans + @count
   from bHQTC with (ROWLOCK)
   where TableName = @tablename and Co = @co and Mth = @mth
   if @@rowcount = 0
   	begin
   	insert bHQTC (TableName, Co, Mth, LastTrans)
   	values (@tablename, @co, @mth, @count)
   	end
   
   -- get last trans#
   select @rcode = LastTrans
   from bHQTC with (nolock)
   where TableName = @tablename and Co = @co and Mth = @mth
   if @@rowcount = 0
   	begin
   	-- error
   	rollback tran	
   	select @errmsg = 'Unable to get next available trans# for ' + isnull(@tablename,'') + '!'
   	goto bspexit
   	end
   	
   commit tran
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQTCNextTransWithCount] TO [public]
GO
