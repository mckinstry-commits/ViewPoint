SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE dbo.vpspAquireTextLengthOfDataType 
/************************************************************
* CREATED:     8/1/07  CHS
* Modified:	GG 10/16/07 - #125791 - fix for DDDTShared
*
* USAGE:
*   gets text length of columns in a given table
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    @objname --table name
*
************************************************************/
(@objname nvarchar(776) = NULL)

AS
	SET NOCOUNT ON;
	
	set nocount on
	declare	@dbname	sysname, @no varchar(35), @yes varchar(35), @none varchar(35)

	select @no = 'no', @yes = 'yes', @none = 'none'

	-- @objname must be either sysobjects or systypes: first look in sysobjects
	declare @objid int
	declare @sysobj_type char(2)
	select @objid = object_id, @sysobj_type = type from sys.all_objects where object_id = object_id(@objname)



	-- DISPLAY COLUMN IF TABLE / VIEW
	if exists (select * from sys.all_columns where object_id = @objid)
	begin

		select
			'Column_name'			= name,
			'Type'					= type_name(user_type_id),
			--'Length'				= convert(int, max_length),
			--'Nullable'				= case when is_nullable = 0 then @no else @yes end,
			--t.InputLength,

			case 
				when (t.InputLength is null) then 
						case
							when (type_name(user_type_id) = 'varchar') then convert(int, max_length) 
							when (type_name(user_type_id) = 'char') then convert(int, max_length) 
							when (type_name(user_type_id) = 'bAPReference') then convert(int, max_length) 							
							when (type_name(user_type_id) = 'tinyint') then convert(int, max_length) * 3
							when (type_name(user_type_id) = 'int') then convert(int, max_length) * 11
							when (type_name(user_type_id) = 'smallint') then convert(int, max_length) * 6
							when (type_name(user_type_id) = 'bigint') then convert(int, max_length) * 20
							when (type_name(user_type_id) = 'bCompany') then convert(int, max_length) * 3
							when (type_name(user_type_id) = 'bSortName') then convert(int, max_length)
						end 
				when (t.InputLength < 1) then null
				else t.InputLength 
			end as 'TextLength'

		from sys.all_columns 
			left join dbo.DDDTShared t (nolock) on type_name(user_type_id) = t.Datatype

		where object_id = @objid
	end
	return (0)
GO
GRANT EXECUTE ON  [dbo].[vpspAquireTextLengthOfDataType] TO [VCSPortal]
GO
