SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHQAttIDVal]
   /*************************************
   * validates HQ Attachment ID
   *
   * CREATED: ???
   * MODIFIED: RT 08/24/04 - Issue #21497, add OrigFileName parameter.
   * MODIFIED: JVH 6/1/09 - Issue #132797, add Description parameter.
   *
   * Pass:
   *	HQ Attachment ID to be validated
   *
   * Success returns:
   *	0 and Description from bHQAT
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@AttID int, @FormName varchar(30) output, @FilePath varchar(128) output, 
   		@OrigFileName varchar(255) output, @Description varchar(255) output, @msg varchar(60) output)
   as 
   
   set nocount on
   declare @rcode int
   select @rcode = 0
   	
   if @AttID is null
   	begin
   	select @msg = 'Missing Attachment ID', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @FormName = FormName, @FilePath = DocName, @OrigFileName = OrigFileName, @Description = Description
   from bHQAT where AttachmentID = @AttID
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Attachment ID.', @rcode = 1
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQAttIDVal] TO [public]
GO
