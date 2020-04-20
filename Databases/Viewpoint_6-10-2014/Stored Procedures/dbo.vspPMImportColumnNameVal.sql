SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[vspPMImportColumnNameVal]

  /*************************************
  * CREATED BY:		GP 03/03/2009
  * Modified By:	GP 1/5/2009 - Issue 137249 increased @ColumnName size from 20 to 500
  *
  *		Validates ColumnName to make sure multiple columns 
  *		don't exist with the same name.
  *
  *		Input Parameters:
  *			Template
  *			RecordType
  *			ColumnName
  *  
  *		Output Parameters:
  *			rcode - 0 Success
  *					1 Failure
  *			msg - Return Message
  *		
  **************************************/
	(@Template varchar(10) = null, @RecordType varchar(20) = null, @ColumnName varchar(500) = null,
	@Desc varchar(60) = null output, @Datatype varchar(20) = null output, @msg varchar(256) output)
	as
	set nocount on

	declare @rcode int, @Table varchar(20), @DDFIcForm varchar(30), @SQLString nvarchar(400)
	set @rcode = 0

	--Get Form name
	select @Table = case @RecordType 
		when 'Item' then 'JCCI' 
		when 'Phase' then 'JCJP' 
		when 'CostType' then 'JCCH' 
		when 'SubDetail' then 'PMSL'
		when 'MatlDetail' then 'PMMF'
		when 'Estimate' then 'JCJM'
		end

	--Get DDFIc Form name
	select @DDFIcForm = case @RecordType
		when 'Item' then 'JCCI'
		when 'Phase' then 'JCJP'
		when 'CostType' then 'JCJPCostTypes'
		when 'SubDetail' then 'PMSubcontractNonIntfc'
		when 'MatlDetail' then 'PMMaterialNonIntfc'
		when 'Estimate' then 'PMProjects'
		end

	--No duplicate Column Names
	if exists(select top 1 1 from PMUD with (nolock) where Template=@Template and RecordType=@RecordType and ColumnName=@ColumnName)
	begin
		select @msg = 'Column Name already exists, please enter another ', @rcode = 1
		goto vspexit
	end

	if substring(@ColumnName, 1, 2) = 'ud'
	begin
		--Make sure Column Name exists in source table
		if not exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME=@Table and COLUMN_NAME=@ColumnName)
		begin	
			select @msg = 'UD field does not exist in ' + @Table + '.', @rcode = 1
			goto vspexit
		end

		--Make sure there is a DDFI entry for UD columns
		if not exists(select top 1 1 from DDFIc with (nolock) where Form=@DDFIcForm and ColumnName=@ColumnName)
			and (substring(@ColumnName,1,2) = 'ud')
		begin
			select @msg = 'No DDFI entry exists for UD Column Name ', @rcode = 1
			goto vspexit
		end
		else
		begin
			select @Desc = Description, @Datatype = Datatype from vDDFIc where Form=@DDFIcForm and ColumnName=@ColumnName
		end
	end
	
	vspexit:
   		return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMImportColumnNameVal] TO [public]
GO
