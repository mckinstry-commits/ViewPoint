SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMAutoUseTempCopy] 
/*****************************************************************
*	created by: TRL - 11/12/08 
*	Modified:	TRL -07/15/09 Issue 129345 added new columns (EMUC/EMUE) BillingStartsOnTrnsfrInDateYN,UseEstDateOutYN to copy
*				GF - 09/14/2009 - issue #131936
*
*
*	purpose - to copy existing Auto-use templates to new templates
*
*	inputs: 	Co
*				Old template
*				New Template
*				New Description
*
*
*	Output: ErrMsg
*
*
******************************************************************/
(@co bCompany, @template varchar(10), @newtemplate varchar(10), @description varchar(60), 
@inclequip varchar(1), @errmsg varchar(255) output)
  
as
set nocount on
  
declare @rcode int, @emuhud_flag bYN, @emucud_flag bYN, @emueud_flag bYN, 
@joins varchar(1000),@where varchar(1000)

select @rcode = 0, @emuhud_flag = 'N', @emucud_flag  = 'N', @emueud_flag ='N'

if @co is null
begin 
	select @errmsg = 'No company input provided.', @rcode = 1
	goto vspexit
end

if isnull(@template,'') = ''
begin 
	select @errmsg = 'No copy from template provided.', @rcode = 1
	goto vspexit
end

if isnull(@newtemplate,'') = ''
begin 
	select @errmsg = 'Must provide new template name.', @rcode = 1
	goto vspexit
end
  
if exists (select Top 1 1 from dbo.EMUH where EMCo = @co and AUTemplate = @newtemplate)
begin
	select @errmsg = 'Template already exists: ' + @newtemplate, @rcode = 1
	goto vspexit
end 
  
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.EMUH'))
Begin
	select @emuhud_flag = 'Y'
End

if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.EMUC'))
Begin
	select @emucud_flag = 'Y'
End

if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.EMUT'))
Begin
	select @emueud_flag = 'Y'
End

-- Copy header info
insert into dbo.EMUH(EMCo, AUTemplate, Description, Notes, UniqueAttchID)                        
select EMCo, @newtemplate, isnull(@description,Description), Notes, UniqueAttchID
from dbo.EMUH h with(nolock)
where h.EMCo = @co and h.AUTemplate = @template
IF @@rowcount >= 1 
	Begin
		if @emuhud_flag = 'Y'
		begin
			-- build joins and where clause
			select @joins = ' from EMUH with(nolock) inner join EMUH orig with(nolock)on orig.EMCo = ' + convert(varchar(3),@co) + ' and orig.AUTemplate = ' + CHAR(39) + @template + CHAR(39)
			select @where = ' where EMUH.EMCo = ' + convert(varchar(3),@co) + ' and EMUH.AUTemplate = ' + CHAR(39) + @newtemplate + CHAR(39)
			-- execute user memo update
			exec @rcode = dbo.vspEMCopyUserMemos 'EMUH', @joins, @where, @errmsg output
		end
	End
ELSE
	Begin
		select @errmsg = 'No Header info to copy.', @rcode = 1
		goto vspexit
	End



-- copy Category info
insert into dbo.EMUC(EMCo, AUTemplate, Category, RulesTable, PhaseGrp, JCPhase, MaxPerPD, MaxPerMonth, MaxPerJob, MinPerPd, DayStartTime,
			 DayStopTime, HrsPerDay, Br1StartTime, Br1StopTime, Br2StartTime, Br2StopTime, Br3StartTime, Br3StopTime, UniqueAttchID,BillingStartsOnTrnsfrInDateYN,UseEstDateOutYN)                        
select EMCo, @newtemplate, Category, RulesTable, PhaseGrp, JCPhase, MaxPerPD, MaxPerMonth, MaxPerJob, MinPerPd, DayStartTime,
			 DayStopTime, HrsPerDay, Br1StartTime, Br1StopTime, Br2StartTime, Br2StopTime, Br3StartTime, Br3StopTime, UniqueAttchID,BillingStartsOnTrnsfrInDateYN,UseEstDateOutYN
from dbo.EMUC c with(nolock) 
where c.EMCo = @co and c.AUTemplate = @template
IF @@rowcount >= 1 
	Begin
		if @emucud_flag = 'Y'
		begin
			-- build joins and where clause
			select @joins = ' from EMUC newrec with(nolock) inner join EMUC orig with(nolock)on orig.EMCo = ' + convert(varchar(3),@co) + ' and orig.AUTemplate = ' + CHAR(39) + @template + CHAR(39)
			select @where = ' where newrec.EMCo = ' + convert(varchar(3),@co) + ' and newrec.AUTemplate = ' + CHAR(39) + @newtemplate + CHAR(39)
			-- execute user memo update
			exec @rcode = dbo.vspEMCopyUserMemos 'EMUC', @joins, @where, @errmsg output
		end
	End
ELSE
	Begin
	if @inclequip <> 'Y'
		begin
		select @errmsg = 'No Category info to copy and option to copy equipment is unchecked.', @rcode = 1
		goto vspexit
		end
	End


if @inclequip = 'Y'
Begin
	insert into dbo.EMUE(EMCo, AUTemplate, Equipment, RulesTable, PhaseGrp, JCPhase, MaxPerPD, MaxPerMonth, MaxPerJob, MinPerPd, DayStartTime,
				 DayStopTime, HrsPerDay, Br1StartTime, Br1StopTime, Br2StartTime, Br2StopTime, Br3StartTime, Br3StopTime,BillingStartsOnTrnsfrInDateYN,UseEstDateOutYN)                        
	select EMCo, @newtemplate, Equipment, RulesTable, PhaseGrp, JCPhase, MaxPerPD, MaxPerMonth, MaxPerJob, MinPerPd, DayStartTime,
				 DayStopTime, HrsPerDay, Br1StartTime, Br1StopTime, Br2StartTime, Br2StopTime, Br3StartTime, Br3StopTime,BillingStartsOnTrnsfrInDateYN,UseEstDateOutYN
	from dbo.EMUE E with(nolock)
	where E.EMCo = @co and E.AUTemplate = @template
	IF @@rowcount >= 1 
	begin
		if @emueud_flag = 'Y'
		begin
			-- build joins and where clause
			select @joins = ' from EMUE newrec with(nolock) inner join EMUE orig with(nolock)on orig.EMCo = ' + convert(varchar(3),@co) + ' and orig.AUTemplate = ' + CHAR(39) + @template + CHAR(39)
			select @where = ' where newrec.EMCo = ' + convert(varchar(3),@co) + ' and newrec.AUTemplate = ' + CHAR(39) + @newtemplate + CHAR(39)
			-- execute user memo update
			exec @rcode = dbo.vspEMCopyUserMemos 'EMUE', @joins, @where, @errmsg output
		end
	end
End
  
vspexit:
if @rcode<>0 
	begin
		select @errmsg=isnull(@errmsg,'')
	end

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMAutoUseTempCopy] TO [public]
GO
