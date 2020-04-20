SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[bfIMTemplateDefaults]
  (@ImportTemplate varchar(10),@Form varchar(30), @ColumnName varchar(50), @RecType varchar(30), @Default bYN)
      returns int
   /***********************************************************
    * CREATED BY	: DANF 02/18/02
    * MODIFIED BY	: DANF 05/13/02 Added Record Type
    *				  RBT  07/23/03 Issue #21935 - Added "with (nolock)" to select statements.
    *
    * USAGE:
    * Used in Template default stored procedure to return the Column Identifier of a template
    * A 0 will return for the columnid if the column is not to be defaulted.
    *
    * INPUT PARAMETERS
    *  @ImportTemplate     Import Template
    *  @Form               Import Form
    *  @ColumnName         Column Name
    *
    * OUTPUT PARAMETERS
    *  @templateid         template Id
    *
    * RETURN VALUE
    *   0                  templateid
    *   1                  failure
    *****************************************************/
      as
      begin
  
  
  	declare @templateid int
   
  if isnull(@RecType,'')<>''
    begin
      if @Default = 'Y'
       begin
        select @templateid = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form and IMTD.RecordType = @RecType
        Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = @ColumnName
        if @@rowcount <> 1 select @templateid=0
       end
      else
       begin
        select @templateid = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form and IMTD.RecordType = @RecType
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = @ColumnName
        if @@rowcount <> 1 select @templateid=0
       end
    end
   else
    begin
      if @Default = 'Y'
       begin
        select @templateid = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = @ColumnName
        if @@rowcount <> 1 select @templateid=0
       end
      else
       begin
        select @templateid = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = @ColumnName
        if @@rowcount <> 1 select @templateid=0
       end
    end
  
  			
  	return @templateid
      end

GO
GRANT EXECUTE ON  [dbo].[bfIMTemplateDefaults] TO [public]
GO
