SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
	/****** Object:  Stored Procedure dbo.vspVAUpdateJCSecurityGroup    Script Date: 8/28/99 9:35:48 AM ******/
	CREATE proc [dbo].[vspVAUpdateJCSecurityGroup]
	/**************************************************************
	*	Object:  Stored Procedure dbo.vspVAUpdateJCSecurityGroup
	**************************************************************
	*	This is used by VA Secure Data Types and Tables to update
	*	the Security Group in the Job Cost Job master or Contract Master
	*	when data security is turned on/off or when the default security group 
	*	is changed.
	*
	*	History:
	*		JonathanP 05/03/07 - Created and adapted from bspVAUpdateJCSecurityGroup
	**************************************************************/

    
   (@Status varchar(10)=null, @Datatype varchar(30)=null, @DefaultSecurityGroup int, 
    @OldDefaultSecurityGroup int, @msg varchar(255) output) 
   
   as
   
   set nocount on
   
   begin
   	declare @rcode int
   	select @rcode = 0
   
   
   if @Status is null or @Status = ''
   	begin
   	select @msg = 'Status of Update or Clear', @rcode = 1
   	goto bspexit
   	end
   
   if @Datatype is null or (@Datatype<>'Job' and @Datatype<>'Contract')
   	begin
   	select @msg = 'Missing data type of (Job/Contract)', @rcode = 1
   	goto bspexit
   	end
   
   if @Status = 'Update' and (@DefaultSecurityGroup is null or @OldDefaultSecurityGroup is null)
   	begin
   	select @msg = 'Missing Default Security Group', @rcode = 1
   	goto bspexit
   	end
   
   
   If @Status = 'Update' 
   begin
   	If @Datatype = 'Job'
   		begin
   		update bJCJM
   		Set SecurityGroup = @DefaultSecurityGroup
   		where SecurityGroup=@OldDefaultSecurityGroup or SecurityGroup is null
   		end
   
   	If @Datatype = 'Contract'
   		begin
   		update bJCCM
   		Set SecurityGroup = @DefaultSecurityGroup
   		where SecurityGroup=@OldDefaultSecurityGroup or SecurityGroup is null
   		end
   end
   
   If @Status = 'Clear' 
   begin
   	If @Datatype = 'Job'
   		begin
   
   		update bJCJM
   		Set SecurityGroup = null
   
   		delete dbo.vDDDS
   		where Datatype='bJob' 
   
   		end
   
   	If @Datatype = 'Contract'
   		begin
   
   		update bJCCM
   		Set SecurityGroup = null
   
   		delete dbo.vDDDS
   		where Datatype='bContract' 
   
   		end
   end
   
   
   Return	@rcode
   
   bspexit:
   
   	return @rcode
   end
   
   
   
   
   
   
   
   
  
 



GO
GRANT EXECUTE ON  [dbo].[vspVAUpdateJCSecurityGroup] TO [public]
GO
