SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO















CREATE                 PROCEDURE [dbo].[vspVPMenuUpdateFormPosition]
/**************************************************
* Created:  JK 06/11/03 - VP.NET
* Modified: JK 07/29/03
*
* Used by VPMenu to update the FormPosition field for a form.
* Pass in the username and formname to identify the record to update,
* and pass in a new value for FormPosition.
* FormPosition is a comma-delimited string of Int values corresponding to top, left,
* height and width.
*   - Value "10, 55, 500, 350" indicates top is 10, left 55, width height 500 and width 350.
*   - Value "max" indicates maximized screen.
*
* We will attempt to do an UPDATE, and if @rowcount is zero we will to an insert.  
*
* The key of DDFU is  username + form.
*
* The output depends on the username being viewpointcs or other.
* 
* Inputs
*       @username		Needed since we use a system connection.
*	@formname 		DDFH form name.
*	@formpos 		Comma-delimited string containing top, left, height, width
*	@gridrowheight		optional.
*
* Output
*	@errmsg
*
****************************************************/
	(@username varchar(128) = null, @formname varchar(30) = null, 
	 @formpos varchar(20) = null, @gridrowheight smallint = null,
	 @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@username is null or @formname is null or @formpos is null) 
	begin
	select @errmsg = 'Missing required field:  username, formname, or formpos.  [vspVPMenuUpdateFormPosition]', @rcode = 1
	goto vspexit
	end

begin	
-- Attempt an UPDATE first.
UPDATE DDFU SET FormPosition = @formpos, GridRowHeight = @gridrowheight
WHERE VPUserName = @username AND Form = @formname
-- Did we accomplish an update?
if @@rowcount = 0
	-- No rows were updated so the record doesn't exist.
	begin
	-- Need to insert instead.
	INSERT INTO DDFU (VPUserName, Form, FormPosition, GridRowHeight)
	VALUES (@username, @formname, @formpos, @gridrowheight)
	end
end


   
vspexit:
	return @rcode















GO
GRANT EXECUTE ON  [dbo].[vspVPMenuUpdateFormPosition] TO [public]
GO
