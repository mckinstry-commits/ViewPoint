SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMEquipChangeOpenBatchList]
/************************************************************
*     Created by: TRL 08//08 Issue 126196.
*	  Modified by:	
*
*	  Form:  EM Equipment Change
*     Usage: Query used to return open batch list where equipment exists
*	  
*
*	  Input Parameters
*     EM Company, VPUserName, Equipment
*
*************************************************************/
(@emco bCompany,@vpusername bVPUserName,@equipment bEquip,
@viewpointdatabase varchar(128),@errmsg varchar(256)output)

as

set nocount on

declare @rcode int, @opencursor int,
@tablename varchar(128),@columnname varchar(128),@vpmodco varchar(10),@vpemco varchar(10),
@sqlstring as NVARCHAR(1000),@paramdef as NVARCHAR(500)

select @rcode = 0,@opencursor = 0 

--Validate EM Co
if @emco is null
Begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto vspexit
End
--Validate User Name
If IsNull(@vpusername,'') = '' 
Begin
	select @errmsg = 'Missing VP User Name!',@rcode = 1
	goto vspexit
End
If not exists(select top 1 1 from DDUP with (nolock) where VPUserName=@vpusername )
Begin
	select @errmsg = 'User name does not exist in VA User Profile!', @rcode = 1
	goto vspexit
End

--Validate Equipment
--Check for missing equipment
if IsNull(@equipment,'') = ''
Begin
	select @errmsg = 'Missing Equipment code to change!', @rcode = 1
	goto vspexit
End

If not exists (select top 1 1 from dbo.EMEH Where EMCo=@emco and OldEquipmentCode=@equipment)
begin
	--Check for valid equipment code	
	If not exists(select top 1 1 from dbo.EMEM with(nolock) Where EMCo=@emco and Equipment=@equipment)
	Begin
		select @errmsg = 'Invalid Equipment code!', @rcode = 1
		goto vspexit
	End
End

--Check for missing databasename
if IsNull(@viewpointdatabase,'') = ''
Begin
	select @errmsg = 'Viewpoint database cannot be null!', @rcode = 1
	goto vspexit
End

create  table #OpenBatchList
(Co tinyint,Mth smalldatetime, BatchId int, SourceType varchar(10),
CreatedBy varchar(128),InUseBy varchar(128),BatchStatus tinyint)

declare cOpenBatchList cursor local fast_forward for

Select VPTableName,VPColumnName,VPEMCo,Co
FROM  dbo.EMChangeBatchList with(nolock)
Where ViewpointDB=@viewpointdatabase 

Open cOpenBatchList
select @opencursor = 1

goto NextBatchTable
NextBatchTable:

fetch next from cOpenBatchList into @tablename,@columnname,@vpemco,@vpmodco

If (@@fetch_status <> 0) 
begin
	goto CloseOpenBatchCursor
end

--Insert Open Batch information
set @sqlstring = N'Insert into #OpenBatchList (Co,Mth,BatchId,SourceType,CreatedBy,InUseBy,BatchStatus) '+
	  ' Select c.Co, c.Mth, c.BatchId, c.Source, c.CreatedBy, c.InUseBy, c.Status' + 
	  ' From dbo.'+ @tablename +' t with(nolock) '+ 
	  ' Left Join HQBC c with(nolock)on t.'+@vpmodco+' = c.Co and t.Mth=c.Mth and t.BatchId = c.BatchId '+
	  ' Where c.Status <5 and t.'+@vpemco+ '=@emco and t.'+@columnname+' = @equipment'

set @paramdef = N'@emco tinyint, @equipment varchar(20)'

exec sp_executesql @sqlstring,@paramdef,@emco,@equipment

--select next batch table
goto NextBatchTable

CloseOpenBatchCursor:
If @opencursor = 1
begin
	close cOpenBatchList
	deallocate cOpenBatchList
End
--This is the final selection for the batch list
Select Co,Mth,BatchId,
Source=case when IsNull(SourceType,'')='' then 'Payroll' else SourceType end,
CreatedBy,InUseBy,
Status = case when BatchStatus = 0 then 'Open'
				  when BatchStatus = 1 then 'Validation in Progress'
				  when BatchStatus = 2 then 'Validation Errors'
				  when BatchStatus = 3 then 'Validation OK'
				  when BatchStatus = 4 then 'Posting in Progress'
				  when BatchStatus = 5 then 'Posted Successfully'
				  when BatchStatus = 6 then 'Canceled' 
				  else '???' end
From #OpenBatchList
Group by  Co,Mth,BatchId,SourceType,CreatedBy,InUseBy,BatchStatus
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipChangeOpenBatchList] TO [public]
GO
