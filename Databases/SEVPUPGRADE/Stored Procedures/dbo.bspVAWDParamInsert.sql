SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspVAWDParamInsert] 
/**************************************
*    Created by TV 
*				TV - 23061 added isnulls
*				MV - 28347 delete old queryname
*				HH - TK-18458 added VPGridQueryParameters for VA Inquiries
*				
*    Purpose: To update bWDJP when a new
*             Job is created.
*
*    inputs: @jobname
*            @queryname
*
*    Outputs @Output
*
**************************************/
(@jobname varchar(50), @queryname varchar(50), @querytype int = 0, @delete varchar(1))
as 

set nocount on

--delete old WDJP entries when QueryName has changed
if @delete = 'Y'
begin
	if exists(select 1 from WDJP where JobName=@jobname)
	begin
		delete from WDJP where JobName=@jobname
	end
end

-- VA Inquiry
if @querytype = 1	
begin
	--if QueryName exists in Query Parameters table insert into Job Params table
	if exists (select ParameterName from VPGridQueryParameters where QueryName = @queryname)
	begin
		insert WDJP (JobName, Param, Description, QueryName)
		select @jobname, p.ParameterName, p.Description, p.QueryName
		from VPGridQueryParameters p 
		where p.QueryName = @queryname
			and not exists(select * from WDJP j where j.Param = p.ParameterName and j.JobName =  @jobname)
	end 
else 
	if exists (select Param from WDJP where JobName =  @jobname)    
	begin
		delete from WDJP
		where JobName =  @jobname
	end 
	return
end

-- WF Notifier Query
else
begin
	--if QueryName exists in Query Parameters table insert into Job Params table
	if exists (select Param from WDQP where QueryName = @queryname)
	begin
		insert WDJP (JobName, Param, Description, QueryName)
		select @jobname, p.Param, p.Description, p.QueryName
		from WDQP p 
		where p.QueryName = @queryname
		and not exists(select * from WDJP j where j.Param = p.Param and j.JobName =  @jobname)
	end 
else 
	if exists (select Param from WDJP where JobName =  @jobname)    
	begin
		delete from WDJP
		where JobName =  @jobname
	end 
	return	
end


GO
GRANT EXECUTE ON  [dbo].[bspVAWDParamInsert] TO [public]
GO
