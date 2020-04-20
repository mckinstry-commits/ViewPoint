SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[bspPCPreferredProjectSizeVal]
   /***********************************************************
    * CREATED BY:	HH TFS 50265 05/15/13
    * MODIFIED By : 
	*
    * USAGE:
    * validates PreferredProjectSizes
    * an error is returned if size is not in range [1-5]
    *
    * INPUT PARAMETERS
    *   ProjectSize
	*
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs 
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@ProjectSize int = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
    
   if @ProjectSize is null
   	begin
   	select @msg = 'Missing project size preference!', @rcode = 1
   	goto bspexit
   	end
   
   if @ProjectSize < 1 OR @ProjectSize > 5
   	begin
   	select @msg = 'Invalid project size preference!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPCPreferredProjectSizeVal] TO [public]
GO
