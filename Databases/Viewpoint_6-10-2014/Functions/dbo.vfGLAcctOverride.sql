SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  function [dbo].[vfGLAcctOverride]
(@co int = null, @linetype int = null)
returns bYN
/***********************************************************
* CREATED BY	: MV 07/19/07
* MODIFIED BY	
*
* USAGE:
* 	Retrieves the GLAcctOverride from EMCO,INCO,JCCO based on linetype.
*
* INPUT PARAMETERS:
*	co  
*	linetype
*
* OUTPUT PARAMETERS:
*	Y or N
*
*****************************************************/
as
begin

declare @glacctoverride bYN
if @co is null or @linetype is null
	begin
	select @glacctoverride = 'N'
	goto exitfunction
	end

if @linetype = 1 or @linetype = 7
	begin
	select @glacctoverride = GLCostOveride from JCCO where JCCo=@co
	end

if @linetype = 2 
	begin
	select @glacctoverride = OverrideGL from INCO where INCo=@co
	end

 if @linetype = 4 
	begin
	select @glacctoverride = GLOverride from EMCO where EMCo=@co
	end

exitfunction:
return @glacctoverride
end

GO
GRANT EXECUTE ON  [dbo].[vfGLAcctOverride] TO [public]
GO
