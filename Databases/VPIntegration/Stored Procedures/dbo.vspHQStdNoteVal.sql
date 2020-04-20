SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspHQStdNoteVal]
  /********************************************************
  * CREATED BY:  RT 05/06/05
  * MODIFIED BY: 
  *
  * USAGE:
  * 	Returns the description matching the passed-in standard note.
  *
  * INPUT PARAMETERS:
  *   @stdnote          Standard Note
  *
  * OUTPUT PARAMETERS:
  *   @msg              Standard Note Description or error message.
  *
  * RETURN VALUE:
  * 	0 	              Success
  *	    1                 Failure
  *
  **********************************************************/
  
  	(@stdnote varchar(10) = null, @msg varchar(255) output)
  
  as
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0
  
  if @stdnote is null
  	begin
  	select @msg = 'Missing Standard Note', @rcode=1
  	goto bspexit
  	end
  
  -- get material's standard unit of measure
  select @msg = Description
  from HQNT where StdNote = @stdnote
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQStdNoteVal] TO [public]
GO
