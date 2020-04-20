SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE            PROCEDURE [dbo].[vspVPMenuInsertLinks]
/**************************************************
* Created: JRK 07/11/2005
*
* Used by regular users to insert new links in table vDDWL.
*
*
* Inputs:
*	@name			Link's name
*	@address		Link's URL address
*       @seq			Display sequence (0, 1, 2, etc.)
* Output:
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@name varchar(60) = null, @address varchar(256), @seq smallint = null,
	 @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int, @user bVPUserName, @rowsaffected int

select @rcode = 0, @user = suser_sname() -- Get the user id from the connection.


if @name is null or @address is null or @seq is null
	begin
	select @errmsg = 'Missing required input parameters: Name, Address and/or Sequence.', @rcode = 1
	goto vspexit
	end

INSERT INTO vDDWL 
([VPUserName], [Name], [Address], [Seq])
 VALUES (@user, @name, @address, @seq)

SELECT @rowsaffected = @@rowcount

-- We should get 1 and only 1 row.
if @rowsaffected <> 1
	begin
	select @errmsg = 'Error inserting a record into the Links table.', @rcode = 1
	goto vspexit
	end


vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) 
	 + '[vspVPMenuInsertLinks]'
	return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspVPMenuInsertLinks] TO [public]
GO
