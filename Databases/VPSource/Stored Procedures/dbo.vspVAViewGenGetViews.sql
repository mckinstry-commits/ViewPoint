SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVAViewGenGetViews]
  /********************************
  * Created MJ 08/22/2006
  * Modified: JonathanP 03/02/2007 - Updated this procedure to only return the tables for modules that can
  *									 have data security. (AP,AR,CM,EM,GL,HQ,HR,IN,JB,JC,MS,PM,PO,PR,RQ,SL)
  *			  DANF 01/21/2007 - Issue 126735 - Corrected query that returns base views.
  *			  JonathanP 05/22/2008 - Issue 128393 - added "as TableName" to the select
  *			  JonathanP 09/17/2008 - Issue 129659 - changed select statement to now include a ViewName column and to order by ViewName
  *			  JonathanP 02/18/2008 - Issue 129835 - Added @datatype parameter to filter down the result set.
  *
  *	Inputs:
  *		@datatype parameter - Pass null to return all securable views. Pass a datatype to filter down to only those views can be
  *							  secured for that type.
  *
  *
  *********************************/
  	(@datatype varchar(30) = null, @msg varchar(512) OUTPUT)
  AS
set nocount on

declare @rcode int
select @rcode = 0

  begin	
	
	-- Select all the rows matching the given datatype, or return all rows if no datatype
	-- is specified.
	select distinct substring(s.TableName, 2, len(s.TableName)) as ViewName, 
			        s.TableName as TableName, 
			        d.[Description] as [Description],
			        s.ViewIsOutOfSync
		from DDSLShared s with (nolock)
		left join DDTH d with (nolock) on d.TableName = substring(s.TableName, 2, len(s.TableName))
		where (s.Datatype = @datatype or @datatype = '' or @datatype is null)  AND s.TableName <> 'bHQMA'
		order by ViewName

	if @@rowcount = 0
  	begin
  	select @msg = 'Unable to retrieve tables.', @rcode = 1
  	end	
  end   
  
 vspexit:	
  	return @rcode


-- OLD PROCEDURE

--if @datatype is null or @datatype = ''
	--begin					
	--	-- Get all of the views with their underlying tables that should be refreshed. Insert the result set into a table variable.	 
		
	--	select a.*
	--		from
	--			(select convert(varchar(30),substring(t.TABLE_NAME, 2,LEN(t.TABLE_NAME))) as ViewName, 
	--				   convert(varchar(30), t.TABLE_NAME) as TableName			   ,
	--				   d.Description as Description,
	--				   s.ViewIsOutOfSync as ViewIsOutOfSync			   
	--				from INFORMATION_SCHEMA.TABLES t with (nolock)
	--				join INFORMATION_SCHEMA.TABLES v with (nolock)
	--					on t.TABLE_CATALOG = v.TABLE_CATALOG and t.TABLE_SCHEMA = v.TABLE_SCHEMA and 
	--					   substring(t.TABLE_NAME, 2,LEN(t.TABLE_NAME)) = v.TABLE_NAME and v.TABLE_TYPE = 'VIEW'										   
	--				left join DDTH d with (nolock) on d.TableName = substring(t.TABLE_NAME, 2,LEN(t.TABLE_NAME))
	--				left join (select distinct TableName, ViewIsOutOfSync from DDSLShared with (nolock)) s on s.TableName = t.TABLE_NAME
	--				where t.TABLE_TYPE = 'BASE TABLE' and substring(t.TABLE_NAME, 2,2) <> 'DD' and 
	--					  substring(t.TABLE_NAME, 2,2) <> 'RP' and substring(t.TABLE_NAME, 2,3) <> 'frl') a 											  						  
	--		order by a.ViewName
	--end
	--else
	--begin
	--	select distinct substring(s.TableName, 2, len(s.TableName)) as ViewName, 
	--			        s.TableName as TableName, 
	--			        d.[Description] as [Description],
	--			        s.ViewIsOutOfSync
	--		from DDSLShared s with (nolock)
	--		left join DDTH d with (nolock) on d.TableName = substring(s.TableName, 2, len(s.TableName))
	--		where s.Datatype = @datatype
	--end


GO
GRANT EXECUTE ON  [dbo].[vspVAViewGenGetViews] TO [public]
GO
