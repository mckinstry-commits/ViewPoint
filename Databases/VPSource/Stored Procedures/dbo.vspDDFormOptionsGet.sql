SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vspDDFormOptionsGet]
/********************************
* Created: RM 07/17/07 
* Modified: 
*
* Used to Get the DDFU.Options column for the form.
*
* Input:
*	@form	Form name
*
* Output:
*	@options	DDFU.Options
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
  (@form varchar(30) = null, @username bVPUserName = null,  @options varchar(256) output, @errmsg varchar(512) output)

as
set nocount on

declare @rcode int
select @rcode = 0


if @form is null
	begin
		select @errmsg = 'Form parameter missing.', @rcode = 1
		goto bspexit
	end

if @username is null
	begin
		select @errmsg = 'Username parameter missing.', @rcode = 1
		goto bspexit
	end


	select @options = Options from DDFU where Form=@form


bspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDFormOptionsGet]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFormOptionsGet] TO [public]
GO
