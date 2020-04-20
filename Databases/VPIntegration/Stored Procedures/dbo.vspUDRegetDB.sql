SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vspUDRegetDB] 
   /**************************************************
   	Created RM 03/08/01
   
   	Usage
   		Used to reget the info from the UDTA Table and put it into the UDTC
   
   **************************************************/
   (@tablename bDesc = null ,@errmsg varchar(255) output)
   AS
   
   declare @rcode int
   select @rcode = 0
   
   if @tablename is null 
   begin
   	select @rcode = 1, @errmsg = 'Table Name Missing!'
   	goto bspexit
   end
  
   if not exists(select * from vDDFIc where ViewName = @tablename)
   begin
   	select @rcode = 1,@errmsg = 'Table has not been created.'
   	goto bspexit
   end
  
   UDTC_UPDATE:
		update UDTC
		set DDFISeq = i.Seq,
			TableName = i.ViewName,
			Description = i.Description,
			DataType = i.Datatype,
			InputType = i.InputType,
			InputMask = i.InputMask,
			InputLength = i.InputLength,
			Prec = i.Prec,
			ControlType = i.ControlType
		from vDDFIc i 
		join UDTC d on d.TableName = i.ViewName and d.ColumnName = i.ColumnName
		WHERE i.ViewName = @tablename
   UDTC_INSERT:
		insert into  bUDTC(TableName, ColumnName, Description, DataType, InputType, InputMask
		, InputLength, Prec, ControlType, StatusText, Tab, DDFISeq, AutoSeqType)

		SELECT i.ViewName, i.ColumnName, i.Description, i.Datatype, i.InputType, i.InputMask
		, i.InputLength, i.Prec, i.ControlType, i.StatusText, i.Tab, i.Seq, i.AutoSeqType
		from  vDDFIc i 
		LEFT JOIN bUDTC c ON i.ViewName = c.TableName AND c.ColumnName = i.ColumnName
		WHERE  i.ViewName = @tablename AND c.ColumnName IS NULL AND i.Seq <> 99

   UDTC_DELETE:
		delete  UDTC
		from  UDTC d 
		WHERE d.TableName = @tablename
		and not d.ColumnName in (select ColumnName from vDDFIc where ViewName = @tablename)
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspUDRegetDB] TO [public]
GO
