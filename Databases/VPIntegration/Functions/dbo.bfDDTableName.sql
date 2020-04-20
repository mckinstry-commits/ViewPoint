SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     function [dbo].[bfDDTableName]
  (@FromClause varchar(255))
      returns varchar(255)
   /***********************************************************
    * CREATED BY	: DANF 04/18/2004
    * MODIFIED BY	
    *
    * USAGE:
    * Used to return the the TableName for the ColumnName Lookup.
    *
    * INPUT PARAMETERS
    * 	Fromclause from DDLH.
    *
    * OUTPUT PARAMETERS
    *  @TableName      return table name
    *
    *****************************************************/
      as
      begin
  
 	declare @TableName varchar(255), @FLen int, @rcode int, @errmsg varchar(255)
 
 
 	if substring(@FromClause,1,4)='dbo.'
 		select @FromClause=substring(@FromClause,5,len(@FromClause))
 
    	select @FLen = PATINDEX ( '% %' , @FromClause)
 	if isnull(@FLen,0)=0
 		select @TableName =@FromClause
 	else
     	select @TableName =substring(@FromClause,1, @FLen)
 
  	exitfunction:
  			
  	return @TableName
      end

GO
GRANT EXECUTE ON  [dbo].[bfDDTableName] TO [public]
GO
