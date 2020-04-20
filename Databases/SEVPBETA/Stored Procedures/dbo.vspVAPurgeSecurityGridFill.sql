SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
CREATE  proc [dbo].[vspVAPurgeSecurityGridFill]
/****************************************************************************
* Created: DANF 04/20/2004
* Modified: DANF 11/16/2004 - 26126 Added Index to increase performance.
*			AL 2/28/07 - Ported to V6. changed table names to reflect new tables
*			AL 4/26/07 - Added If statement prior to exec to ensure the proper columns exist
*			AL 5/7/07  - Changed access from tables TO VIEWS, added SUBSTRING statements
*							 IN DYNAMIC sql TO remove prevailing b OR v  
*			GG 06/15/07 - Performance mods, load temp table with vDDDS values and remove when qualifier and 
*						instance value found in linked table.  Entries remaining in temp table will be those
*						no longer in use.  Eliminates a query and runs much faster!
*						Changed back to use tables (instead of views) to avoid data security filtering out rows
*						in linked tables.
*						Added try/catch block for error trap and return message.
*			AL 9/14/09 - execute as viewpointcs
*
* Usage:
* 	Returns a resultset of Data Security entries where the Qualifier and Instance values
*	 for a Datatype have no corresponding entries in any of its linked tables.
*
* Inputs:
*	@datatype		Datatype
*
* Output:
*	resultset of Qualifier and Instance values
*	@msg			Error message
*
* Return code:
*	0 = success, 1 = error
*
*****************************************************************************/
(@datatype varchar(30), @msg varchar(5000) = '' output) with execute as 'viewpointcs'

as

set nocount on
    
declare	@TableName varchar(30),	@InstanceColumn varchar(30), @QualifierColumn varchar(30),
	@openDDSL tinyint, @tsql varchar(2000), @rcode int

set @rcode = 0
   
-- create a temp table to hold datatype qualifier and instance values   
create table #SecureData
	(Qualifier varchar (30) NULL,
	 Instance varchar (30) NULL)
  
-- load temp table with all values, they will be eliminated as found in linked tables 

insert #SecureData 
select Qualifier, Instance
from dbo.vDDDS s(nolock)
where Datatype = @datatype 
order by Qualifier, Instance


if @@rowcount = 0 goto endDDSL	-- no reason to continue

-- create a cursor to loop through all tables linked to the datatype
declare DDSL_curs cursor local fast_forward for
select TableName, InstanceColumn, QualifierColumn
from dbo.DDSLShared
where Datatype = @datatype 

-- open cursor
open DDSL_curs
select @openDDSL=1

-- loop through cursor
next_DDSL:
	fetch next from DDSL_curs
	into @TableName, @InstanceColumn, @QualifierColumn
   
	if @@fetch_status <> 0 goto endDDSL

	-- construct a query to remove rows from #SecureData if the Qualifier and Instance values
	-- for the datatype exist in the linked table
	select @tsql = 'delete #SecureData from #SecureData s where exists(select top 1 1 from dbo.'
		+ @TableName + ' a (nolock) where s.Qualifier = a.' + @QualifierColumn
		+ ' and s.Instance = convert(varchar,a.' + @InstanceColumn + '))' 

	-- exit if all entries in #SecureData have been removed 
	if not exists(select top 1 1 from #SecureData) goto endDDSL

	-- use error trapping to retieve error message (e.g. invalid object or column)
	begin try
	  exec (@tsql)
	end try
	begin catch
				if @msg is not null
				
						select @msg = @msg + 'Security Links problem - Table: ' + @TableName + ' Qualifier Column: ' + @QualifierColumn
								+ ' Instance Column: ' + @InstanceColumn + ' Error: ' + Error_Message(), @rcode = 1
		
				else
						select @msg = 'Security Links problem - Table: ' + @TableName + ' Qualifier Column: ' + @QualifierColumn
								+ ' Instance Column: ' + @InstanceColumn + ' Error: ' + Error_Message(), @rcode = 1
								
	end catch

 	goto next_DDSL
 

endDDSL:
	-- return any rows remaining in temp table
    select * from #SecureData

	-- cleanup 
    if @openDDSL = 1
		begin
        close DDSL_curs
        deallocate DDSL_curs
        end
    
	drop table #SecureData

	return @rcode
   







GO
GRANT EXECUTE ON  [dbo].[vspVAPurgeSecurityGridFill] TO [public]
GO
