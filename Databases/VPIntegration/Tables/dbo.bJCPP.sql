CREATE TABLE [dbo].[bJCPP]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[ActualUnits] [dbo].[bUnits] NOT NULL,
[ProgressCmplt] [dbo].[bPct] NOT NULL,
[PRCo] [dbo].[bCompany] NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[CostTrans] [dbo].[bTrans] NULL,
[BatchSeq] [int] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btJCPPi    Script Date: 8/28/99 9:37:47 AM ******/
CREATE  trigger [dbo].[btJCPPi] on [dbo].[bJCPP] for INSERT as
/*-----------------------------------------------------------------
*	This trigger rejects insertion in bJCPP (Progress Entry Batch) if 
*	any of the following error conditions exist:
*
* 		Invalid Batch ID#
*		Batch associated with another source or table
*		Batch in use by someone else
*		Batch status not 'open'
*
*
*	use bsJCPPVal to fully validate all entries in a JCPP batch
*	prior to posting.
*
*				TV - 23061 added isnulls
*				mh - 6.x 124951
*				danf - 126412 fix select permission denied on bJCPP table by changing statement to use a view instead of table
*				GF	03/06/2008	-	issue #127346
*				GF	03/28/2008	-	issue #127626
*				GP	10/8/2008	-	Issue 130151, changed @currpct and @currprojpct from bPct to float.
*				Dan So 10/09/2008 - Issue 130179 - removed ABS functions on @currpct and @currprojpct
*				GF	04/10/2009	-	issue #133206 update ud fields using stored procedure
*				CHS	05/12/2009	-	issue #132559 update linked units when linked units = zero
*				GF 01/22/2009 - issue #137743 - not updating linked units correctly
*				GF 03/10/2010 - issue #138579 - remmed out ud insert for linked. May be a performance problem.
*				GF 12/15/2011 TK-10370 remmed out select @udcolumns that were causing connects to throw error when control loaded.
*				EN 01/23/2013 D-06543/#140311/TK-20910 include prco/crew info when post to linked cost types
*				EN 3/13/2013 43717/43718 fix for multiple insert error ... 2nd fetch for bJCPP_insert cursor missing @prco and @crew
*
*----------------------------------------------------------------*/
declare @batchid bBatchID, @batchseq int, @errmsg varchar(2500), @co bCompany,
   		@inuseby bVPUserName, @mth bMonth, @numrows int, @source bSource,
		@status tinyint, @tablename char(20), @phasegroup bGroup, @lastco bCompany,
		@lastmth bMonth, @lastbatchid int, @job bJob, @phase bPhase, @costtype bJCCType,
		@units bUnits, @pctcmplt bPct, @actualdate bDate, @currunits bUnits,
		@currprojunits bUnits, @currpct float, @currprojpct float, @linkestunits bUnits,
		@linkedunits bUnits, @linkprojunits bUnits, @opencursor int, @linkcosttype bJCCType, 
		@um bUM, @linkum bUM, @linkactive bYN, @prco bCompany, @crew varchar(10), @seq int,
		@linkedplugged varchar(1), @rcode int, @link_seq int, @udflag bYN,
		@sql nvarchar(max), @udvalues nvarchar(max), @udcolumn1 nvarchar(max),
		@udcolumn2 nvarchar(max)

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

set @udflag = 'N'
set @rcode = 0

---- get ud fields if any and set flag
select @udvalues = ISNULL(@udvalues,'') + COLUMN_NAME + ' = u.' + COLUMN_NAME + ', ',
		@udcolumn1 = isnull(@udcolumn1,'') + 'u.' + COLUMN_NAME + ', ',
		@udcolumn2 = isnull(@udcolumn2,'') + COLUMN_NAME + ', '
from INFORMATION_SCHEMA.COLUMNS 
where TABLE_NAME = 'bJCPP' AND COLUMN_NAME like 'ud%'
if isnull(@udvalues,'') <> ''
	begin
	select @udflag = 'Y'
	select @udvalues = substring(@udvalues, 1, len(@udvalues)-1)
	select @udcolumn1 = substring(@udcolumn1,1, len(@udcolumn1)-1)
	select @udcolumn2 = substring(@udcolumn2,1, len(@udcolumn2)-1)
	end

----TK-10370
--select @udcolumn1
--select @udcolumn2

---- cycle through inserted rows
if @numrows = 1
	begin
	select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @batchseq = i.BatchSeq,
			@phasegroup = h.PhaseGroup, @job = i.Job, @phase = i.Phase, @costtype = i.CostType, 
			@units = i.ActualUnits, @pctcmplt = i.ProgressCmplt, @actualdate = i.ActualDate,
			@prco = PRCo, @crew = Crew
	from inserted i join bHQCO h with (nolock) on i.Co = h.HQCo
	end
else
	begin
	declare bJCPP_insert cursor local fast_forward
	for select	i.Co, i.Mth, i.BatchId, i.BatchSeq, 
				h.PhaseGroup, i.Job, i.Phase, i.CostType,
				i.ActualUnits, i.ProgressCmplt, i.ActualDate,
				i.PRCo, i.Crew
	from inserted i join bHQCO h with (nolock) on i.Co = h.HQCo

	open bJCPP_insert

	fetch next from bJCPP_insert into @co, @mth, @batchid, @batchseq, 
				@phasegroup, @job, @phase, @costtype, @units, @pctcmplt, @actualdate,
				@prco, @crew
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
	end


insert_check:

select @source = Source, @tablename = TableName, @inuseby = InUseBy, @status = Status 
from bHQBC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0 
	begin
	select @errmsg = 'Invalid Batch ID#'
	goto error
	end

if @source <> 'JC Progres'
	begin
	select @errmsg = 'Batch associated with another source'
	goto error
	end

if @tablename <> 'JCPP'
	begin
	select @errmsg = 'Batch associated with another table'
	goto error
	end

if @inuseby is null
	begin
	select @errmsg = 'Batch (In Use) name must first be updated'
	goto error
	end

if @inuseby <> SUSER_SNAME()
	begin
	select @errmsg = 'Batch already in use by ' + isnull(@inuseby,'')
	goto error
	end

if @status <> 0
	begin
	select @errmsg = 'Must be an open batch'
	goto error
	end

if @phasegroup is null
	begin
	select @errmsg = 'Missing Phase Group in Head Quarters.'
	goto error
	end

if not exists (select top 1 1 from bJCJM with (nolock) where JCCo=@co and Job=@job)
	begin
	select @errmsg = @job + ' Job not in Job Master!'
	goto error
	end

if not exists (select top 1 1 from bHQGP with (nolock) where Grp=@phasegroup)
	begin
	select @errmsg = convert(varchar(3),@phasegroup) + ' Phase Group not in HQGP!'
	goto error
	end
    

if not exists (select top 1 1 from bJCJP with (nolock) where JCCo=@co and Job=@job 
 			and PhaseGroup=@phasegroup and Phase=@phase)
  	begin
  	select @errmsg = @phase + ' Phase not in Phase Master!'
  	goto error
  	end

/* insert link progress cost types if they do not exist */
/* This is for any imports or from the Progress Form where*/
/* the user has not overriden the links estabished in the */
/* Cost Type master.*/
if @co <> isnull(@lastco,0) or @mth <> isnull(@lastmth,'') or @batchid <> isnull(@lastbatchid,0)
	begin
	exec dbo.vspJCProgressLinkCostTypes @co, @phasegroup, @mth, @batchid
	select @lastco=@co, @lastmth=@mth, @lastbatchid=@batchid
	end

---- if no linked cost types exist. Done
if not exists(select 1 from dbo.bJCPPCostTypes with (nolock) where Co = @co and Mth = @mth
		and BatchId = @batchid and PhaseGroup=@phasegroup and LinkProgress=@costtype)
	begin
	goto nextProgress
	end

---- get current completed units for phase/cost type -- tech calls #1452635 issue #137743
select @currunits=isnull(sum(d.EstUnits),0), @currprojunits=isnull(sum(d.ProjUnits),0),@um=h.UM
from bJCCH h with (nolock)
left join bJCCD d with (nolock) on h.JCCo=d.JCCo and h.Job=d.Job and h.PhaseGroup=d.PhaseGroup 
and h.Phase=d.Phase and h.CostType=d.CostType and d.ActualDate <= @actualdate
where h.JCCo=@co and h.Job=@job and h.PhaseGroup=@phasegroup and h.Phase=@phase and h.CostType=@costtype
--group by d.EstUnits, d.ProjUnits, d.UM
group by h.UM



----Issue 124951 Arithmetic overflow dividing units/currunits and stuffing into currpct
 if @currunits = 0
	begin
	set @currpct = 0
	end
 else
	begin
	if abs(@units/@currunits) <= 99.9999
	-- Issue 130179 --
	--  set @currpct = abs(@units/@currunits)
		set @currpct = (@units/@currunits)
	else
		set @currpct = 99.9999
	end
    
if @currprojunits = 0
	begin
	set @currprojpct = 0
	end
else
	begin
	if abs(@units/@currprojunits) <= 99.9999
	-- Issue 130179 --
	--	set @currprojpct = abs(@units/@currprojunits)
		set @currprojpct = (@units/@currprojunits)
	else
		set @currprojpct = 99.9999
	end


---- declare cursor on bJCCT for linked cost types
declare bcJCCT cursor LOCAL FAST_FORWARD for select CostType
from dbo.bJCPPCostTypes
where Co = @co and Mth = @mth and BatchId = @batchid and PhaseGroup=@phasegroup and LinkProgress=@costtype

---- open bJCCT cursor
open bcJCCT
select @opencursor = 1

---- process through all entries in batch
JCCT_loop:
fetch next from bcJCCT into @linkcosttype

if @@fetch_status = -1 goto JCCT_end
if @@fetch_status <> 0 goto JCCT_loop

---- get needed date form bJCCH and bJCCD to create/update bJCPP batch record
select @linkum=h.UM, @linkactive=h.ActiveYN, @linkedplugged = h.Plugged,
		@linkestunits=isnull(sum(d.EstUnits),0),
		@linkprojunits=isnull(sum(d.ProjUnits),0)
from bJCCH h with (nolock)
left join bJCCD d with (nolock) on h.JCCo=d.JCCo and h.Job=d.Job and h.PhaseGroup=d.PhaseGroup 
and h.Phase=d.Phase and h.CostType=d.CostType and d.ActualDate <= @actualdate
where h.JCCo=@co and h.Job=@job and h.PhaseGroup=@phasegroup and h.Phase=@phase and h.CostType=@linkcosttype
Group by h.UM, h.ActiveYN, h.Plugged

---- per carol, if linked cost type is not set up in JCCH then skip it.
if @@rowcount=0 goto JCCT_loop

---- do not insert linked cost type if JCCH.ActiveYN flag is 'N'
if @linkactive = 'N' goto JCCT_loop

---- if linked cost type um = 'LS' and no estimate units skip
if @linkum = 'LS' and @linkestunits = 0 goto JCCT_loop

---- set linkedunits based on @linkedplugged flag
select @linkedunits = case @linkedplugged when 'N' then (@linkestunits*@currpct) else (@linkprojunits*@currprojpct) end

---- #132559 update linked units equal @units when linked units equal zero
---- and units of measure match
if (@linkedunits = 0 and @um = @linkum) select @linkedunits = @units


-- update/add linked cost types
---- remmed out per issue #127626
----if @um <> @linkum
----begin
---- select @linkedunits = case Plugged when 'N' then (@linkestunits*@pctcmplt) else (@linkprojunits*@pctcmplt) end
----select @linkedunits = case Plugged when 'N' then (@linkestunits*@currpct) else (@linkprojunits*@currprojpct) end
----from bJCCH with (nolock)
----where JCCo=@co and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@linkcosttype

---- update or insert progress for linked cost type into JCPP
if exists(select top 1 1 from bJCPP with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid
			and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@linkcosttype
			and isnull(PRCo,0) = isnull(@prco,0) and isnull(Crew,'') = isnull(@crew,''))
	begin
	update bJCPP set UM=@linkum, ActualUnits=@linkedunits, ProgressCmplt=@pctcmplt, PRCo=@prco, Crew=@crew
	where Co=@co and Mth=@mth and BatchId=@batchid and Job=@job and PhaseGroup=@phasegroup
	and Phase=@phase and CostType=@linkcosttype
	and isnull(PRCo,0) = isnull(@prco,0) and isnull(Crew,'') = isnull(@crew,'')
	end
else
	begin
	---- #138579
	---- insert row into JCPP
	--if isnull(@udflag,'N') <> 'Y'
	--	begin
		insert bJCPP (Co, Mth, BatchId, Job, PhaseGroup, Phase, CostType, UM,
				ActualUnits, ProgressCmplt, PRCo, Crew, ActualDate, BatchSeq)
		select @co, @mth, @batchid, @job, @phasegroup, @phase, @linkcosttype, @linkum,
				@linkedunits, @pctcmplt, @prco, @crew, @actualdate,
				isnull(max(j.BatchSeq),0) + 1
		from bJCPP j with (nolock) where j.Co=@co and j.Mth=@mth and j.BatchId=@batchid
		--goto JCCT_loop
	--	end
	--else
	--	begin
	--	---- insert section
	--	select @sql = 'insert bJCPP (Co, Mth, BatchId, Job, PhaseGroup, Phase, CostType, ' +
	--				  'UM, ActualUnits, ProgressCmplt, PRCo, Crew, ActualDate, BatchSeq, ' +
	--					@udcolumn2 + ') '

	--	---- select section
	--	select @sql = @sql + 'select ' + convert(varchar(3),@co) + ', ' +
	--					char(39) + isnull(convert(varchar(30),@mth,101),'') + char(39) + ', ' +
	--					----char(39) + @mth + char(39) + ', ' +
	--					convert(varchar(8),@batchid) + ', ' +
	--					char(39) + @job + char(39) + ', ' +
	--					convert(varchar(3),@phasegroup) + ', ' +
	--					char(39) + @phase + char(39) + ', ' +
	--					convert(varchar(3),@linkcosttype) + ', ' +
	--					char(39) + @linkum + char(39) + ', ' +
	--					convert(varchar(20),@linkedunits) + ', ' +
	--					convert(varchar(20),@pctcmplt) + ', ' +
	--					'u.PRCo, u.Crew, ' + 
	--					char(39) + isnull(convert(varchar(30),@actualdate,101),'') + char(39) + ', ' +
	--					convert(varchar(10),@link_seq) + ', ' + @udcolumn1 + ' '
						

	--	---- from, join, where section
	--	select @sql = @sql + 'from bJCPP p with (nolock) ' +
	--					'join bJCPP u with (nolock) on p.Co=u.Co and p.Mth=u.Mth and p.BatchId=u.BatchId ' +
	--					'and u.BatchSeq = ' + isnull(convert(varchar(10),@batchseq),'') + ' ' +
	--					'where p.Co= ' + isnull(convert(varchar(3),@co),'') +
	--					' and p.Mth= ' + CHAR(39) + isnull(convert(varchar(30),@mth,101),'') + CHAR(39) +
	--					' and p.BatchId= ' + isnull(convert(varchar(10),@batchid),'') +
	--					' and p.BatchSeq= ' + isnull(convert(varchar(10),@batchseq),'')

	--	exec @rcode = dbo.vspJCPPudUpdate @sql
	--	goto JCCT_loop
	--	end
	---- #138579
	end


---- update user memos
if @udflag = 'Y'
	begin
	set @sql = 'update p set ' + isnull(@udvalues,'')
	set @sql = @sql + ' from bJCPP p ' +
			' join bJCPP u with (nolock) ' +
			' on p.Co = u.Co and p.Mth = u.Mth and p.BatchId = u.BatchId and u.BatchSeq = ' + isnull(convert(varchar(10),@batchseq),'') +
			' where p.Co=' + isnull(convert(varchar(3),@co),'') +
			' and p.Mth=' + CHAR(39) + isnull(convert(varchar(30),@mth,101),'') + CHAR(39) +
			' and p.BatchId=' + isnull(convert(varchar(10),@batchid),'') +
			' and p.Job=' + CHAR(39) + isnull(@job,'') + CHAR(39) +
			' and p.PhaseGroup=' + isnull(convert(varchar(3),@phasegroup),'') +
			' and p.Phase=' + CHAR(39) + isnull(@phase,'') + CHAR(39) +
			' and p.CostType=' + isnull(convert(varchar(3),@linkcosttype),'') +
			' and isnull(p.PRCo,0)= isnull(' + isnull(convert(varchar(3),@prco),0) + ',0)' +
			' and isnull(p.Crew,'+ CHAR(39) + CHAR(39) +')= isnull(' + isnull(@crew,'''''') + ','+ CHAR(39) + CHAR(39) + ')'

	exec @rcode = dbo.vspJCPPudUpdate @sql
--	exec (@sql)
	end



goto JCCT_loop


JCCT_end:
  	if @opencursor = 1
  		begin
  		close bcJCCT
  		deallocate bcJCCT
  		set @opencursor = 0
  		end


nextProgress:
	if @numrows > 1
		begin
		fetch next from bJCPP_insert 
		into @co, @mth, @batchid, @batchseq, 
		@phasegroup, @job, @phase, @costtype, 
		@units, @pctcmplt, @actualdate,
		@prco, @crew

		if @@fetch_status = 0 goto insert_check

		close bJCPP_insert
		deallocate bJCPP_insert
		end


---- add entry to HQ Close Control as needed
insert bHQCC(Co, Mth, BatchId, GLCo)
select JCPB.Co, JCPB.Mth, JCPB.BatchId, JCCO.GLCo 
from inserted JCPB with (nolock)
join bJCCO JCCO with (nolock) on JCCO.JCCo = JCPB.Co
left join bHQCC HQCC with (nolock)
on HQCC.Co = JCPB.Co and HQCC.Mth = JCPB.Mth and HQCC.BatchId = JCPB.BatchId and HQCC.GLCo = JCCO.GLCo
where HQCC.BatchId is null
group by JCPB.Co, JCPB.Mth, JCPB.BatchId, JCCO.GLCo 




return


error:
	select @errmsg = '' + @errmsg + ' - cannot insert JC Progress Entry Batch entry!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJCPPu    Script Date: 8/28/99 9:37:48 AM ******/
CREATE trigger [dbo].[btJCPPu] on [dbo].[bJCPP] for UPDATE as 
/*-------------------------------------------------------------- 
* Update trigger for JCPP
* Created By: 
* Modified By:	danf - 126412 fix select permission denied on bJCPP table by changing statement to use a view instead of table    
*				GF	03/06/2008	-	issue #127346
*				GF	03/28/2008	-	issue #127626
*				GP	10/8/2008	-	Issue 130151, changed @currpct and @currprojpct from bPct to float.
*				Dan So 10/09/2008 - Issue 130179 - removed ABS functions on @currpct and @currprojpct
*				GF	04/10/2009	-	issue #133206 update ud fields using stored procedure
*				CHS	05/12/2009	-	issue #132559 update linked units when linked units = zero
*				GF 01/22/2009 - issue #137743 - not updating linked units correctly
*
*--------------------------------------------------------------*/
declare @batchid bBatchID, @batchseq int, @errmsg varchar(255), @co bCompany,
		@inuseby bVPUserName, @mth bMonth, @numrows int, 
		@source bSource, @status tinyint, @tablename char(20), 
		@phasegroup bGroup, @lastco bCompany,@lastmth bMonth,
		@lastbatchid int, @job bJob, @phase bPhase, @costtype bJCCType,
		@units bUnits, @pctcmplt bPct, @actualdate bDate,
		@currunits bUnits, @currprojunits bUnits, @currpct float, @currprojpct float,
		@linkestunits bUnits, @linkedunits bUnits, @linkprojunits bUnits, 
		@opencursor int, @linkcosttype bJCCType,  @um bUM, @linkum bUM, @linkactive bYN,
		@sql nvarchar(max), @udflag bYN, @udvalues nvarchar(max),
		@seq int, @prco bCompany, @crew varchar(10), @oldprco bCompany, @oldcrew varchar(10),	
		@changecount int, @costtrans bTrans, @q char(2), @rcode int

 select @numrows = @@rowcount
   set @udflag = 'N'
   set nocount on
   if @numrows = 0 return

set @rcode = 0

  /* check for changes to Co */
   if update(Co)
      begin
      select @errmsg = 'Cannot change Co'
      goto error
      end
   
   /* check for changes to Mth */
   if update(Mth)
      begin
      select @errmsg = 'Cannot change Mth'
      goto error
      end
   
   
   /* check for changes to BatchId */
   if update(BatchId)
      begin
      select @errmsg = 'Cannot change BatchId'
      goto error
      end
   
   /* check for changes to BatchId */
   if update(BatchSeq)
      begin
      select @errmsg = 'Cannot change BatchSeq'
      goto error
      end

   /* check for changes to Job */
   if update(Job)
      begin
		set @changecount = 0
		select @changecount from inserted i
		join deleted d on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
		where isnull(i.Job,'') <> isnull(d.Job,'')

		if isnull(@changecount,0) <> 0 
			begin
				  select @errmsg = 'Cannot change Job'
				  goto error
			end
      end 
   
   /* check for changes to PhaseGroup */
   if update(PhaseGroup)
      begin
		set @changecount = 0
		select @changecount from inserted i
		join deleted d on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
		where isnull(i.PhaseGroup,'') <> isnull(d.PhaseGroup,'')

		if isnull(@changecount,0) <> 0 
			begin
			  select @errmsg = 'Cannot change PhaseGroup'
			  goto error
			end
      end 
   
   /* check for changes to Phase */
   if update(Phase)
      begin
		set @changecount = 0
		select @changecount from inserted i
		join deleted d on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
		where isnull(i.Phase,'') <> isnull(d.Phase,'')

		if isnull(@changecount,0) <> 0 
			begin
			  select @errmsg = 'Cannot change Phase'
			  goto error
			end
      end
   
   /* check for changes to CostType */
   if update(CostType)
      begin
		set @changecount = 0
		select @changecount from inserted i
		join deleted d on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
		where isnull(i.Phase,'') <> isnull(d.Phase,'')

		if isnull(@changecount,0) <> 0 
			begin
			  select @errmsg = 'Cannot change CostType'
			  goto error
			end
      end 

	select @q = CHAR(39) + CHAR(39)

	select @udvalues = ISNULL(@udvalues,'') + COLUMN_NAME + ' = u.' + COLUMN_NAME + ', '
	from INFORMATION_SCHEMA.COLUMNS 
	where TABLE_NAME = 'bJCPP' AND COLUMN_NAME like 'ud%'

	if isnull(@udvalues,'')<> '' 
		select @udvalues = substring(@udvalues,1, len(@udvalues)-1), @udflag = 'Y'


    if @numrows = 1
   	select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @batchseq = i.BatchSeq, @phasegroup = h.PhaseGroup, 
		   @job = i.Job, @phase = i.Phase, @costtype = i.CostType, 
			@units = i.ActualUnits, @pctcmplt = i.ProgressCmplt, @actualdate = i.ActualDate,
			@prco = i.PRCo, @crew = i.Crew, @oldprco = d.PRCo, @oldcrew = d.Crew, @costtrans = i.CostTrans
   	from inserted i
	join deleted d on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId and i.BatchSeq = d.BatchSeq
	join HQCO h with (nolock) on i.Co = h.HQCo
   else
   	begin
   	declare bJCPP_insert cursor local fast_forward
   	for select	i.Co, i.Mth, i.BatchId, i.BatchSeq, 
				h.PhaseGroup, i.Job, i.Phase, i.CostType,
				i.ActualUnits, i.ProgressCmplt, i.ActualDate,
				i.PRCo, i.Crew, d.PRCo, d.Crew, i.CostTrans
   	from inserted i
    join deleted d on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId and i.BatchSeq = d.BatchSeq 
	join HQCO h with (nolock) on i.Co = h.HQCo
   
   	open bJCPP_insert
   
   	fetch next 
	from bJCPP_insert 
	into @co, @mth, @batchid, @batchseq, 
		@phasegroup, @job, @phase, @costtype, 
		@units, @pctcmplt, @actualdate,
		@prco, @crew, @oldprco, @oldcrew, @costtrans
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
	-- If updating a record with a cost transction exit updating or adding links.
	if isnull(@costtrans,-1) <> -1 goto JCCT_end

	-- -- #25131 check for existance of progress record for old prco and crew
   if isnull(@oldprco,0) <> isnull(@prco,0) or isnull(@oldcrew,'') <> isnull(@crew,'')
   	begin
    
   		-- check for linked cost types
   		if exists(select top 1 1 
					from dbo.bJCPPCostTypes with (nolock) 
					where Co = @co and Mth = @mth and BatchId = @batchid and PhaseGroup=@phasegroup and LinkProgress=@costtype)
   			begin
   			-- declare cursor on bJCCT for linked cost types
   			declare bcJCCT cursor LOCAL FAST_FORWARD for select CostType
   			from dbo.bJCPPCostTypes where Co = @co and Mth = @mth and BatchId = @batchid and PhaseGroup=@phasegroup and LinkProgress=@costtype
    
   			-- open bJCCT cursor
   			open bcJCCT
   			select @opencursor = 1
   			-- process through all entries in batch
   			OLD_JCCT_loop:
   			fetch next from bcJCCT into @linkcosttype
   			if @@fetch_status = -1 goto OLD_JCCT_end
   			if @@fetch_status <> 0 goto OLD_JCCT_loop
    
   			-- update linked cost type in bJCPP
   			update bJCPP set PRCo=@prco, Crew=@crew
   			where Co=@co and Mth=@mth and BatchId=@batchid and Job=@job 
   			and PhaseGroup=@phasegroup and Phase=@phase and CostType=@linkcosttype
   			and isnull(PRCo,0) = isnull(@oldprco,0) and isnull(Crew,'') = isnull(@oldcrew,'')
    				
   			goto OLD_JCCT_loop
    
   			OLD_JCCT_end:
   				if @opencursor = 1
   					begin
   					close bcJCCT
   					deallocate bcJCCT
   					set @opencursor = 0
   					end
   			end
   	end
   
   
  
     -- if no linked cost types exist. Done
     if not exists(select top 1 1 
					from dbo.bJCPPCostTypes with (nolock) 
					where Co = @co and Mth = @mth and BatchId = @batchid and PhaseGroup=@phasegroup and LinkProgress=@costtype)
      	goto bspexit


---- get current completed units for phase/cost type -- tech calls #1452635 issue #137743
select @currunits=isnull(sum(d.EstUnits),0), @currprojunits=isnull(sum(d.ProjUnits),0),@um=h.UM
from bJCCH h with (nolock)
left join bJCCD d with (nolock) on h.JCCo=d.JCCo and h.Job=d.Job and h.PhaseGroup=d.PhaseGroup 
and h.Phase=d.Phase and h.CostType=d.CostType and d.ActualDate <= @actualdate
where h.JCCo=@co and h.Job=@job and h.PhaseGroup=@phasegroup and h.Phase=@phase and h.CostType=@costtype
--group by d.EstUnits, d.ProjUnits, d.UM
group by h.UM



	if @currunits = 0
		begin
		set @currpct = 0
		end
	else
		begin
		if abs(@units/@currunits) <= 99.9999
			begin
			-- Issue 130179 --
			-- set @currpct = abs(@units/@currunits)
			set @currpct = (@units/@currunits)
			end
		else
			begin
			set @currpct = 99.9999
			end
		end

	if @currprojunits = 0
		begin
		set @currprojpct = 0
		end
	else
		begin
		if abs(@units/@currprojunits) <=99.9999
			begin
			-- Issue 130179 --
			-- set @currprojpct = abs(@units/@currprojunits)
			set @currprojpct = (@units/@currprojunits)
			end
		else
			begin
			set @currprojpct = 99.9999
			end
		end

     -- declare cursor on bJCCT for linked cost types
     declare bcJCCT cursor LOCAL FAST_FORWARD for select CostType
     from dbo.bJCPPCostTypes
     where Co = @co and Mth = @mth and BatchId = @batchid and PhaseGroup=@phasegroup and LinkProgress=@costtype
    
     -- open bJCCT cursor
     open bcJCCT
     select @opencursor = 1
       
     -- process through all entries in batch
     JCCT_loop:
     fetch next from bcJCCT into @linkcosttype
      
     if @@fetch_status = -1 goto JCCT_end
     if @@fetch_status <> 0 goto JCCT_loop
      
      -- get needed date form bJCCH and bJCCD to create/update bJCPP batch record
      select @linkum=h.UM, @linkactive=h.ActiveYN, 
      	   @linkestunits=isnull(sum(d.EstUnits),0), @linkprojunits=isnull(sum(d.ProjUnits),0)
      from bJCCH h with (nolock)
      left join bJCCD d with (nolock) on h.JCCo=d.JCCo and h.Job=d.Job and h.PhaseGroup=d.PhaseGroup 
      and h.Phase=d.Phase and h.CostType=d.CostType and d.ActualDate <= @actualdate
      where h.JCCo=@co and h.Job=@job and h.PhaseGroup=@phasegroup and h.Phase=@phase and h.CostType=@linkcosttype
      Group by h.UM, h.ActiveYN
      
      -- per carol, if linked cost type is not set up in JCCH then skip it.
      if @@rowcount=0 goto JCCT_loop
      
      -- do not insert linked cost type if JCCH.ActiveYN flag is 'N'
      if @linkactive = 'N' goto JCCT_loop
     
      -- if linked cost type um = 'LS' and no estimate units skip
      if @linkum = 'LS' and @linkestunits = 0 goto JCCT_loop
      
-- update/add linked cost types
---- remmed out per issue #127626
----if @um <> @linkum
----	begin
	------ select @linkedunits = case Plugged when 'N' then (@linkestunits*@pctcmplt) else (@linkprojunits*@pctcmplt) end
	select @linkedunits = case Plugged when 'N' then (@linkestunits*@currpct) else (@linkprojunits*@currprojpct) end
	from bJCCH with (nolock)
	where JCCo=@co and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@linkcosttype
----	end
----else
----	begin
----	select @linkedunits = @units
----	end


---- #132559 update linked units equal @units when linked units equal zero
---- and units of measure match
if (@linkedunits = 0 and @um = @linkum) select @linkedunits = @units


     -- update or insert progress for linked cost type into JCPP
     update bJCPP set UM=@linkum, ActualUnits=@linkedunits, ProgressCmplt=@pctcmplt, PRCo=@prco, Crew=@crew
     where Co=@co and Mth=@mth and BatchId=@batchid and Job=@job and PhaseGroup=@phasegroup
     and Phase=@phase and CostType=@linkcosttype
     and isnull(PRCo,0) = isnull(@prco,0) and isnull(Crew,'') = isnull(@crew,'')
     if @@rowcount = 0
      	begin
		----select @seq = isnull(@seq,@batchseq) + 1
      	insert dbo.bJCPP (Co, Mth, BatchId, Job, PhaseGroup, Phase, CostType, 
      			UM, ActualUnits, ProgressCmplt, PRCo, Crew, ActualDate, BatchSeq)
      	select @co, @mth, @batchid, @job, @phasegroup, @phase, @linkcosttype, 
      			@linkum, @linkedunits, @pctcmplt, @prco, @crew, @actualdate, isnull(max(p.BatchSeq),0) + 1
      	from dbo.bJCPP p where Co=@co and Mth=@mth and BatchId=@batchid
      	end
     

-- update user memos
if @udflag = 'Y'
	begin
	set @sql = 'update p set ' + isnull(@udvalues,'')
	set @sql = @sql + ' from bJCPP p ' +
			' join bJCPP u with (nolock) ' +
			' on p.Co = u.Co and p.Mth = u.Mth and p.BatchId = u.BatchId and u.BatchSeq = ' + isnull(convert(varchar(10),@batchseq),'') +
			' where p.Co=' + isnull(convert(varchar(3),@co),'') +
			' and p.Mth=' + CHAR(39) + isnull(convert(varchar(30),@mth,101),'') + CHAR(39) +
			' and p.BatchId=' + isnull(convert(varchar(10),@batchid),'') +
			' and p.Job=' + CHAR(39) + isnull(@job,'') + CHAR(39) +
			' and p.PhaseGroup=' + isnull(convert(varchar(3),@phasegroup),'') +
			' and p.Phase=' + CHAR(39) + isnull(@phase,'') + CHAR(39) +
			' and p.CostType=' + isnull(convert(varchar(3),@linkcosttype),'') +
			' and isnull(p.PRCo,0)= isnull(' + isnull(convert(varchar(3),@prco),0) + ',0)' +
			' and isnull(p.Crew,'+ CHAR(39) + CHAR(39) +')= isnull(' + isnull(@crew,@q) + ','+ CHAR(39) + CHAR(39) + ')'

	exec @rcode = dbo.vspJCPPudUpdate @sql
----	exec (@sql)
	end

   
   
   
   goto JCCT_loop
   
   
   JCCT_end:
      	if @opencursor = 1
      		begin
      		close bcJCCT
      		deallocate bcJCCT
      		set @opencursor = 0
      		end
   
   
 
   
   bspexit:
      	if @opencursor = 1
      		begin
      		close bcJCCT
      		deallocate bcJCCT
      		set @opencursor = 0
      		end
      
   
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update JC Progress Entry Batch entry!'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 






GO
ALTER TABLE [dbo].[bJCPP] ADD CONSTRAINT [PK_bJCPP] PRIMARY KEY CLUSTERED  ([Co], [Mth], [BatchId], [BatchSeq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biJCPP] ON [dbo].[bJCPP] ([Co], [Mth], [BatchId], [Job], [PhaseGroup], [Phase], [CostType], [PRCo], [Crew]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCPP] ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_dta_index_bJCPP_52_1284199625__K5_K1_K4_K6_K7_K13_K2_K3_K15] ON [dbo].[bJCPP] ([PhaseGroup], [Co], [Job], [Phase], [CostType], [ActualDate], [Mth], [BatchId], [BatchSeq]) ON [PRIMARY]
GO
