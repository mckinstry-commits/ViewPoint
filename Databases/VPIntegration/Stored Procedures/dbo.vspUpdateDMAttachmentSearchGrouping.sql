SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  CREATE    procedure [dbo].[vspUpdateDMAttachmentSearchGrouping]
  /***********************************************************
   * CREATED BY: AL 1/7/10
   * MODIFIED By : 
   *
   * USAGE:
   * Saves grouping for the grid in DMAttachmentIndexSearch
   *
   ************************************************************************/
  	(@col varchar(50), @username bVPUserName, @msg varchar(60) output)

  as
  set nocount on
 
  declare @rcode int
  select @rcode = 0
  
		

		insert into dbo.vDMAttachmentSearchGrouping
		Values (@col, @username)    
	
	
   if @@rowcount = 0
  	begin
  						select @msg = 'Record was not saved!', @rcode = 1
								goto bspexit
			end


  bspexit:
  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspUpdateDMAttachmentSearchGrouping] TO [public]
GO
