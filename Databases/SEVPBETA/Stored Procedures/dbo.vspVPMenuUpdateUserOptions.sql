SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE           PROCEDURE [dbo].[vspVPMenuUpdateUserOptions]
/**************************************************
* Created: JRK 04/17/06
* Modified: JonathanP 04/21/09 - 133308: Now handles user names with single quotes in them.
*
* Called by RemoteHelper's UpdateUserOptions.
* Update DDUP with the keword=value paris passed in.
*
*
* Inputs:
*	@userid - The user to update.
*   @keywordsvalues - A comma-separated list of [field name = value].
*
* Output:
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@userid bVPUserName, @keywordsvalues varchar(1024)=null,
     @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int, @rowsaffected int

if @userid is null or @keywordsvalues is null 
	begin
	select @errmsg = 'Missing required input parameters: UserID or Keyword Value Pairs!', @rcode = 1
	goto vspexit
	end

select @rcode = 0 

-- Build a dynamic query string.
DECLARE @SQLString NVARCHAR(1100)

-- Make sure a single quote is changed to 2 single quotes since we are executing dynamic sql
select @userid = replace(@userid, '''', '''''')

/* Set column list. CHAR(13) is a carriage return, line feed.*/
SET @SQLString = N'Update DDUP Set ' + @keywordsvalues  + N' where VPUserName=''' + @userid + + N'''' +CHAR(13)
--print @SQLString

EXEC sp_executesql @SQLString

SELECT @rowsaffected = @@rowcount

-- We should get 1 and only 1 row.
if @rowsaffected <> 1
	begin
	select @errmsg = 'The row of DDUP was not updated.', @rcode = 1
	goto vspexit
	end

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) 
	 + '[vspVPMenuUpdateUserOptions]'
	return @rcode

















GO
GRANT EXECUTE ON  [dbo].[vspVPMenuUpdateUserOptions] TO [public]
GO
