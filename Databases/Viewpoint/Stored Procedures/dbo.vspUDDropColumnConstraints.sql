SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspUDDropColumnConstraints]
     /************************************************
     	Created 01/17/08 RM
      Modified: 10/31/08 RM - Added [] around table/column names
			      
     	Usage: Used to drop constraints from a column in a UD Table
     
     
     ************************************************/
     (@tablename varchar(50), @columnname varchar(50), @errmsg varchar(255) output)
     WITH EXECUTE AS 'viewpointcs'
     AS

declare @rcode int, @dropstring varchar(1024), @constraintname varchar(255)
select @rcode = 0


	declare DropCursor cursor local fast_forward for select o.name from sysconstraints c 
								join sysobjects t on c.id = t.id 
								join sysobjects o on c.constid = o.id
								join syscolumns m on m.id=t.id and m.colid = c.colid
								where t.name=@tablename and m.name=@columnname


	open DropCursor



	fetch next from DropCursor into @constraintname

	while @@fetch_status = 0
	begin
		select @dropstring = 'alter table [' + @tablename + '] drop constraint [' + @constraintname + ']'

		--print @dropstring
		exec(@dropstring)


		fetch next from DropCursor into @constraintname
	end

GO
GRANT EXECUTE ON  [dbo].[vspUDDropColumnConstraints] TO [public]
GO
