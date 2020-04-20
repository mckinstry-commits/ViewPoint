SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE  procedure [dbo].[bspPMPCOApproveUserMemoCopy]
/***********************************************************
* CREATED BY:	GF 07/25/2006 - 6.x issue #121954
* Modified By:
*
*
* USAGE: Executed from bspPMPCOApprove to copy change order header user memos
* from pending to approved tables. (PMOP and PMOH)
*
* INPUT:
* @srctablename		Source table name to use for users memos to update
* @desttablename	Destination table name for user memos to update
* @whereclause		Where clause for update statement
*
* OUTPUT:
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@srctablename varchar(30), @desttablename varchar(30), @joins varchar(2000),
 @whereclause varchar(1000), @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @updatestring varchar(4000), @columnname varchar(120)

select @rcode = 0

------ pseudo cursor for ud columns in source to be updated
select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.' + @srctablename)
while @columnname is not null
BEGIN
	------ check if column name exists in destination table
	if exists(select * from syscolumns where name = @columnname and id = object_id('dbo.' + @desttablename))
		begin
		------ update source to destination
		select @updatestring = null
		select @updatestring = 'update ' + @desttablename + ' set ' + @columnname + ' = ' + @srctablename + '.' + @columnname + @joins + @whereclause
		------ execute statement
		exec (@updatestring)
		if @@Error <> 0
			begin
			select @rcode = 1
			goto bspexit
			end
		end


select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.' + @srctablename) and name > @columnname
if @@rowcount = 0 select @columnname = null
END



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOApproveUserMemoCopy] TO [public]
GO
