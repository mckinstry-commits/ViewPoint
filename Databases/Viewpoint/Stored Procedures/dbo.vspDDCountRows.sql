SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         PROCEDURE [dbo].[vspDDCountRows]
/**************************************************
* Created: JRK 04/14/06
* Modified: TEJ 2011/04/01 Bumped SQL statement size to 700. 128 + 512 + Additional 28 characters = 668
*                          We have a potential architectural problem with this as we are allowing larger
*					       table names queries like this. The issue that triggered this was caused by that 
*                          and was pushing up close to the 512 limit on the WHERE clause.
*
*
* Used by RemoteHelper's CountRows function.
* retrieve a row count for the specified view and where clause
*
* Inputs:
*	viewname
*	whereclause
*
* Output:
*	resultset of users' sub folders from vDDSF
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@viewname varchar(128)=null, @whereclause varchar(512)=null,@errmsg varchar(512) output)
as

set nocount on 

declare @rcode int

if @viewname is null or @whereclause is null
	begin
	select @errmsg = 'Missing required input parameters: viewname and/or whereclause!', @rcode = 1
	goto vspexit
	end

set @rcode = 0

-- Build a dynamic query string.
DECLARE @SQLString NVARCHAR(700)

/* Set column list. CHAR(13) is a carriage return, line feed.*/
SET @SQLString = N'select count(0) from ' + @viewname  + N' where ' + @whereclause + CHAR(13)

EXEC sp_executesql @SQLString
   
vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDCountRows]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDCountRows] TO [public]
GO
