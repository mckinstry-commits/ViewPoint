SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspEMCOPurgeCompanyGet]
/********************************************************
* CREATED BY: DANF 04/02/2007
* MODIFIED BY:	
*
* USAGE:
* 	Retrieves the GLCompany and Last Month Closed from GL.
	from EMCO
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
* from EMCO (EM Company file):
*	GLCO 
*	Last Month Closed
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@emco bCompany, @glco bCompany output, @LastMthClosed bDate output ,@errmsg varchar(255) output)
as 
set nocount on


declare @rcode int
select @rcode = 0

  if @emco is null
  	begin
	  	select @errmsg = 'Missing EM Company', @rcode = 1
  		goto bspexit
  	end
  else
	begin
		select top 1 1 
		from dbo.EMCO with (nolock)
		where EMCo = @emco
		if @@rowcount = 0
			begin
				select @errmsg = 'Company# ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
				goto bspexit
			end
	end

	select 	@glco = e.GLCo, @LastMthClosed = LastMthSubClsd
	from dbo.EMCO e with (nolock)
	left join dbo.GLCO g with (nolock)
	on e.GLCo = g.GLCo
	where EMCo = @emco 

bspexit:
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCOPurgeCompanyGet] TO [public]
GO
