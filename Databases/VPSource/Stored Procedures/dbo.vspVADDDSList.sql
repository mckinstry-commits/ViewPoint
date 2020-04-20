SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
   
CREATE proc [dbo].[vspVADDDSList] 
/************************************************************************
* Created: GG 06/12/07
* Modified: AL 4/29/08 - Added option to filter by security group
*			AL 4/30/08 - Added option to filter by company
*
* Usage:
* Returns a resultset containing all instance and data security group combinations
* for a secure datatype.  Used by VA Data Security to display information in the grid.
*
* Inputs:
*	@datatype			Datatype
*	@securitygroup		Security Group
* Outputs:
*	resultset of data security info for the datatype
*	@msg				Error message
*
* Return code:
*	0 = success, 1 = error w/messsge
*
**************************************************************************/
(@datatype varchar(30), @securitygroup int, @company smallint, @msg varchar(512) output)
with execute as 'viewpointcs'	-- required for dynamic query
as

set nocount on 

declare @rcode integer, @mastertable varchar(30), @mastercol varchar(30), @masterdesccol varchar(30),
	@qualifiercol varchar(30), @sqldatatype varchar(30), @tsql nvarchar(4000)

select @rcode = 0

-- get Datatype info   
select @mastertable = MasterTable, @mastercol = MasterColumn, @masterdesccol = MasterDescColumn,
	@qualifiercol = QualifierColumn, @sqldatatype = SQLDatatype
from dbo.vDDDT (nolock)
where  Datatype = @datatype

if @@rowcount = 0
	begin
   	select @msg = 'Invalid Datatype!', @rcode = 1
   	goto vspexit
   	end
if @sqldatatype is null 
	begin
	select @msg = @datatype + ' has not been assigned a SQL datatype.', @rcode = 1
	goto vspexit
	end

-- build select query to return all instance and data security group combinations for the datatype
if @sqldatatype = 'bCompany' 
	begin
	if @securitygroup is not null or @securitygroup = 0 
		begin
		
		if @company is not null
			begin
			select @tsql = 'select m.' + @qualifiercol + ' as [Qualifier], m.' + @mastercol + ' as [Instance], ' 
			+ 'c.Name as [Description], g.SecurityGroup, g.Name as [SecGroupName], '
			+ 'case when s.Instance is null then ''N'' else ''Y'' end as [Allowed] '
			+ 'from dbo.' + @mastertable + ' m (nolock) '
			+ 'join dbo.vDDDT d (nolock) on d.Datatype = @datatype '
			+ 'left join dbo.vDDSG g (nolock) on g.GroupType = 0 '	-- data security groups
			+ 'left join dbo.vDDDS s (nolock) on s.Datatype = @datatype and s.Qualifier = ' + @qualifiercol
			+ ' and s.Instance = convert(varchar,m.' + @mastercol + ') and s.SecurityGroup = g.SecurityGroup '
			+ 'left join dbo.bHQCO c (nolock) on c.HQCo = m.' + @qualifiercol
			+ ' where g.SecurityGroup = @securitygroup and m.' + @qualifiercol +' = @company'
			-- union with vDDDS to include entries no longer existing in datatype's master table
			+ ' union select s.Qualifier, s.Instance, c.Name as [Description], s.SecurityGroup, g.Name as [SecGroupName], '
			+ '''Y'' from dbo.vDDDS s (nolock) join dbo.vDDSG g (nolock) on g.SecurityGroup = s.SecurityGroup '
			+ 'left join dbo.bHQCO c (nolock) on c.HQCo = s.Qualifier ' 
			+ 'where s.Datatype = @datatype and s.SecurityGroup = @securitygroup and s.Qualifier = @company '
			+ 'order by Qualifier, Instance, SecurityGroup'
			end
		else
			begin
		-- Company based datatypes join to bHQCO to pull company name 
			select @tsql = 'select m.' + @qualifiercol + ' as [Qualifier], m.' + @mastercol + ' as [Instance], ' 
				+ 'c.Name as [Description], g.SecurityGroup, g.Name as [SecGroupName], '
				+ 'case when s.Instance is null then ''N'' else ''Y'' end as [Allowed] '
				+ 'from dbo.' + @mastertable + ' m (nolock) '
				+ 'join dbo.vDDDT d (nolock) on d.Datatype = @datatype '
				+ 'left join dbo.vDDSG g (nolock) on g.GroupType = 0 '	-- data security groups
				+ 'left join dbo.vDDDS s (nolock) on s.Datatype = @datatype and s.Qualifier = ' + @qualifiercol
				+ ' and s.Instance = convert(varchar,m.' + @mastercol + ') and s.SecurityGroup = g.SecurityGroup '
				+ 'left join dbo.bHQCO c (nolock) on c.HQCo = m.' + @qualifiercol
				+ ' where g.SecurityGroup = @securitygroup'
				-- union with vDDDS to include entries no longer existing in datatype's master table
				+ ' union select s.Qualifier, s.Instance, c.Name as [Description], s.SecurityGroup, g.Name as [SecGroupName], '
				+ '''Y'' from dbo.vDDDS s (nolock) join dbo.vDDSG g (nolock) on g.SecurityGroup = s.SecurityGroup '
				+ 'left join dbo.bHQCO c (nolock) on c.HQCo = s.Qualifier ' 
				+ 'where s.Datatype = @datatype and s.SecurityGroup = @securitygroup '
				+ 'order by Qualifier, Instance, SecurityGroup'
			end
		end
	else
		begin
			if @company is null 
				begin
				select @tsql = 'select m.' + @qualifiercol + ' as [Qualifier], m.' + @mastercol + ' as [Instance], ' 
				+ 'c.Name as [Description], g.SecurityGroup, g.Name as [SecGroupName], '
				+ 'case when s.Instance is null then ''N'' else ''Y'' end as [Allowed] '
				+ 'from dbo.' + @mastertable + ' m (nolock) '
				+ 'join dbo.vDDDT d (nolock) on d.Datatype = @datatype '
				+ 'left join dbo.vDDSG g (nolock) on g.GroupType = 0 '	-- data security groups
				+ 'left join dbo.vDDDS s (nolock) on s.Datatype = @datatype and s.Qualifier = ' + @qualifiercol
				+ ' and s.Instance = convert(varchar,m.' + @mastercol + ') and s.SecurityGroup = g.SecurityGroup '
				+ 'left join dbo.bHQCO c (nolock) on c.HQCo = m.' + @qualifiercol
				-- union with vDDDS to include entries no longer existing in datatype's master table
				+ ' union select s.Qualifier, s.Instance, c.Name as [Description], s.SecurityGroup, g.Name as [SecGroupName], '
				+ '''Y'' from dbo.vDDDS s (nolock) join dbo.vDDSG g (nolock) on g.SecurityGroup = s.SecurityGroup '
				+ 'left join dbo.bHQCO c (nolock) on c.HQCo = s.Qualifier ' 
				+ 'where s.Datatype = @datatype '
				+ 'order by Qualifier, Instance, SecurityGroup'
				end
			
			else
				begin
				select @tsql = 'select m.' + @qualifiercol + ' as [Qualifier], m.' + @mastercol + ' as [Instance], ' 
				+ 'c.Name as [Description], g.SecurityGroup, g.Name as [SecGroupName], '
				+ 'case when s.Instance is null then ''N'' else ''Y'' end as [Allowed] '
				+ 'from dbo.' + @mastertable + ' m (nolock) '
				+ 'join dbo.vDDDT d (nolock) on d.Datatype = @datatype '
				+ 'left join dbo.vDDSG g (nolock) on g.GroupType = 0 '	-- data security groups
				+ 'left join dbo.vDDDS s (nolock) on s.Datatype = @datatype and s.Qualifier = ' + @qualifiercol
				+ ' and s.Instance = convert(varchar,m.' + @mastercol + ') and s.SecurityGroup = g.SecurityGroup '
				+ 'left join dbo.bHQCO c (nolock) on c.HQCo = m.' + @qualifiercol
				+ ' where s.Qualifier = @company '
				-- union with vDDDS to include entries no longer existing in datatype's master table
				+ ' union select s.Qualifier, s.Instance, c.Name as [Description], s.SecurityGroup, g.Name as [SecGroupName], '
				+ '''Y'' from dbo.vDDDS s (nolock) join dbo.vDDSG g (nolock) on g.SecurityGroup = s.SecurityGroup '
				+ 'left join dbo.bHQCO c (nolock) on c.HQCo = s.Qualifier ' 
				+ 'where s.Datatype = @datatype and s.Qualifier = @company '
				+ 'order by Qualifier, Instance, SecurityGroup'
				end
		end
	end
else
	begin
	
		if @securitygroup is not null or @securitygroup = 0
			begin
			
			if @company is not null
				begin
				select @tsql = 'select m.' + @qualifiercol + ' as [Qualifier], m.' + @mastercol + ' as [Instance], m.'
				+ @masterdesccol + ' as [Description], g.SecurityGroup, g.Name as [SecGroupName],'
				+ 'case when s.Instance is null then ''N'' else ''Y'' end as [Allowed] '
				+ 'from dbo.' + @mastertable + ' m (nolock) '
				+ 'join dbo.vDDDT d (nolock) on d.Datatype = @datatype '
				+ 'left join dbo.vDDSG g (nolock) on g.GroupType = 0 '	-- data security groups
				+ 'left join dbo.vDDDS s (nolock) on s.Datatype = @datatype and s.Qualifier = ' + @qualifiercol
				+ ' and s.Instance = convert(varchar,m.' + @mastercol + ') and s.SecurityGroup = g.SecurityGroup '
				+ 'where g.SecurityGroup = @securitygroup and m.' + @qualifiercol +' = @company '
				-- union with vDDDS to include entries no longer existing in datatype's master table 1
				+ 'union select s.Qualifier, s.Instance, null, s.SecurityGroup, g.Name as [SecGroupName], '
				+ '''Y'' from dbo.vDDDS s (nolock) join dbo.vDDSG g (nolock) on g.SecurityGroup = s.SecurityGroup '
				+ 'where s.Datatype = @datatype and s.Qualifier = @company and s.SecurityGroup = @securitygroup and not exists(select top 1 1 from dbo.' + @mastertable
				+ ' m (nolock) where  m.' + @qualifiercol + ' = s.Qualifier and m.' + @mastercol + ' = s.Instance) '
				+ 'order by Qualifier, Instance, SecurityGroup'
				end
			else
				begin	
				select @tsql = 'select m.' + @qualifiercol + ' as [Qualifier], m.' + @mastercol + ' as [Instance], m.'
					+ @masterdesccol + ' as [Description], g.SecurityGroup, g.Name as [SecGroupName],'
					+ 'case when s.Instance is null then ''N'' else ''Y'' end as [Allowed] '
					+ 'from dbo.' + @mastertable + ' m (nolock) '
					+ 'join dbo.vDDDT d (nolock) on d.Datatype = @datatype '
					+ 'left join dbo.vDDSG g (nolock) on g.GroupType = 0 '	-- data security groups
					+ 'left join dbo.vDDDS s (nolock) on s.Datatype = @datatype and s.Qualifier = ' + @qualifiercol
					+ ' and s.Instance = convert(varchar,m.' + @mastercol + ') and s.SecurityGroup = g.SecurityGroup '
					+ 'where g.SecurityGroup = @securitygroup '
					-- union with vDDDS to include entries no longer existing in datatype's master table 2
					+ 'union select s.Qualifier, s.Instance, null, s.SecurityGroup, g.Name as [SecGroupName], '
					+ '''Y'' from dbo.vDDDS s (nolock) join dbo.vDDSG g (nolock) on g.SecurityGroup = s.SecurityGroup '
					+ 'where s.Datatype = @datatype and s.SecurityGroup = @securitygroup and not exists(select top 1 1 from dbo.' + @mastertable
					+ ' m (nolock) where  m.' + @qualifiercol + ' = s.Qualifier and m.' + @mastercol + ' = s.Instance) '
					+ 'order by Qualifier, Instance, SecurityGroup'
				end
			end
				
		else		
			begin
			
			if @company is not null
				begin
					-- all others use datatype description column
				select @tsql = 'select m.' + @qualifiercol + ' as [Qualifier], m.' + @mastercol + ' as [Instance], m.'
					+ @masterdesccol + ' as [Description], g.SecurityGroup, g.Name as [SecGroupName],'
					+ 'case when s.Instance is null then ''N'' else ''Y'' end as [Allowed] '
					+ 'from dbo.' + @mastertable + ' m (nolock) '
					+ 'join dbo.vDDDT d (nolock) on d.Datatype = @datatype '
					+ 'left join dbo.vDDSG g (nolock) on g.GroupType = 0 '	-- data security groups
					+ 'left join dbo.vDDDS s (nolock) on s.Datatype = @datatype and s.Qualifier = ' + @qualifiercol
					+ ' and s.Instance = convert(varchar,m.' + @mastercol + ') and s.SecurityGroup = g.SecurityGroup '
					+ 'where m.' + @qualifiercol +' = @company '
					-- union with vDDDS to include entries no longer existing in datatype's master table 3
					+ 'union select s.Qualifier, s.Instance, null, s.SecurityGroup, g.Name as [SecGroupName], '
					+ '''Y'' from dbo.vDDDS s (nolock) join dbo.vDDSG g (nolock) on g.SecurityGroup = s.SecurityGroup '
					+ 'where s.Datatype = @datatype and s.Qualifier = @company and not exists(select top 1 1 from dbo.' + @mastertable
					+ ' m (nolock) where  m.' + @qualifiercol + ' = s.Qualifier and m.' + @mastercol + ' = s.Instance) '
					+ 'order by Qualifier, Instance, SecurityGroup'
				end
			else
				begin
				-- all others use datatype description column
				select @tsql = 'select m.' + @qualifiercol + ' as [Qualifier], m.' + @mastercol + ' as [Instance], m.'
					+ @masterdesccol + ' as [Description], g.SecurityGroup, g.Name as [SecGroupName],'
					+ 'case when s.Instance is null then ''N'' else ''Y'' end as [Allowed] '
					+ 'from dbo.' + @mastertable + ' m (nolock) '
					+ 'join dbo.vDDDT d (nolock) on d.Datatype = @datatype '
					+ 'left join dbo.vDDSG g (nolock) on g.GroupType = 0 '	-- data security groups
					+ 'left join dbo.vDDDS s (nolock) on s.Datatype = @datatype and s.Qualifier = ' + @qualifiercol
					+ ' and s.Instance = convert(varchar,m.' + @mastercol + ') and s.SecurityGroup = g.SecurityGroup '
					-- union with vDDDS to include entries no longer existing in datatype's master table 4
					+ 'union select s.Qualifier, s.Instance, null, s.SecurityGroup, g.Name as [SecGroupName], '
					+ '''Y'' from dbo.vDDDS s (nolock) join dbo.vDDSG g (nolock) on g.SecurityGroup = s.SecurityGroup '
					+ 'where s.Datatype = @datatype and not exists(select top 1 1 from dbo.' + @mastertable
					+ ' m (nolock) where  m.' + @qualifiercol + ' = s.Qualifier and m.' + @mastercol + ' = s.Instance) '
					+ 'order by Qualifier, Instance, SecurityGroup'
				end
			end
		
		end
	
--print @tsql


exec sp_executesql @tsql,N'@datatype varchar(10),@securitygroup int, @company smallint',@datatype,@securitygroup, @company

vspexit:
	return @rcode    

   






GO
GRANT EXECUTE ON  [dbo].[vspVADDDSList] TO [public]
GO
