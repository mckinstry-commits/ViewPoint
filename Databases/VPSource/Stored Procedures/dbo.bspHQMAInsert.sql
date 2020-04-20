SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMAInsert    Script Date: 8/28/99 9:34:52 AM ******/
   CREATE  proc [dbo].[bspHQMAInsert]
    /* Adds entries to HQ Master Audit table
     * pass in all columns
     * returns msg if error
    */
    	(@tablename char(20), @key varchar(60), @co bCompany, @rectype char(1),
    	 @field char(30), @old varchar(30), @new varchar(30), @date bDate,
    	 @user bVPUserName, @errmsg varchar(60) output)
    as
    	set nocount on
    	declare @rcode int
    	select @rcode=0
    /* add HQ Master Audit entry */
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    values (@tablename,@key,@co,@rectype,@field,@old,@new,@date,@user)
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Unable to add HQ Master Audit entry!', @rcode = 1
    	end
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQMAInsert] TO [public]
GO
