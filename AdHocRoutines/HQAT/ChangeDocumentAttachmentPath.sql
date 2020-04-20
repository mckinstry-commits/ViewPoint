Use Viewpoint
go

declare @oldAttPath varchar(256)
declare @newAttPath varchar(256)
select 
	@oldAttPath='\\mckconimg\ViewpointAttachments\'
,	@newAttPath='\\setestconimg\Viewpoint'

begin tran

update HQAO set TempDirectory=@newAttPath, PermanentDirectory=@newAttPath
update HQAT set DocName=replace(DocName,@oldAttPath,@newAttPath)

commit tran

