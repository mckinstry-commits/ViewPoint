SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspPMImportDefaultValues]

  /*************************************
  * CREATED BY:		GP 02/26/2009
  * MODIFIED BY:
  *
  *		Gets Viewpoint Default values or User Defaults
  *		for PM Imports.
  *
  *		Input Parameters:
  *			PMCo
  *			Template
  *			ImportID
  *    
  *		Output Parameters:
  *			rcode - 0 Success
  *					1 Failure
  *			msg - Return Message
  *		
  **************************************/
	(@Template varchar(10) = null, @RecordType varchar(20) = null, @ColumnName varchar(20) = null, 
	@ValueIn varchar(max) = null, @ValueOut varchar(max) output, 
	@msg varchar(500) output)

	as
	set nocount on


declare @rcode smallint, @ViewpointDefault bYN, @Override bYN, @ViewpointDefaultValue varchar(255), 
	@UserDefaultValue varchar(255)
	
select @rcode = 0, @ViewpointDefault = '', @Override = '', @ViewpointDefaultValue = '', @UserDefaultValue = ''

begin try

	--Get ViewpointDefault and Override flags
	select @ViewpointDefault=ViewpointDefault, @Override=OverrideYN, @ViewpointDefaultValue=ViewpointDefaultValue,
		@UserDefaultValue=UserDefault 
	from PMUD with (nolock) 
	where Template=@Template and RecordType=@RecordType and ColumnName=@ColumnName

	--Both ViewpointDefault & Override Checked
	if @ViewpointDefault = 'Y' and @Override = 'Y'
	begin
		set @ValueOut = @ViewpointDefaultValue
	end

	--Only ViewpointDefault Checked
	if @ViewpointDefault = 'Y' and @Override = 'N'
	begin
		if @ValueIn = '' set @ValueIn = null
		set @ValueOut = coalesce(@ValueIn, @ViewpointDefaultValue, @UserDefaultValue)
	end

	--Only Override Checked
	if @ViewpointDefault = 'N' and @Override = 'Y'
	begin
		set @ValueOut = @UserDefaultValue
	end

	--Neither Checked
	if @ViewpointDefault = 'N' and @Override = 'N'
	begin
		set @ValueOut = @ValueIn
	end

end try

begin catch
	select @msg = 'Error: ' + error_message() + char(13) + char(10) + 'Line #' + error_line(), @rcode = 1
	goto vspexit
end catch


vspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMImportDefaultValues] TO [public]
GO
