SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  CREATE    procedure [dbo].[vspUpdateDMAttachmentGridOptions]
  /***********************************************************
   * CREATED BY: AL 12/3/09
   * MODIFIED By : 
   *
   * USAGE:
   * Saves user options for Attachement index search form
   *
   ************************************************************************/
  	(@username dbo.bVPUserName, @hqaicolumnname varchar(50), @msg varchar(60) output)

  as
  set nocount on
 
  declare @rcode int
  select @rcode = 0
  		  
			if not exists (select * from vDMAttachmentGridOptions where
																		UserName = @username and HQAIColumnName = @hqaicolumnname)
			begin
			
								insert into dbo.vDMAttachmentGridOptions
								Values (@username,+@hqaicolumnname)    
			end			
	
   if @@rowcount = 0
  	begin
  						select @msg = 'Record was not saved!', @rcode = 1
								goto bspexit
			end


  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspUpdateDMAttachmentGridOptions] TO [public]
GO
