SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspHQResponseValueDescForDocTemplate]
/***********************************************************
* CREATED BY:	GP	03/19/2011 - V1# B-03634
* MODIFIED BY:	
*				
* USAGE:
* Used in PM Doc Template - Response tab to validate Response Value field.
* The values entered by the user in HQResponseValueItem must be allowed by
* the table.
*
* INPUT PARAMETERS
* Template Name - from PM Doc Template
* Seq - from PM Doc Template
* Value Code (Response Value) - from PM Doc Template
*
* OUTPUT PARAMETERS
*   @msg      Description or error if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@TemplateName bReportTitle, @Seq int, @ValueCode varchar(20), @msg varchar(255) output)
as
set nocount on

declare @rcode int,@Datatype varchar(30), @InputType tinyint, @InputPrec tinyint, @InputLength smallint, 
	@ControlType tinyint, @ComboType varchar(20)
	
set @rcode = 0


--Validate
if @TemplateName is null
begin
	select @msg = 'Missing Template Name.', @rcode = 1
	goto vspexit
end

if @Seq is null
begin
	select @msg = 'Missing Seq.', @rcode = 1
	goto vspexit
end

if @ValueCode is null
begin
	select @msg = 'Missing Value Name.', @rcode = 1
	goto vspexit
end

--Get Description
select @msg = [Description] from dbo.HQResponseValue where @ValueCode = ValueCode
if @@rowcount = 0
begin
	select @msg = 'Invalid Response Value.', @rcode = 1
	goto vspexit
end	

begin try
	--Return DD info
	select distinct @Datatype = i.Datatype, @InputType = i.InputType, @InputPrec = i.Prec, 
		@InputLength = i.InputLength, @ControlType = i.ControlType, @ComboType = i.ComboType
	from dbo.HQDocTemplateResponseField r
	join dbo.HQWD d on d.TemplateName = r.TemplateName
	join dbo.HQWO o on o.TemplateType = d.TemplateType and o.DocObject = r.DocObject
	join dbo.DDFH h on (h.ViewName = o.ObjectTable or h.JoinClause like ('%' + o.ObjectTable + '%'))
	join dbo.DDFI i on i.Form = h.Form and i.ColumnName = r.ColumnName
	where r.TemplateName = @TemplateName and r.Seq = @Seq

	--Get more specific datatype info
	if @Datatype is not null
	begin
		select @InputType = InputType, @InputPrec = Prec, @InputLength = InputLength 
		from dbo.DDDT 
		where Datatype = @Datatype
	end

	--Validate string
	if @InputType = 0
	begin
		--check length
		if isnull(@InputLength, 0) <> 0 and exists (select top 1 1 from dbo.HQResponseValueItem where ValueCode = @ValueCode and len(DatabaseValue) > @InputLength)
		begin
			select @msg = 'The Response Value selected contains database values that are too long, the column only allows ' + cast(@InputLength as varchar(20)) + ' characters. Please update the response value items or select another Response Value.', @rcode = 1
			goto vspexit		
		end
	end

	--Validate numeric
	if @InputType = 1
	begin
		--check for varchar
		if exists (select top 1 1 from dbo.HQResponseValueItem where ValueCode = @ValueCode and isnumeric(DatabaseValue) = 1)
		begin
			select @msg = 'The Response Value selected contains database values that are not numeric, the column only allows numeric values. Please update the response value items or select another Response Value.', @rcode = 1
			goto vspexit
		end
		
		--check tinyint
		if @InputPrec = 0 and exists (select top 1 1 from dbo.HQResponseValueItem where ValueCode = @ValueCode and isnumeric(DatabaseValue) = 1 and cast(DatabaseValue as bigint) not between 0 and 255)
		begin
			select @msg = 'The Response Value selected contains database values that are invalid, the column only allows values 0 to 255. Please update the response value items or select another Response Value.', @rcode = 1
			goto vspexit
		end	
		
		--check smallint
		if @InputPrec = 1 and exists (select top 1 1 from dbo.HQResponseValueItem where ValueCode = @ValueCode and isnumeric(DatabaseValue) = 1 and cast(DatabaseValue as bigint) not between -32768 and 32767)
		begin
			select @msg = 'The Response Value selected contains database values that invalid, the column only allows values -32,768 to 32,767. Please update the response value items or select another Response Value.', @rcode = 1
			goto vspexit
		end	
		
		--check int
		if @InputPrec = 2 and exists (select top 1 1 from dbo.HQResponseValueItem where ValueCode = @ValueCode and isnumeric(DatabaseValue) = 1 and cast(DatabaseValue as bigint) not between -2147483648 and 2147483647)
		begin
			select @msg = 'The Response Value selected contains database values that invalid, the column only allows values -2,147,483,648 to 2,147,483,647. Please update the response value items or select another Response Value.', @rcode = 1
			goto vspexit
		end	
				
		--check bigint
		if @InputPrec = 4 and exists (select top 1 1 from dbo.HQResponseValueItem where ValueCode = @ValueCode and isnumeric(DatabaseValue) = 1 and cast(DatabaseValue as bigint) not between -9223372036854775808 and 9223372036854775807)
		begin
			select @msg = 'The Response Value selected contains database values that invalid, the column only allows values -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807. Please update the response value items or select another Response Value.', @rcode = 1
			goto vspexit
		end	
	end

	--Validate date/time
	if @InputType in (3,4)
	begin
		if exists (select top 1 1 from dbo.HQResponseValueItem where ValueCode = @ValueCode and isdate(DatabaseValue) = 0)
		begin
			select @msg = 'The Response Value selected contains database values that are invalid, the column only allows date values. Please update the response value items or select another Response Value.', @rcode = 1
			goto vspexit		
		end
	end
	
	--Validate combobox
	if @ControlType = 3
	begin
		if (select count(1) 
		from dbo.DDCI c
		join dbo.HQResponseValueItem i on i.DatabaseValue = c.DatabaseValue
		where c.ComboType = @ComboType and i.ValueCode = @ValueCode)
		<>
		(select count(1) from dbo.HQResponseValueItem where ValueCode = @ValueCode)
		begin
			select @msg = 'The Response Value selected contains database values that are invalid, the field is a combobox and the value items do not match. Please update the response value items or select another Response Value.', @rcode = 1
			goto vspexit			
		end
	end
end try

--consume other overflow/conversion errors
begin catch
end catch	
		
	
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQResponseValueDescForDocTemplate] TO [public]
GO
