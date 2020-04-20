SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMImportBulkInsert]
   /************************************************************************
   * CREATED:   DANF 01/04/2007
   * MODIFIED:   DANF 02/28/2008 - Issue 127035 - Set warnings off.
   *			CC 3/12/2008 - Issue 127389 - changed alter string to nvarchar(max)
   *
   * Purpose of Stored Procedure
   *
   *   insert data from a text file.
   *    
   *           
   * Notes about Stored Procedure
   * 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@DatabaseName varchar(255), @ImportTable varchar(255), @FilePath varchar(255), @FieldDelimiter varchar(255), @RowDelimiter varchar(255), @msg varchar(255) output)
   
   as
   set nocount on
   
    declare @rcode int, @AlterString NVARCHAR(MAX), @USER VARCHAR(120)
   
    select @rcode=0

    If @DatabaseName is null
       begin
       select @msg='Missing Database Name.', @rcode=1
       goto bspexit
       end

    If @ImportTable is null
       begin
       select @msg='Missing Import Table.', @rcode=1
       goto bspexit
       end

    If @FilePath is null
       begin
       select @msg='Missing File Path.', @rcode=1
       goto bspexit
       end


	if isnull(@FieldDelimiter,'')='' and isnull(@RowDelimiter,'')=''
		begin
		Set @AlterString = 'SET ANSI_WARNINGS OFF; BULK INSERT ' + quotename(@DatabaseName) + '.dbo.' + quotename(@ImportTable) + ' From ''' + @FilePath + ''' WITH ( FIELDTERMINATOR = '''', ROWTERMINATOR = ' + char(39) + '\n' + char(39) + ' )'
   		end

	if isnull(@FieldDelimiter,'') <> '' and  isnull(@RowDelimiter,'') = ''
		begin
		Set @AlterString = 'SET ANSI_WARNINGS OFF; BULK INSERT ' + quotename(@DatabaseName) + '.dbo.' + quotename(@ImportTable) + ' From ''' + @FilePath + ''' WITH ( FIELDTERMINATOR = ''' + @FieldDelimiter + ''', ROWTERMINATOR = ' + char(39) + '\n' + char(39) + ' )'
		end

	if isnull(@FieldDelimiter,'') <> '' and  isnull(@RowDelimiter,'') <> ''
		begin
		Set @AlterString = 'SET ANSI_WARNINGS OFF; BULK INSERT ' + quotename(@DatabaseName) + '.dbo.' + quotename(@ImportTable) + ' From ''' + @FilePath + ''' WITH ( FIELDTERMINATOR = ''' + @FieldDelimiter + ''', ROWTERMINATOR = ' + @RowDelimiter + ' )'
		end

	if isnull(@FieldDelimiter,'') = '' and  isnull(@RowDelimiter,'') <> ''
		begin
		Set @AlterString = 'SET ANSI_WARNINGS OFF; BULK INSERT ' + quotename(@DatabaseName) + '.dbo.' + quotename(@ImportTable) + ' From ''' + @FilePath + ''' WITH ( FIELDTERMINATOR = '''', ROWTERMINATOR = ' + @RowDelimiter + ' )'
		end

	EXEC sp_executesql @AlterString
   
   bspexit:
        if @rcode<>0 select @msg=isnull(@msg,'') + char(13) + char(10) + '[vspIMImportBulkInsert]'
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMImportBulkInsert] TO [public]
GO
