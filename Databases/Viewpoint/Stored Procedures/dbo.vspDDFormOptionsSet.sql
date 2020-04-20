SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vspDDFormOptionsSet]
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
  (@form varchar(30) = null, @username bVPUserName = null,  @options varchar(256)=null, @errmsg varchar(512) output)

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


	if exists (select top 1 1 from DDFU where Form=@form and VPUserName=@username)
		begin
			update DDFU set Options=@options where Form=@form and VPUserName=@username
		end
	else
		begin
			insert DDFU(VPUserName, Form, Options) Values(@username, @form, @options)
		end


bspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDFormOptionsSet]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFormOptionsSet] TO [public]
GO
