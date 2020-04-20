SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspVAWDTableColumnInsert] 
/**************************************
*    Created by HH - TK-18866 
*				
*    Purpose: To update vWDJBTableColumn when a new
*             Job is created.
*
*    inputs: @jobname
*            @queryname
*			 @querytype
*
*    Outputs @Output
*
**************************************/
(@jobname varchar(50), @queryname varchar(50), @querytype int = 0, @delete varchar(1))
as 

set nocount on

--delete old WDJBTableColumns entries when QueryName has changed
if @delete = 'Y'
begin
	if exists(select 1 from WDJBTableColumns where JobName=@jobname)
	begin
		delete from WDJBTableColumns where JobName=@jobname
	end
end

-- VA Inquiry
if @querytype = 1	
begin
	--if QueryName exists in Query Parameters table insert into Job Params table
	if exists (select ColumnName from VPGridColumns where QueryName = @queryname)
	begin
		insert WDJBTableColumns (JobName, ColumnName, Seq)
		select @jobname, '['+c.ColumnName+']', c.DefaultOrder
		from VPGridColumns c 
		where c.QueryName = @queryname
			and not exists(select * from WDJBTableColumns j where j.ColumnName = c.ColumnName and j.JobName =  @jobname)
		order by c.DefaultOrder
	end 
else 
	if exists (select ColumnName from WDJBTableColumns where JobName =  @jobname)    
	begin
		delete from WDJBTableColumns
		where JobName =  @jobname
	end 
	return
end

-- WF Notifier Query
else
begin
	--if QueryName exists in Query Parameters table insert into Job Params table
	if exists (select TableColumn from WDQF where QueryName = @queryname)
	begin
		insert WDJBTableColumns (JobName, ColumnName, Seq)
		select @jobname, '['+p.TableColumn+']', p.Seq
		from WDQF p 
		where p.QueryName = @queryname
		and not exists(select * from WDJBTableColumns j where j.ColumnName = p.TableColumn and j.JobName =  @jobname)
		order by p.Seq
	end 
else 
	if exists (select ColumnName from WDJBTableColumns where JobName =  @jobname)    
	begin
		delete from WDJBTableColumns
		where JobName =  @jobname
	end 
	return	
end


GO
GRANT EXECUTE ON  [dbo].[vspVAWDTableColumnInsert] TO [public]
GO
