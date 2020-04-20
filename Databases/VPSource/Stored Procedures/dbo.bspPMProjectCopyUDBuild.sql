SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************************/
   CREATE procedure [dbo].[bspPMProjectCopyUDBuild]
   /*******************************************************
    * CREATED BY: GF	12/06/2001
    * MODIFIED By :
    *
    *
    * USAGE: This stored procedure will load two variables with user memo
    *		column names. Will be used in PM SP's and triggers to create 
    *		insert string and select string for user memos columns for the 
    *		specified table.
    *
    * INPUT:
    *	@tablename		Table name to update users memos for
    *	@alias			Table name alias for select string
    *	@joins			Join clause for update statement
    *	@whereclause	Where clause for update statement
    *
    * OUTPUT:
    *	@insertclause	variable with insert clause of user memos to be added to table insert clause
    *	@selectclause	variable with select clause of user memos to be added to table select clause
    *  @errmsg     if something went wrong
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
   *****************************************************/
   (@tablename varchar(30), @alias varchar(6) = null, @insertclause varchar(1000) = null output, 
    @selectclause varchar(1000) = null output, @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @columnname varchar(30)
   
   select @rcode = 0
   
   -- pseudo cursor for ud columns in source to be updated
   select @columnname = min(name) from syscolumns where name like 'ud%'
   and id = object_id('dbo.' + @tablename)
   while @columnname is not null
   BEGIN
   
   	if isnull(@insertclause,'') = ''
   		select @insertclause = ', ' + @columnname
   	else
   		select @insertclause = @insertclause + ', ' + @columnname
   
   	if isnull(@selectclause,'') = ''
   		begin
   		if isnull(@alias,'') = ''
   			select @selectclause = ', ' + @columnname
   		else
   			select @selectclause = ', ' + @alias + '.' + @columnname
   		end
   	else
   		begin
   		if isnull(@alias,'') = ''
   			select @selectclause = @selectclause + ', ' + @columnname
   		else
   			select @selectclause = @selectclause + ', ' + @alias + '.' + @columnname
   		end
   
   select @columnname = min(name) from syscolumns where name like 'ud%' 
   and id = object_id('dbo.' + @tablename) and name > @columnname
   if @@rowcount = 0 select @columnname = null
   END
   
   bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjectCopyUDBuild] TO [public]
GO
