SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************************/
   CREATE procedure [dbo].[vspPMImportUDBuild]
   /*******************************************************
    * CREATED BY:		GP 03/17/2009
    * MODIFIED BY:		
    *
    *
    * USAGE: This stored procedure will load 3 variables with user memo
    *		column names. Will be used in PM SP's and triggers to create 
    *		insert string and select string for user memos columns for the 
    *		specified table.
    *
    * INPUT:
    *	@StandardTable	Table name to update users memos for
	*	@PMWorkTable	Table name to check that column name also exists in
    *	@Alias			Table name alias for select string
    *
    * OUTPUT:
    *	@InsertClause	variable with insert clause of user memos to be added to table insert clause
    *	@Statement	variable with select clause of user memos to be added to table select clause
    *	@errmsg     if something went wrong
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
   *****************************************************/
   (@StandardTable varchar(30) = null, @PMWorkTable varchar(30) = null, @WhereClause varchar(255) = null, 
	@Statement varchar(max) = null output, @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @ColumnName varchar(30)
   
   select @rcode = 0
   
	--Validation
	if @StandardTable is null or @PMWorkTable is null or @WhereClause is null
	begin
		set @Statement = null
		goto vspexit
	end

	--Get first column name
	select @ColumnName = min(i.COLUMN_NAME) from INFORMATION_SCHEMA.COLUMNS i 
	join INFORMATION_SCHEMA.COLUMNS p on p.COLUMN_NAME = i.COLUMN_NAME
	where substring(i.COLUMN_NAME,1,2) = 'ud'
		and i.TABLE_NAME = @StandardTable and p.TABLE_NAME = @PMWorkTable

	--Pseudo cursor for ud columns
	WHILE @ColumnName is not null
	BEGIN
		--Build update statement
		if @Statement is null
		begin
			select @Statement = @ColumnName + ' = ' + '(select ' + @ColumnName + ' from ' + @PMWorkTable +
				' with (nolock) ' + @WhereClause + ')'
		end
		else
		begin
			select @Statement = @Statement + ', ' + @ColumnName + ' = ' + '(select ' + @ColumnName + 
				' from ' + @PMWorkTable + ' with (nolock) ' + @WhereClause + ')'
		end 

		--Get next column name
		select @ColumnName = min(i.COLUMN_NAME) from INFORMATION_SCHEMA.COLUMNS i 
		join INFORMATION_SCHEMA.COLUMNS p on p.COLUMN_NAME = i.COLUMN_NAME
		where substring(i.COLUMN_NAME,1,2) = 'ud'
			and i.TABLE_NAME = @StandardTable and i.COLUMN_NAME > @ColumnName and p.TABLE_NAME = @PMWorkTable

		--If no columns, exit loop
		if @@rowcount = 0 select @ColumnName = null
	END
   
	vspexit:
 		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportUDBuild] TO [public]
GO
