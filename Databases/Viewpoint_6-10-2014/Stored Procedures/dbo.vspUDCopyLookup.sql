SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     PROCEDURE [dbo].[vspUDCopyLookup]
    /***************************************************
    	Created 07/11/07  TEP - Copied from bspUDCopyLookup to vspUDCopyLookup
    
    	Copies standard lookup to a user defined lookup
    
    ***************************************************/
    (@stdlookup varchar(30),@userlookup varchar(30),@userdescription bDesc,@errmsg varchar(255) output)
    AS
    
    declare @rcode int
    
    select @rcode = 0
    
    if @stdlookup is null
    begin
    	select @rcode = 1, @errmsg = 'Invalid Std. Lookup.'
    	goto vspexit
    end
    
    if not exists(select top 1 1  from dbo.DDLHShared (nolock) where Lookup = @stdlookup)
    begin
    	select @rcode = 1,@errmsg = 'Source Lookup Does Not Exist!.'
    	goto vspexit
    end
    
    if exists(select top 1 1 from dbo.vDDLHc (nolock) where Lookup = @userlookup)
    begin
    	select @rcode = 1, @errmsg = 'Lookup already exists.  Please choose another lookup name.'
    	goto vspexit
    end
   
    insert vDDLHc (Lookup, Title, FromClause, WhereClause, JoinClause, OrderByColumn, 
					Memo, GroupByClause, Version) 
		select @userlookup, @userdescription, FromClause, WhereClause, JoinClause, OrderByColumn, 
				Memo, GroupByClause, Version from dbo.DDLHShared WHERE Lookup = @stdlookup
    
    
    insert vDDLDc (Lookup, Seq, ColumnName, ColumnHeading, Hidden, Datatype, 
					InputType, InputLength, InputMask, Prec) 
		select @userlookup, Seq, ColumnName, ColumnHeading, Hidden, Datatype, 
					InputType, InputLength, InputMask, Prec from dbo.DDLDShared WHERE Lookup = @stdlookup
    
    vspexit:
    return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspUDCopyLookup] TO [public]
GO
