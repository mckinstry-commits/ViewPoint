SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[vspDDFindCodeStr]
/**************************************************
* Created: GG 07/14/03
* Modified: 
*
* Utility procedure used to find all occurences of a string
* within sql objects of the current database
*
* Inputs:
*	@ss			string to search for
*
* Output:
*	resultset of sql objects containing search string
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@ss varchar(1000) = null, @errmsg varchar(512) output)


AS

set nocount on

DECLARE @rcode int, @sql nvarchar(4000)

if @ss is null 
	begin
	select @errmsg = 'Input parameter is missing: Search String', @rcode = 1
	goto vspexit
	end

set @rcode = 0

select @sql = 'select distinct o.name 
FROM sysobjects o
JOIN syscomments c
ON o.id = c.id
WHERE text like ''%' + @ss + '%''
/* Elminate system objects & VSS objects */
AND name not like ''sys%''
AND name not like ''dt/_%'' ESCAPE ''/''
AND name not like ''fn/_%'' ESCAPE ''/'''


EXEC (@sql)


vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDFindCodeStr]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFindCodeStr] TO [public]
GO
