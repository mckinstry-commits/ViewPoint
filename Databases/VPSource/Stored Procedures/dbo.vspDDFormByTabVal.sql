SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspDDFormByTabVal]
   /***********************************************************
    * CREATED BY: DANF 10/30/04 - Issue 23547 remove Options as a vlaifd form to apply secuity on.
    *
	* MODIFIED BY:	AL 05/03/07 - Imported To 6x 	
	*				CC	07/16/09 - #129922 - Added link for culture text			
    * USAGE:
    * validates Form
    *
    * INPUT PARAMETERS
   
    *   Form         Form Do Purge
    * INPUT PARAMETERS
    *   @FormTable         Main table from DDFH
    *   @UMTab         Tab that user memos are on.
    *   @errmsg        error message if something went wrong
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
   	(	  @Form varchar(30) = NULL   		
   		, @culture INT = NULL 
   		, @FormTable varchar(30) output
   		, @msg varchar(60) OUTPUT
   		)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   
   if @Form is null
   	begin
   	select @msg = 'Missing Form!', @rcode = 1
   	goto bspexit
   	end
   
   select @FormTable=[ViewName], @msg = ISNULL(CultureText.CultureText, DDFHShared.Title) --@UMTab=MemoTab, @desc = Title 
   from DDFHShared
   LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.TextID = DDFHShared.TitleID AND CultureText.CultureID = @culture
   where Form = @Form and Form <>'Options'
   if @@rowcount = 0
   	begin
   	select @msg = 'Form not on file!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspDDFormByTabVal] TO [public]
GO
