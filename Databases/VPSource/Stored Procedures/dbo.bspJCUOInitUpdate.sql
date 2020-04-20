SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************/
CREATE   proc [dbo].[bspJCUOInitUpdate]
/***********************************************************
* CREATED BY	: GF 03/02/2004
* MODIFIED BY	: TV - 23061 added isnulls
*					GF 03/27/2008 - issue #126993 added 2 columns to bJCUO
*
* USAGE:
*  Updates the projection initialize options in bJCUO
*
*
* INPUT PARAMETERS
*	JCCo		JC Company
*	Form		JC Form Name
*	UserName	VP UserName
*	WriteOver	Write Over Plug option
*	InitOption	Initialize option
*
* OUTPUT PARAMETERS
*   @msg

* RETURN VALUE
*   0         success
*   1         Failure  'if Fails THEN it fails.
*****************************************************/
(@jcco bCompany, @form varchar(30), @username bVPUserName, @writeover char(1), @initoption char(1), 
@msg varchar(255) output)
as
set nocount on

declare @rcode integer

select @rcode = 0

-- insert projection user options record
update dbo.bJCUO set ProjWriteOverPlug = @writeover, ProjInitOption = @initoption
where JCCo=@jcco and Form=@form and UserName=@username

bspexit:
	if @rcode<>0 select @msg=@msg
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCUOInitUpdate] TO [public]
GO
