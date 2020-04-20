SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
   CREATE  procedure [dbo].[bspPMProjectCopyUserMemos]
   /***********************************************************
    * CREATED BY: GF	12/06/2001
    * MODIFIED By :
    *
    *
    * USAGE: Executed from bspPMProjectCopy to update user memo fields
    *		for various JC and PM tables.
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
   
   declare @rcode int, @updatestring varchar(4000), @columnname varchar(30)
   
   select @rcode = 0
   
   -- pseudo cursor for ud columns in source to be updated
   select @columnname = min(name) from syscolumns where name like 'ud%'
   and id = object_id('dbo.' + @tablename)
   while @columnname is not null
   BEGIN
   
   	select @updatestring = null
   	select @updatestring = 'update ' + @tablename + ' set ' + @columnname + ' = z.' + @columnname + @joins + @whereclause
   
   	exec (@updatestring)

   	if @@Error <> 0
   		begin
   		select @rcode = 1
   		goto bspexit
   		end
   
   select @columnname = min(name) from syscolumns where name like 'ud%' 
    and id = object_id('dbo.' + @tablename) and name > @columnname
   if @@rowcount = 0 select @columnname = null
   END
   
   
   
   bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjectCopyUserMemos] TO [public]
GO
