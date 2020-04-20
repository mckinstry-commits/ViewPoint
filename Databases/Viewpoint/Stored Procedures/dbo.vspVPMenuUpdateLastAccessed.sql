SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE              PROCEDURE [dbo].[vspVPMenuUpdateLastAccessed]
/**************************************************
* Created:  JK 06/11/03 - VP.NET
* Modified: JK 07/29/03
* Modified: JRK 03/08/06 to use DDFU and RPUP instead of vDDFU and vRPUP.
*
* Used by VPMenu to update the LastAccessed field for a form or a report.
* @itemtype tells us if we are updating a form or a report.  @menuitem will
* be either a formname or a report ID.
* We will attempt to do an UPDATE, and if @rowcount is zero we will to an insert.  
*
* The key of DDFU is username + mod + itemtype + menuitem.
*
* The output depends on the username being viewpointcs or other.
* 
* Inputs
*       @username		Needed since we use a system connection.
*	@itemtype 		'F' (form) or 'R' (report)
*	@menuitem 		form name or report id
*
* Output
*	@errmsg
*
****************************************************/
	(@username varchar(128) = null, @itemtype char(1) = null, 
	 @menuitem varchar(30) = null, @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@username is null or @itemtype is null or @menuitem is null) 
	begin
	select @errmsg = 'Missing required field:  username, itemtype, or menuitem.  [vspVPMenuUpdateLastAccessed]', @rcode = 1
	goto vspexit
	end

-- Form or Report??
if @itemtype = 'F'
	-- Form
	begin	
	-- Attempt an UPDATE first.
	UPDATE DDFU SET LastAccessed = getdate()
	WHERE VPUserName = @username AND Form = @menuitem
	-- Did we accomplish an update?
	if @@rowcount = 0
		-- No rows were updated so the record doesn't exist.
		begin
		-- Need to insert instead.
		INSERT INTO DDFU (VPUserName, Form, LastAccessed)
		VALUES (@username, @menuitem, getdate())
		end
	end

else 
	-- Report
	begin	
	-- Attempt an UPDATE first.
	UPDATE RPUP SET LastAccessed = getdate()
	WHERE VPUserName = @username AND ReportID = @menuitem
	-- Did we accomplish an update?
	if @@rowcount = 0
		-- No rows were updated so the record doesn't exist.
		begin
		-- Need to insert instead.
		INSERT INTO RPUP (VPUserName, ReportID, LastAccessed)
		VALUES (@username, @menuitem, getdate())
		end
	end

   
vspexit:
	return @rcode












GO
GRANT EXECUTE ON  [dbo].[vspVPMenuUpdateLastAccessed] TO [public]
GO
