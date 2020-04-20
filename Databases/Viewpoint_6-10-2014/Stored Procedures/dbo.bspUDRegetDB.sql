SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[bspUDRegetDB] 
   /**************************************************
   	Created RM 03/08/01
   
   	Usage
   		Used to reget the info from the UDTA Table and put it into the UDTC
   
   	
   **************************************************/
   (@tablename bDesc = null ,@errmsg varchar(255) output)
   AS
   
   declare @rcode int,@seq int
   select @rcode = 0
   
   
   if @tablename is null 
   begin
   	select @rcode = 1, @errmsg = 'Table Name Missing!'
   	goto bspexit
   end
   
   if not exists(select * from bUDCA where TableName = @tablename)
   begin
   	select @rcode = 1,@errmsg = 'Table has not been created.'
   	goto bspexit
   end
   
   delete bUDTC
   where TableName = @tablename
   
   select @seq = min(DDFISeq) from bUDCA where TableName = @tablename
   
   
   UDTC_INSERT:
   insert bUDTC (TableName, ColumnName, Description, KeySeq, DataType, InputType, InputMask, InputLength, Prec, FormSeq, ControlType, OptionButtons, StatusText, Tab, Notes, DDFISeq)
   select * from bUDCA
   where TableName = @tablename and DDFISeq = @seq
   
   select @seq = min(DDFISeq) from bUDCA where TableName = @tablename  and DDFISeq > @seq
   
   
   if @seq is not null
   begin
   goto UDTC_INSERT
   end
   
   
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspUDRegetDB] TO [public]
GO
