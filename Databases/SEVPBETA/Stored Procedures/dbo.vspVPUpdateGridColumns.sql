SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO















CREATE                 PROCEDURE [dbo].[vspVPUpdateGridColumns]
/**************************************************
* Created:  JK 07/28/05
* Modified: JRK 03/08/06 to use views instead of tables.
*
* Used by VPLogViewer to update the width of grid columns.
* Pass in the username, formname, and the comma-delimited string of column widths.
* For example, "0100,0231,1121,0050" contains 4 widths, each consisting of 4 chars.
*
* We will attempt to do an UPDATE, and if @rowcount is zero we will to an insert.  
*
* The key of DDUI is  username + form.
*
* The output depends on the username being viewpointcs or other.
* 
* Inputs
*       @username		Needed since we use a system connection.
*	@formpos 		Comma-delimited string consisting of 4-char widths, as in "0100,0231,1121,0050"
*
* Output
*	@errmsg
*
****************************************************/
	(@username varchar(128) = null, @formname varchar(30) = null, 
	 @widths varchar(512) = null, @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@username is null or @formname is null or @widths is null) 
	begin
	select @errmsg = 'Missing required field:  username, formname, or widths.  [vspVPUpdateGridColumns]', @rcode = 1
	goto vspexit
	end

declare @colnbr smallint, @pos int, @seq char(4), @seqnbr smallint, @width char(4)
--select @colnbr=0
select @pos=1

-- Loop through the comma-delimited string of widths
-- The format is "0010=0111,0020=0065" for Seq 0010 and 0020 widths of 0111 and 0065 respectively.
while @pos < datalength(@widths)
begin
	select @seq=substring(@widths,@pos,4)  -- The first 4 chars are the Seq.
	select @seqnbr=cast(@seq as smallint) -- Convert Seq from alpha to smallint.
	select @width=substring(@widths,@pos + 5,4) -- The width starts just after the "=".
	-- print @width

	-- Attempt an UPDATE first.
	UPDATE DDUI SET ColWidth = cast(@width as smallint)
	WHERE VPUserName = @username AND Form = @formname AND Seq = @seqnbr
	-- Did we accomplish an update?
	if @@rowcount = 0
		-- No rows were updated so the record doesn't exist.
		-- Need to insert instead.
		--INSERT INTO DDUI (VPUserName, Form, GridCol, ColWidth)
		--VALUES (@username, @formname, @colnbr, @width)
		INSERT INTO DDUI (VPUserName, Form, Seq, GridCol, ColWidth)
		SELECT @username, @formname, @seqnbr, GridCol, @width
		FROM DDFI
		WHERE Form=@formname AND GridCol=@colnbr
	
	select @pos=@pos+10
	--select @colnbr=@colnbr+1
end

   
vspexit:
	return @rcode

















GO
GRANT EXECUTE ON  [dbo].[vspVPUpdateGridColumns] TO [public]
GO
