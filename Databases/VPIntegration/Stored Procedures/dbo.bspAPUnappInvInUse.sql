SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPUnappInvInUse    Script Date: 8/28/99 9:32:34 AM ******/
   CREATE  proc [dbo].[bspAPUnappInvInUse]
   /***********************************************************
    * CREATED BY	: kf 9/3/97
    * MODIFIED BY	: kf 9/3/97
    *              kb 10/29/2 - issue #18878 - fix double quotes
    *		ES 03/12/04 - #23061 isnull wrapping
	*				  MV 12/15/09 - #136356 - return 'inuseflag'
    *
    * USED IN:
    *   APUnappInv
    *
    * USAGE:
    *checks to see if UnappInv is in use, can't get in it to edit if it is
    *
    * INPUT PARAMETERS
    *   APCo  AP Co to check against
    *   UIMth Unapproved Invoice Month
    *   UISeq Unapproved Invoice Sequence
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
       (@co bCompany, @uimth bMonth, @uiseq varchar(15), @msg varchar(100) output)
   as
   
   set nocount on
   
   declare @rcode int, @InUse bBatchID, @InUseMth bMonth, @inuseby bVPUserName, @status tinyint,
   	@source bSource
   
   select @rcode = 0
   select @InUse=null
   
   
   if isnumeric(@uiseq)=1
       begin
       select @InUse=InUseBatchId, @InUseMth=InUseMth, @msg = Description from APUI
   	  where APCo = @co and UIMth=@uimth and UISeq=convert(smallint,@uiseq)
   
       if @@rowcount=0	goto bspexit
   
       if not @InUse is null
       	begin
       	select @source=Source
       	       from HQBC
       	       where Co=@co and BatchId=@InUse and Mth=@InUseMth
       	    if @@rowcount<>0
       	       begin
       		select @msg = 'Invoice already in use by ' +
       		      isnull(convert(varchar(2),DATEPART(month, @InUseMth)), '') + '/' +
       		      isnull(substring(convert(varchar(4),DATEPART(year, @InUseMth)),3,4), '') +
       			' batch # ' + isnull(convert(varchar(6),@InUse), '') + 
   			' - ' + 'Batch Source: ' + isnull(@source, ''), @rcode = 1
       		goto bspexit
       	       end
       	    else
       	       begin
       		select @msg='Invoice already in use by another batch!', @rcode=1
       		goto bspexit
       	       end
           end
   	end

	
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPUnappInvInUse] TO [public]
GO
