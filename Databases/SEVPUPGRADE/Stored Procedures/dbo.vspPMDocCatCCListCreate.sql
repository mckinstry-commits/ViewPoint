SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE PROCEDURE [dbo].[vspPMDocCatCCListCreate]
/***********************************************************
* CREATED By:	GF 07/14/2009 - issue #24641
* MODIFIED By:
*
*
* USAGE:
* creates the CC list that will be used in PM Documents and
* also for test purposes in PM Document Category Overrides.
*
* PASS:
* PMCo			PM Company
* DocCat		Document Category
* OvrCCList		CC List verbage
* VendorGroup	PM Vendor Group
* Firm			PM Firm Number
* Contact		PM Firm Contact Code
* CCResults		Results of the CC List test as verbage and column values
*
*
* RETURNS:
* 
* ErrMsg if any
* 
* OUTPUT PARAMETERS
*   @msg     Error message if invalid, 
* RETURN VALUE
*   0 Success
*   1 fail
*****************************************************/ 
(@pmco bCompany = null, @doccat varchar(10) = null, @ovrcclist nvarchar(max) = null,
 @vendorgroup bGroup = null, @firm bVendor = null, @contact bEmployee = null, 
 @msg nvarchar(max) = null output)
as
set nocount on

declare @rcode int, @array_value varchar(255), @file_position int, @file_value varchar(30),
		@column_value varchar(100), @apco dbo.bCompany, @columns nvarchar(max),
		@start_position int, @end_position int, @column_results nvarchar(100),
		@sql nvarchar(max), @firm_where nvarchar(500), @contact_where nvarchar(500),
		@param_definition nvarchar(500), @column_result nvarchar(100),
		@opencursor int, @partstring nvarchar(100), @parttable nvarchar(100),
		@partcolumn nvarchar(100), @results nvarchar(100)

set @rcode = 0
set @columns = @ovrcclist

---- when firm is null we are in test mode and need to retrieve values
---- needed to test the CC list override
if @firm is null
	begin
	select @apco=p.APCo, @vendorgroup = h.VendorGroup
	from dbo.PMCO p with (nolock) join dbo.HQCO h with (nolock) on h.HQCo = p.APCo
	where p.PMCo = @pmco
	if @@rowcount = 0 set @vendorgroup = null

	---- get first Firm from PMFM and First Contact for Firm from PMPM
	if @vendorgroup is not null
		begin
		if exists(select top 1 1 from dbo.PMPM with (nolock) where VendorGroup = @vendorgroup)
			begin
			select top 1 @firm = FirmNumber, @contact = ContactCode
			from dbo.PMPM with (nolock) where VendorGroup = @vendorgroup
			order by VendorGroup, FirmNumber, ContactCode
			end
		end
	end


---- build the where clause for firm and contact
---- will either used parameters of test defaults
set @firm_where = ' from dbo.PMFM where dbo.PMFM.VendorGroup = ' + convert(varchar(10),@vendorgroup) + ' and dbo.PMFM.FirmNumber = ' + convert(varchar(10),@firm)
set @contact_where = ' from dbo.PMPM where dbo.PMPM.VendorGroup = ' + convert(varchar(10),@vendorgroup) + ' and dbo.PMPM.FirmNumber = ' + convert(varchar(10), @firm) + ' and dbo.PMPM.ContactCode = ' + convert(varchar(10), @contact)


---- create table variable to store table, column, and output for each
---- column as defined in the CC List String that will be returned output
declare @cclisttable table
(
	PartString		nvarchar(100) not null,
	PartTable		nvarchar(100) not null,
	PartColumn		nvarchar(100) not null,
	Results			nvarchar(100) null
)


select @columns = replace(@columns,'[','{')
select @columns = replace(@columns,']','}')

---- parse out the columns and check if in INFORMATION_SCHEMA.COLUMNS
---- Loop through the string searching for separtor characters
WHILE PATINDEX('%{%', @columns) <> 0 
    BEGIN
		
		select @start_position = 0, @end_position = 0, @array_value = null, @file_position = 0,
			   @file_value = null, @column_value = null
		select @start_position = PATINDEX('%{%', @columns)
		select @end_position = PATINDEX('%}%', @columns)
		
		select @array_value = substring(@columns, @start_position, @end_position - @start_position + 1)
		select @array_value = ltrim(rtrim(@array_value))
		select @array_value = replace(@array_value,'{','[')
		select @array_value = replace(@array_value,'}',']')
		
		---- now split the @array_value into file and column values
		select @file_position = PATINDEX('%.%', @array_value)
		if @file_position > 3
			begin
			select @file_value = substring(@array_value, 1, @file_position - 1)
			select @column_value = substring(@array_value, @file_position + 1, datalength(@array_value))
			
			select @file_value = replace(@file_value,'[','')
			select @column_value = replace(@column_value,']','')
			
			set @column_results = null
			---- validate to SCHEMA
			if exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @file_value and COLUMN_NAME = @column_value)
				begin
				--if @exists = 'N'
				--	begin
				--	select @column_results = isnull(@column_value,'')
				--	end
				--else
				--	begin
					if @file_value = 'PMFM'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMFM.' + @column_value + ')'
						set @sql = @sql + @firm_where
						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end
						
					if @file_value = 'PMPM'
						begin
						set @sql = N'SELECT @value_out = convert(nvarchar(100), PMPM.' + @column_value + ')'
						set @sql = @sql + @contact_where
						set @param_definition = N'@value_out nvarchar(100) output'
						
						execute sp_executesql @sql, @param_definition, @value_out = @column_result OUTPUT;
						set @column_results = isnull(@column_result,'');
						end
					--end
				end
			
			---- insert rows int @cclisttable
			insert @cclisttable(PartString, PartTable, PartColumn, Results)
			select @array_value, @file_value, @column_value, @column_results
			end
		
		select @columns = stuff(@columns, 1, @end_position, '')
		
	END


---- declare cursor on @cclisttable and replace columns in @ovrcclist with results
declare bcCCList cursor local fast_forward for select p.PartString, p.PartTable, p.PartColumn, p.Results
from @cclisttable p
group by p.PartString, p.PartTable, p.PartColumn, p.Results

---- open cursor
open bcCCList
select @opencursor = 1

CCList_loop:
fetch next from bcCCList into @partstring, @parttable, @partcolumn, @results

if @@fetch_status <> 0 goto CCList_end

select @ovrcclist = replace(@ovrcclist, @partstring, isnull(ltrim(rtrim(@results)),''))

goto CCList_loop

CCList_end:
	if @opencursor = 1
		begin
		close bcCCList
		deallocate bcCCList
		set @opencursor = 0
		end



select @msg = @ovrcclist



bspexit:
	----if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocCatCCListCreate] TO [public]
GO
