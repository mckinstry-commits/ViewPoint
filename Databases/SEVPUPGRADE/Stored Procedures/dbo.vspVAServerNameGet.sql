SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   

	/****** Object:  Stored Procedure dbo.vspVAServerNameGet    Script Date: 8/28/99 9:35:48 AM ******/
	CREATE proc [dbo].[vspVAServerNameGet]
	/********************************
	* Created: DANF 05/10/07
	* Modified:	
	*
	* Return the server used in RPRL.
	*
	* Input:
	*	@currentservername
	*	
	* Return code:
	*	0 = success, 1 = failure
	*
	*********************************/


	(@currentservername varchar(120) output , @msg varchar(255) output) 

	as

	set nocount on

	begin
   	declare @rcode int, @path varchar(512), @beginpos int, @endpos int
   	select @rcode = 0
    
	select top 1 @path = Path
	from vRPRL with (nolock)
	where Location = 'AP'

	if isnull(@path,'') = ''
		begin
			select top 1 @path = Path
			from vRPRL with (nolock)
			where Location = 'JC'
		end

   	if isnull(@path,'') = ''
	begin
		select @msg = 'Unable to find server name.',@rcode=1
		goto bspexit
	end

	select @beginpos = (select patindex('%\\%' , @path)) +2

	select @endpos = (select patindex('%\%' , substring(@path,@beginpos, len(@path)))) - 1

	select @currentservername = substring(@path, @beginpos, @endpos)


	Return	@rcode

	bspexit:

	return @rcode

	end

   
   
   
   
   
   
   
  
 



GO
GRANT EXECUTE ON  [dbo].[vspVAServerNameGet] TO [public]
GO
