SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspUDUserLookupsDetailInfo    Script Date: 07/03/2007 13:03:28 ******/    
   CREATE proc [dbo].[vspUDUserLookupsDetailInfo]    
   /***********************************************************    
    * CREATED BY: TEP 03/05/2004    
    * MODIFIED By : RM 01/03/08 - Check column name against SQL Reserved Word List    
    * CC 08/06/08 - Issue #126766 Check both the UD columns, and the DDFI columns for user lookups    
    * AL 05/27/09 - Issue #133705 Removed any 'nolocks' from the @tablename string  
    * Dave C 06/30/09 - Issue #134195 Changed proc to not throw an error if table/column could not be found in metadata tables  
    *          as well as added a check to ensure that the table and column actually exist (in sys.columns),  
    *          and parsed the table name correctly (in the case of the table name being appended with [nolock]).  
    * Dave C 07/09/09 - Issue #134195 Rejection: Added logic to not try to parse @tablename if it DOESN'T contain spaces (i.e. <with (nolock)>)
    * USAGE:    
    * Return Table/Column information from UDTC and DDFI    
    *    
    * INPUT PARAMETERS    
    *   TableName, ColumnName    
    *       
    * OUTPUT PARAMETERS    
    *   @description     
    *   @datatype     
    *   @inputtype     
    *   @inputmask     
    *   @inputlength     
    *   @prec     
    *   @errmsg        error message if something went wrong    
    * RETURN VALUE    
    *   0 Success    
    *   1 fail    
    ************************************************************************/    
       (@tablename varchar(20), @columnname varchar(30), @description bDesc output,    
        @datatype varchar(20) output, @inputtype tinyint output, @inputmask varchar(20) output,    
  @inputlength int output, @prec tinyint output, @errmsg varchar(500) output)  
  as    
  set nocount on    
  begin    
   declare @rcode int    
   select @rcode = 0    
  if @tablename is null    
   begin    
   select @errmsg = 'Missing Table Name', @rcode = 1    
   goto vspexit    
   end    
    
  if @columnname is null    
   begin    
   select @errmsg = 'Missing Column Name', @rcode = 1    
   goto vspexit    
   end  
     
   --Clean up tablename, if it needs it-- otherwise, fall through.
   SELECT @tablename = LTRIM(RTRIM(@tablename))  
     
   DECLARE @firstspace int  
   SELECT @firstspace = CHARINDEX(' ', @tablename, 0)
   If @firstspace <> 0
	Begin
		SELECT @tablename = SUBSTRING(@tablename, 0, @firstspace)
	End
  
        --added in case columnname is passed in Table.Column syntax
      DECLARE @period int
      select @period = charindex('.',@columnname,0)
      if @period <> 0
      begin
            select @tablename = substring(@columnname,0,@period)
            select @columnname = substring(@columnname,@period+1,len(@columnname)-@period)
       end
          
     
  exec @rcode = vspSQLReservedWordCheck @columnname, @errmsg output    
  if @rcode = 1    
 goto vspexit    
      
if not exists(  
 select * from sys.columns where OBJECT_NAME(object_id) = @tablename  
 AND name = @columnname  
 )  
 begin  
  select @errmsg = 'Table or Column does not exist.', @rcode = 1  
  goto vspexit  
 end  
    
  SELECT @description = [Description]    
  ,@datatype = DataType     
  ,@inputtype = InputType     
  ,@inputmask = InputMask     
  ,@inputlength = InputLength     
  ,@prec = Prec     
 FROM     
  (    
    SELECT [Description]    
     ,DataType     
     ,InputType     
     ,InputMask     
     ,InputLength     
     ,Prec     
     ,TableName    
    FROM dbo.UDTC    
    WHERE TableName = @tablename     
       AND ColumnName = @columnname     
    
    UNION    
    
    SELECT [Description]    
     ,Datatype AS [DataType]    
     ,InputType     
     ,InputMask     
     ,InputLength     
     ,Prec      
     ,ViewName AS TableName    
    FROM DDFIShared    
    WHERE      
      ViewName = @tablename AND ColumnName = @columnname     
  ) AS DDColumns    
     
  vspexit:    
   return @rcode                                                       
  end 
GO
GRANT EXECUTE ON  [dbo].[vspUDUserLookupsDetailInfo] TO [public]
GO
