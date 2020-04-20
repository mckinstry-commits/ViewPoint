SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO















CREATE                 PROCEDURE [dbo].[vspVPMenuGetFormPosition]
/**************************************************
* Created:  JK 06/11/03 - VP.NET
* Modified: JK 07/29/03
*
* Used by VPMenu to retrieve the FormPosition field for a form.
* Pass in the username and formname to identify the record to update,
* and an output argument for the FormPosition.
* FormPosition is a comma-delimited string of Int values corresponding to top, left,
* height and width.
*   - Value "10, 55, 500, 350" indicates top is 10, left 55, height 500 and width 350.
*   - Value "max" indicates maximized screen.
*
* The key of DDFU is  username + form.
*
* The output depends on the username being viewpointcs or other.
* 
* Inputs
*       @username		Needed since we use a system connection.
*	@formname 		Form Name
*
* Output
*	@formpos 		Value in the FormPosition field of DDFU.
*	@errmsg
*
****************************************************/
	(@username varchar(128) = null, @formname varchar(30) = null, 
	 @formpos varchar(30) output, @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int, @gridrowheight smallint
select @rcode = 0

-- Check for required fields
if (@username is null or @formname is null) 
	begin
	select @errmsg = 'Missing required field:  username or formname.  [vspVPMenuGetFormPosition]', @rcode = 1
	goto vspexit
	end

begin	

SELECT @formpos = FormPosition, @gridrowheight = GridRowHeight 
FROM DDFU 
WHERE VPUserName = @username AND Form = @formname

if @gridrowheight is null
	select @formpos = @formpos + ','
else
	select @formpos = @formpos + ',' + cast(@gridrowheight as varchar(3))

end
   
vspexit:
	return @rcode















GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetFormPosition] TO [public]
GO
