SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
	/****** Object:  Stored Procedure dbo.vspVAServerNameChange    Script Date: 8/28/99 9:35:48 AM ******/
	CREATE proc [dbo].[vspVAServerNameChange]
	/********************************
	* Created: DANF 05/10/07
	* Modified:	
	*
	* Used to change the server name in RPRL report locations and HQWL (word locations).
	*
	* Input:
	*	@currentservername
	*	@newservername
	*	
	* Return code:
	*	0 = success, 1 = failure
	*
	*********************************/

    
   (@currentservername varchar(120)=null, @newservername varchar(120)=null,  @msg varchar(255) output) 

   as
   
   set nocount on
   
   begin
   	declare @rcode int, @rpcount int, @wlcount int
   	select @rcode = 0
   
   
   if @currentservername is null or @currentservername = ''
   	begin
   	select @msg = 'The current server name is missing.', @rcode = 1
   	goto bspexit
   	end
   
   if @newservername is null or @newservername = ''
   	begin
   	select @msg = 'The new server name is missing.', @rcode = 1
   	goto bspexit
   	end

    
	update vRPRL
	Set Path = replace (lower(Path), '\\' + lower(@currentservername) + '\', '\\' + lower(@newservername) + '\')
	where lower(Path) like '\\' + lower(@currentservername) + '\%'
	select @rpcount = @@rowcount

	update bHQWL
	Set Path = replace (lower(Path), '\\' + lower(@currentservername) + '\', '\\' + lower(@newservername) + '\')
	where lower(Path) like '\\' + lower(@currentservername) + '\%'
	select @wlcount = @@rowcount

	select @msg = convert(varchar(3), @rpcount) + ' reports and ' + convert(varchar(3), @wlcount) + ' word location records were changed.'

	Return	@rcode
   
   bspexit:

	return @rcode
	
	end
   
   
   
   
   
   
   
   
  
 



GO
GRANT EXECUTE ON  [dbo].[vspVAServerNameChange] TO [public]
GO
