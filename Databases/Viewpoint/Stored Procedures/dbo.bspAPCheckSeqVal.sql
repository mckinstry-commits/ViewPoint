SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPCheckSeqVal    Script Date: 8/28/99 9:32:31 AM ******/
   CREATE     procedure [dbo].[bspAPCheckSeqVal]
   /******************************
   *created:  4/10/98 kb
   *modified: 4/10/98 kb
   *		 09/10/02 mv - #17344 expand validation
   *		 10/18/02 mv - 18878 quoted identifier cleanup
   *		 11/15/02 MV - #19035 changed name to sortname,removed vendor
   *		 11/26/03 MV = #23061 isnull wrap
   * Usage:
   *	used by check print when reprinting and choose a beginning 
   *	seq it returns the vendor's name for display
   *
   * Input params:
   *	@co - Company
   *	@mth - Batch Month
   *	@batchid - Batch Id
   *	@seq - Batch Sequence
   *
   *Output params:
   *	@msg		Vendor name from Batch Seq or error text
   *
   * Return code:
   *	0 = success, 1= failure
   *
   **************************************/
   (@co bCompany, @mth bMonth, @batchid bBatchID, @seq int, @sortname varchar (60) = null,
   	@nameout varchar(60) output, @msg varchar(200) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
    
   
   if @sortname is null 
   begin
   select @nameout = Name from bAPPB  
   	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid check sequence.', @rcode = 1
   	end
   end
   
   
   if @sortname is not null 
   begin
   select @nameout = b.Name from bAPPB b join bAPVM v on b.VendorGroup=v.VendorGroup and b.Vendor=v.Vendor
   	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and @sortname=v.SortName
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid check sequence for Vendor: ' + isnull(@sortname,''), @rcode = 1
   	end
   end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPCheckSeqVal] TO [public]
GO
