SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspUDTCIncrementFieldCheck]
/***********************************************************
* CREATED: 1/23/09 AL
* Usage:
*	Validates that no other field is auto-incrementing.
*
* INPUT PARAMETERS
*   @tablename       Table that column is in
*	  @columnname						Column being checked.
* INPUT PARAMETERS
*   @msg        error message if something went wrong, otherwise description
*
* RETURN VALUE
*   0 Success
*   1 fail
************************************************************************/
  	(@tablename varchar (255) = null, @columnname varchar (255) = null, @autoseqtype tinyint, @msg varchar(255) output)
as
set nocount on

declare @rcode int
select @rcode = 0

Declare @incrementedcolumn as VarChar(255)
declare @keyseq as tinyint

if @autoseqtype = 0
				begin
				goto vspexit
				end

if @tablename is null
	begin
	select @msg = 'Missing Table Name!', @rcode = 1
	goto vspexit
	end

if @columnname is null
	begin
	select @msg = 'Missing Column Name!', @rcode = 1
	goto vspexit
	end

Select @incrementedcolumn = ColumnName from UDTC 
where TableName = @tablename and
AutoSeqType is not null and AutoSeqType <> 0


if @incrementedcolumn is not null and @incrementedcolumn <> @columnname
				begin
				select @msg = 'Only one column can be auto-incrementing', @rcode = 1
				goto vspexit
  	 end
  
select @keyseq = KeySeq from UDTC
where TableName = @tablename and
ColumnName = @columnname

if exists(Select * from UDTC where TableName = @tablename and KeySeq < @keyseq and AutoSeqType is not null and AutoSeqType <> 0)
				begin
				select @msg = 'Auto-incrementing column must be last key column.', @rcode = 1
				goto vspexit
				end 
   
vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspUDTCIncrementFieldCheck] TO [public]
GO
