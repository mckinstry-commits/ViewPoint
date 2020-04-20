SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspJCUOInitGet]
   /***********************************************************
    * CREATED BY	: DANF
    * MODIFIED BY	: 
    *
    * USAGE:
    *  retriving the projection initialize options in bJCUO
    *
    *
    * INPUT PARAMETERS
    *	JCCo		JC Company
    *	Form		JC Form Name
    *	UserName	VP UserName
    *
    * OUTPUT PARAMETERS
    *	WriteOver	Write Over Plug option
    *	InitOption	Initialize option
    *	
    *   @msg
   
    * RETURN VALUE
    *   0         success
    *   1         Failure  'if Fails THEN it fails.
    *****************************************************/
   (@jcco bCompany, @form varchar(30), @username bVPUserName, 
	@projmethod char(1)= null output, @writeover char(1) = null output, @initoption char(1) = null output, 
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode integer
   
   select @rcode = 0
   
	select @projmethod = ProjMethod, @initoption = ProjInitOption, @writeover = ProjWriteOverPlug 
	from bJCUO with (nolock)
	where JCCo= @jcco and Form = @form and UserName= @username 
	if @@rowcount <> 1 select @rcode = 1, @msg = 'Missing User Options'


   bspexit:
       if @rcode<>0 select @msg=@msg
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCUOInitGet] TO [public]
GO
