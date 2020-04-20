SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDLookupVal    Script Date: 8/28/99 9:32:38 AM ******/
  
  CREATE    procedure [dbo].[vspVADDSetAppPassword]
  /***********************************************************
   * CREATED BY: MJ 04/11/05
   * MODIFIED By : AL 03/14/07 Added dynamic SQL to keep the application role 
   *			   password in sync with the vDDVS password 
   *	- JRK 4/18/07 : added "with execute as 'viewpointcs'"
   *	- AL 1/16/08: Modified to ensure that role exists before attempting to modify it.					
   * USAGE:
   * gets app role security password
   *
   * INPUT PARAMETERS
  
   *   
   * INPUT PARAMETERS
   *   @msg        error message if something went wrong, otherwise description
   * RETURN VALUE
   *   0 Success
   *   1 fail
   ************************************************************************/
  	(@newpassword varchar(256), @passwordString varchar(256), @msg varchar(60) output)
  with execute as 'viewpointcs'
  as
  set nocount on
  declare @new varchar(256)
  declare @rcode int
  declare @command varchar(2000)
  select @rcode = 0
  
  	update vDDVS
	set AppRolePassword = @newpassword  
	from vDDVS 

	
	
    	if @@rowcount = 0
  	begin
  	select @msg = 'Password was not updated!', @rcode = 1
	goto bspexit
	end


	--Alters the application role to keep the password in sync with the DDVS table
	Set @new = Quotename(@passwordString,'''' )

	if exists(select * from sys.database_principals
			  where type = 'R'
			  and name = 'Viewpoint')
		begin
		set @command = 'ALTER application role Viewpoint with password = ' + @new 

		exec (@command)
		end


  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVADDSetAppPassword] TO [public]
GO
