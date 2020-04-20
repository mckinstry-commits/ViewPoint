SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE procedure [dbo].[vspEMCopyUserMemos]
/***********************************************************
* CREATED BY:	TRL	11/12/2008
* MODIFIED By:	GF	01/05/2008 - issue #131660 changes for performance
*
*
* USAGE: Executed from vspEMAutoUseTempCopy to update user memo fields
*		for EM Tables.
*
* INPUT:
*	@tablename		Table name to update users memos for
*	@joins			Join clause for update statement
*	@whereclause	Where clause for update statement
*
* OUTPUT:
*   @errmsg     if something went wrong
   
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@tablename varchar(30), @joins varchar(1000), @whereclause varchar(1000), @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @updatestring varchar(max), @column_names varchar(max)

select @rcode = 0

----select * from ud_columns
if exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @tablename
			and COLUMN_NAME like 'ud%')
	begin
	select @updatestring = 'update ' + @tablename + ' set '
	select @column_names = isnull(@column_names,'') + convert(varchar(60), COLUMN_NAME) + ' = orig.' + convert(varchar(60), COLUMN_NAME) + ', '
	from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @tablename and COLUMN_NAME like 'ud%'

	---- drop trailing comma from @column_names
	select @column_names = substring(@column_names,1,datalength(@column_names)-2)

	---- add column names to update string
	select @updatestring = @updatestring + @column_names
	
	---- add joins and where clause
	select @updatestring = @updatestring + @joins + @whereclause

	---- execute update
	exec (@updatestring)
	end


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCopyUserMemos] TO [public]
GO
