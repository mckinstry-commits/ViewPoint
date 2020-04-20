SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  CREATE    procedure [dbo].[vspUpdateDMAttachmentGridColumnOrder]
  /***********************************************************
   * CREATED BY: AL 10/7/10
   * MODIFIED By : 
   *
   * USAGE:
   * Saves column order for the grid in DMAttachmentIndexSearch
   *
   ************************************************************************/
  	(@col varchar(max), @username bVPUserName, @columnorder int, @msg varchar(60) output)

  as
  set nocount on
 
  declare @rcode int
  select @rcode = 0
  
 
  if @col NOT IN (Select HQAIColumnName from DMAttachmentGridOptions WHERE UserName = @username) AND @col in (SELECT COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bHQAI' and COLUMN_NAME <> 'AttachmentID')
				  
		goto bspexit
		
  else

		insert into dbo.vDMAttachmentGridColumnOrder
		Values (@username, @col, @columnorder)    
	
	
   if @@rowcount = 0
  	begin
		select @msg = 'Record was not saved!', @rcode = 1
		goto bspexit
	end


  bspexit:
  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspUpdateDMAttachmentGridColumnOrder] TO [public]
GO
