SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPCOColGet    Script Date: 8/28/99 9:33:05 AM ******/
   CREATE  proc [dbo].[bspPMPCOColGet]
   /*************************************
   * CREATED BY    : JRE  12/7/97
   * LAST MODIFIED : JRE  12/7/97
   *
   * gets the Date descriptions for Pending Change Orders
   *
   * Pass:
   *	PM Document Type
   *
   * Returns:
   *      PCODate1, ShowPCODate1
   *      PCODate2, ShowPCODate2
   *      PCODate3, ShowPCODate3
   *      PCOItemDate1, ShowPCOItemDate1
   *      PCOItemDate2, ShowPCOItemDate2
   *      PCOItemDate3, ShowPCOItemDate3
   *
   * Success returns:
   *	0
   *
   * Error returns:
   
   *	1 and error message
   **************************************/
   (@doctype bDocType, @PCODate1 bDesc=null output, @ShowPCODate1 char(1)=null output,
    @PCODate2 bDesc=null output, @ShowPCODate2 char(1)=null output,
    @PCODate3 bDesc=null output, @ShowPCODate3 char(1)=null output,
    @PCOItemDate1 bDesc=null output, @ShowPCOItemDate1 char(1)=null output,
    @PCOItemDate2 bDesc=null output, @ShowPCOItemDate2 char(1)=null output,
    @PCOItemDate3 bDesc=null output, @ShowPCOItemDate3 char(1)=null output,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @doctype is null
   	begin
   	select @msg = 'Missing document type!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @PCODate1=PCODate1, @ShowPCODate1=ShowPCODate1,
   	   @PCODate2=PCODate2, @ShowPCODate2=ShowPCODate2,
   	   @PCODate3=PCODate3, @ShowPCODate3=ShowPCODate3,
   	   @PCOItemDate1=PCOItemDate1, @ShowPCOItemDate1=ShowPCOItemDate1,
   	   @PCOItemDate2=PCOItemDate2, @ShowPCOItemDate2=ShowPCOItemDate2,
   	   @PCOItemDate3=PCOItemDate3, @ShowPCOItemDate3=ShowPCOItemDate3
   from bPMDT with (nolock) where DocType = @doctype
   if @@rowcount = 0
   	begin
   	select @msg = 'PM Document type ' + isnull(@doctype,'') + ' not on file!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOColGet] TO [public]
GO
