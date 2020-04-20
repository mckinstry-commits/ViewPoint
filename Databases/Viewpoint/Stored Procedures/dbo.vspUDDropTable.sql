SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[vspUDDropTable] 
   /************************************************
   	Created: RM 03/12/01
   	
   	Modified: DANF 03/10/04 - Issue 20536 Remove Security entries from DDSL.
			  TIMP 08/09/07 - Changed to vspUDDropTable
			  RM 09/08/08 - execute as viewpoint for drop permissions
			  AL 09/14/09 - removing DDSLc records wehn tables are dropped
   	
   	Usage:  Drops user table when deleted from form.
   	
   ************************************************/
   (@tablename varchar(20),@errmsg varchar(255) output)
   with execute as 'viewpointcs'	-- required for dropping table
   AS
   
   declare @rcode int,@dropstring varchar(50),@btablename varchar(20), @columnname varchar(30),@datatype varchar(20)
   
   select @rcode = 0
   
   if @tablename is null 
   begin
   	select @rcode = 1,@errmsg = 'Invalid Tablename.'
   	goto bspexit
   end
   
   
   if not exists(select top 1 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'b' + @tablename)
   goto bspexit
   
   --
     select @btablename = 'b' + @tablename
   
       -- Add Security Entries if Needed
      declare createddslcursor  cursor local fast_forward for
      select ColumnName,DataType from bUDTC
      where TableName = @tablename
      order by DDFISeq
     
     
      --Get columns and info for create string
      open createddslcursor
     
      fetch next from createddslcursor into
      @columnname,@datatype
     
      while @@fetch_status = 0
      begin
     
     
       exec @rcode = dbo.vspDDSLUserColumn @btablename, @datatype, @columnname, null, 'Deletion', @errmsg output
         if @rcode <> 0
         begin
         select @errmsg='Error Deleting User Data Column ' + @columnname + ' from the Security Links Table. ', @rcode = 1
         end
   
        	--print @createstring
      	fetch next from createddslcursor into
      	@columnname,@datatype
      end
     
      close createddslcursor
      deallocate createddslcursor
   
   --
   --Drop table
   begin tran
   select @dropstring = 'drop table b' + @tablename
   exec(@dropstring)
   
   delete from DDSLc where TableName = @tablename
   
   select @dropstring = 'drop view ' + @tablename
   exec(@dropstring)
   
   -- Remove version info
   delete from UDVersion where TableName = @tablename
   
   commit tran
   
   bspexit:
   return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspUDDropTable] TO [public]
GO
