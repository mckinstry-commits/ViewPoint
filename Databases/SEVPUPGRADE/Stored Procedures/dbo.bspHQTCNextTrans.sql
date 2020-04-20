SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspHQTCNextTrans]
   /*********************************************************
    * Created: ??
    * Modified: GG 04/15/02 - cleanup
    *			 GF 07/15/2003 - issue #21820 added table hint to do (ROWLOCK) on update.
    *			 GF 08/07/2003 - issue #22085 Pad1,Pad2,Pad3,Pad4 columns dropped from bHQTC
   			RM 03/26/04 - Issue# 23061 - Added IsNulls
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
   (@tablename char(20) = null, @co bCompany = 0, @mth bMonth = null, @errmsg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int, @errno int, @rowcount int
   
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
   
   exec @errno = bspHQCompanyVal @co, @errmsg output
   if @errno <> 0 goto bspexit
   	
   -- update last trans# - add HQTC entry if needed 
   begin tran
   update bHQTC
   set LastTrans = LastTrans + 1
   from bHQTC with (ROWLOCK)
   where TableName = @tablename and Co = @co and Mth = @mth
   if @@rowcount = 0
   	begin
   	insert bHQTC (TableName, Co, Mth, LastTrans)
   	values (@tablename, @co, @mth, 1)
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
GRANT EXECUTE ON  [dbo].[bspHQTCNextTrans] TO [public]
GO
