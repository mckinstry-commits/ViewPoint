SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspUDTHDirtySet    Script Date: 07/24/2007 08:45:06 ******/
   CREATE            proc [dbo].[vspUDTHDirtySet]
   /***********************************************************
    * CREATED BY: TEP 07/24/2007
    * MODIFIED By : 
    *
    * USAGE:
    * Set Dirty colummn value in UDTH
    *
    * INPUT PARAMETERS
    *   TableName, Dirty
    *   
    * OUTPUT PARAMETERS
    *   @errmsg        error message if something went wrong
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
   	  	(@tablename varchar(20), @dirty bYN, @errmsg varchar(500) output)
  as
  set nocount on
  begin
  	declare @rcode int
  	select @rcode = 0
  if @tablename is null
  	begin
  	select @errmsg = 'Missing Table Name', @rcode = 1
  	goto vspexit
  	end

  if @dirty is null
  	begin
  	select @errmsg = 'Missing Dirty Value', @rcode = 1
  	goto vspexit
  	end
  
  update dbo.UDTH
	set Dirty = @dirty
  	where TableName = @tablename
  
  vspexit:
  	return @rcode                                                   
  end

GO
GRANT EXECUTE ON  [dbo].[vspUDTHDirtySet] TO [public]
GO
