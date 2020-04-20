SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************************************************/
CREATE  proc [dbo].[bspJCProjDetailGridFill]
/****************************************************************************
* Created By:	GF 08/16/2004
* Modified By:	DANF 06/22/06 6.x
*				GF 07/03/2008 - issue #128880 change to join clause for PRCC, included craft
*				GF 10/16/2008 - issue #130583 change case statement when joining attachment from AP
*				GF 09/29/2009 - issue #135576 change case statement when joining attachment id from SL or PO.
*				GF 10/05/2009 - issue #134080 added PO, SL to descriptions.
*				GF 11/30/2009 - issue #136634 - added viewname and keyid to dynamic sql 
*				GF 06/16/2010 - issue #140220 - need to wrap descriptions with isnull
*
*
*
* USAGE:
* 	returns resultset of JC Projection Cost Detail rows to JCProjDetail form to populate grid.
*
*
* INPUT PARAMETERS:
*	JCCo, Job, PhaseGroup, Phase, CostType, BegMonth, EndMonth, ActualUnits, CostOption
*
*****************************************************************************/
(@jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @costtypein varchar(3),
 @begmonth bMonth, @endmonth bMonth, @actualunits bYN, @costoption varchar(1),
 @orderby varchar(100))
as

declare @costtype bJCCType, @sql nvarchar(4000), @where varchar(2000), @paramsin nvarchar(200)


if isnull(@orderby,'') = '' set @orderby = ' order by  l.CostType asc, l.Mth asc, l.CostTrans asc'
if @actualunits is null set @actualunits = 'N'
if @costoption is null set @costoption = 'A'
if isnull(@begmonth,'') = '' set @begmonth = null
if isnull(@endmonth,'') = '' set @endmonth = null

if isnull(@costtypein,'') = '' 
	begin
	set @costtype = null
	end
else
	begin
	set @costtype = convert(tinyint,@costtypein)
	end

---- check order by to see if ascending
if patindex('%asc%', @orderby) > 0
	begin
	---- if l.Mth not in order by add
	if patindex('%l.Mth%', @orderby) = 0
		begin
		select @orderby = @orderby + ', l.Mth asc'
		end
	---- if l.CostTrans not in order by add
	if patindex('%l.CostTrans%', @orderby) = 0
		begin
		select @orderby = @orderby + ', l.CostTrans asc'
		end
	end

---- check order by to see if descending
if patindex('%desc%', @orderby) > 0
	begin
	---- if l.Mth not in order by add
	if patindex('%l.Mth%', @orderby) = 0
		begin
		select @orderby = @orderby + ', l.Mth desc'
		end
	---- if l.CostTrans not in order by add
	if patindex('%l.CostTrans%', @orderby) = 0
		begin
		select @orderby = @orderby + ', l.CostTrans desc'
		end
	end

---- build where clause
select @where = ' from JCCD as l with (nolock)'
select @where = @where + ' left join APVM APVM with (nolock) ON APVM.VendorGroup=l.VendorGroup and APVM.Vendor=l.Vendor '
select @where = @where + ' left join APTH APTH with (nolock) ON APTH.APCo=l.APCo and APTH.Mth=l.Mth and APTH.APTrans=l.APTrans'
select @where = @where + ' left join APTL APTL with (nolock) ON APTL.APCo=l.APCo and APTL.Mth=l.Mth and APTL.APTrans=l.APTrans and APTL.APLine=l.APLine'
select @where = @where + ' left join EMEM EMEM with (nolock) ON EMEM.EMCo=l.EMCo and EMEM.Equipment=l.EMEquip'
select @where = @where + ' left join EMRC EMRC with (nolock) ON EMRC.EMGroup=l.EMGroup and EMRC.RevCode=l.EMRevCode'
select @where = @where + ' left join EMRD EMRD with (nolock) ON EMRD.EMCo=l.EMCo and EMRD.Trans=l.EMTrans and EMRD.Mth=l.Mth'
select @where = @where + ' left join POHD POHD with (nolock) ON POHD.POCo=l.APCo and POHD.PO=l.PO'
select @where = @where + ' left join POIT POIT with (nolock) ON POIT.POCo=l.APCo and POIT.PO=l.PO and POIT.POItem=l.POItem'
select @where = @where + ' left join PREH PREH with (nolock) ON PREH.PRCo=l.PRCo and PREH.Employee=l.Employee'
select @where = @where + ' left join PRCM PRCM with (nolock) ON PRCM.PRCo=l.PRCo and PRCM.Craft=l.Craft'
select @where = @where + ' left join PRCC PRCC with (nolock) ON PRCC.PRCo=l.PRCo and PRCC.Class=l.Class and PRCC.Craft=l.Craft'
select @where = @where + ' left join PRCR PRCR with (nolock) ON PRCR.PRCo=l.PRCo and PRCR.Crew=l.Crew'
select @where = @where + ' left join SLHD SLHD with (nolock) ON SLHD.SLCo=l.APCo and SLHD.SL=l.SL'
select @where = @where + ' left join SLIT SLIT with (nolock) ON SLIT.SLCo=l.APCo and SLIT.SL=l.SL and SLIT.SLItem=l.SLItem'

---- if @costoption =  select @where = @where + ' left join APTH h with (nolock) on h.APCo=l.APCo and h.Mth=l.Mth and h.APTrans=l.APTrans'
select @where = @where + ' where l.JCCo= ' + convert(varchar(3),@jcco)
select @where = @where + ' and l.Job= ' + CHAR(39) + @job + CHAR(39) + ' and l.PhaseGroup= ' + convert(varchar(3),@phasegroup)
select @where = @where + ' and l.Phase= ' +CHAR(39) + @phase + CHAR(39)
select @where = @where + ' and l.Mth between ' + char(39) + isnull(convert(varchar(30), @begmonth, 101),'01/01/1950') + CHAR(39) 
select @where = @where + ' and ' + char(39) + isnull(convert(varchar(30), @endmonth, 101),'12/01/2030') + CHAR(39)
select @where = @where + ' and l.CostType= ' + isnull(convert(varchar(20), @costtype), 'l.CostType')
if @costoption = 'A' and @actualunits = 'N' select @where = @where + ' and (l.ActualUnits <> 0 or l.ActualHours <> 0 or l.ActualCost <> 0)'
if @costoption = 'A' and @actualunits = 'Y' select @where = @where + ' and l.ActualUnits <> 0'
if @costoption = 'C' select @where = @where + ' and (l.TotalCmtdUnits<>0 or l.TotalCmtdCost<>0 or l.RemainCmtdUnits<>0 or l.RemainCmtdCost<>0)'
if @costoption = 'E' select @where = @where + ' and (l.EstUnits<>0 or l.EstHours<>0 or l.EstCost<>0)'
if @costoption = 'P' select @where = @where + ' and (l.ProjUnits<>0 or l.ProjHours<>0 or l.ProjCost<>0)'
select @where = @where + @orderby

select @sql = 'select l.CostType, l.Source, l.Mth, l.CostTrans, l.PostedDate, l.ActualDate, l.JCTransType, l.Description,
		l.GLCo, l.GLTransAcct, l.GLOffsetAcct, l.ReversalStatus, l.UM, l.ActualUnits, l.ActualHours,
		isnull(l.ActualUnitCost,0) as '+ char(39) + 'ActualUnitCost' + char(39) + ', isnull( l.PerECM,' + char(39) + 'E' + char(39) + ') as ' + char(39) + 'PerECM' + char(39) + ', l.ActualCost, l.ProgressCmplt, l.EstUnits, l.EstHours,
		l.EstCost, l.ProjUnits, l.ProjHours, l.ProjCost, l.ForecastUnits, l.ForecastHours, l.ForecastCost,
		l.TotalCmtdUnits, l.TotalCmtdCost, l.RemainCmtdUnits, l.RemainCmtdCost'

	
---- issue #135576 - #136634
if @costoption in ('A','C')
	begin
	---- unique attach id
	select @sql = @sql + ', UniqueAttchID = case' +
						 ' when l.Source = ' + char(39) + 'AP Entry' + char(39) + ' then APTH.UniqueAttchID' +
						 ' when l.Source = ' + char(39) + 'PM Intface' + char(39) + ' and l.JCTransType = ' + char(39) + 'PO' + char(39) + ' then POHD.UniqueAttchID' +
						 ' when l.Source = ' + char(39) + 'PM Intface' + char(39) + ' and l.JCTransType = ' + char(39) + 'SL' + char(39) + ' then SLHD.UniqueAttchID' +
						 ' when l.Source = ' + char(39) + 'SL Entry' + char(39) + ' then SLHD.UniqueAttchID' +
						 ' when l.Source = ' + char(39) + 'PO Entry' + char(39) + ' then POHD.UniqueAttchID' +
						 ' else l.UniqueAttchID end'
	---- view name			 
	select @sql = @sql + ', ViewName = case' +
						 ' when l.Source = ' + char(39) + 'AP Entry' + char(39) + ' then ' + char(39) + 'APTH' + char(39) + 
						 ' when l.Source = ' + char(39) + 'PM Intface' + char(39) + ' and l.JCTransType = ' + char(39) + 'PO' + char(39) + ' then ' + char(39) + 'POHD' + char(39) +
						 ' when l.Source = ' + char(39) + 'PM Intface' + char(39) + ' and l.JCTransType = ' + char(39) + 'SL' + char(39) + ' then ' + char(39) + 'SLHD' + char(39) + 
						 ' when l.Source = ' + char(39) + 'SL Entry' + char(39) + ' then ' + char(39) + 'SLHD' + char(39) + 
						 ' when l.Source = ' + char(39) + 'PO Entry' + char(39) + ' then ' + char(39) + 'POHD' + char(39) + 
						 ' else ' + char(39) + 'JCCD' + char(39) + ' end'
	---- table key ID			 
	select @sql = @sql + ', AttachKeyID = case' +
						 ' when l.Source = ' + char(39) + 'AP Entry' + char(39) + ' then APTH.KeyID' +
						 ' when l.Source = ' + char(39) + 'PM Intface' + char(39) + ' and l.JCTransType = ' + char(39) + 'PO' + char(39) + ' then POHD.KeyID' +
						 ' when l.Source = ' + char(39) + 'PM Intface' + char(39) + ' and l.JCTransType = ' + char(39) + 'SL' + char(39) + ' then SLHD.KeyID' +
						 ' when l.Source = ' + char(39) + 'SL Entry' + char(39) + ' then SLHD.KeyID' +
						 ' when l.Source = ' + char(39) + 'PO Entry' + char(39) + ' then POHD.KeyID' +
						 ' else l.KeyID end'						 
	end
else
	begin
	select @sql = @sql + ', UniqueAttchID = l.UniqueAttchID, ViewName = ' + char(39) + 'JCCD' + char(39) + ', AttachKeyID = l.KeyID'
	end


----#134080
----#140220
----select @sql = @sql + ', APVM.Name as APVMName'
select @sql = @sql + ', convert(varchar(10),APVM.Vendor) + ' + CHAR(39) + ' - ' + CHAR(39) + ' + isnull(APVM.Name,' + char(39) + char(39) + ') as APVMName'

SELECT @sql = @sql + ', APTH.Description as APTHDesc, APTL.Description as APTLDesc, l.APRef as APRef, l.VendorGroup as VendorGroup'

----select @sql = @sql + ', EMEM.Description as EMEMDesc'
select @sql = @sql + ', EMEM.Equipment + ' + CHAR(39) + ' - ' + CHAR(39) + ' + isnull(EMEM.Description,' + char(39) + char(39) + ')  as EMEMDesc'

----SELECT @sql = @sql + ', EMRC.Description as EMRCDesc'
select @sql = @sql + ', EMRC.RevCode + ' + CHAR(39) + ' - ' + CHAR(39) + ' + isnull(EMRC.Description,' + char(39) + char(39) + ')  as EMRCDesc'

SELECT @sql = @sql + ', EMRD.Memo as EMRDMemo, l.EMGroup as EMGroup'

----select @sql = @sql + ', POHD.Description as POHDDesc, POIT.Description as POITDesc'
select @sql = @sql + ', POHD.PO + ' + CHAR(39) + ' - ' + CHAR(39) + ' + isnull(POHD.Description,' + CHAR(39) + CHAR(39) + ') as POHDDesc'
SELECT @sql = @sql + ', convert(varchar(10),POIT.POItem) + ' + CHAR(39) + ' - ' + CHAR(39) + ' + isnull(POIT.Description,' + char(39) + char(39) + ')  as POITDesc'

select @sql = @sql + ', isnull(PREH.LastName,'+ char(39) + char(39) +') + ' + char(39) + ' ' + char(39) + ' + isnull(PREH.FirstName,'+ char(39) + char(39) +') + ' + char(39) + ' ' + char(39) + ' + isnull(PREH.MidName,'+ char(39) + char(39) +') as PREHName, PRCM.Description as PRCMDesc, PRCC.Description as PRCCDesc, PRCR.Description as PRCRDesc'

----select @sql = @sql + ', SLHD.Description as SLHDDesc, SLIT.Description as SLITDesc'
SELECT @sql = @sql + ', SLHD.SL + ' + CHAR(39) + ' - ' + CHAR(39) + ' + isnull(SLHD.Description,' + char(39) + char(39) + ') as SLHDDesc'
SELECT @sql = @sql + ', convert(varchar(10),SLIT.SLItem) + ' + CHAR(39) + ' - ' + CHAR(39) + ' + isnull(SLIT.Description,' + char(39) + char(39) + ') as SLITDesc'
----#140220

select @sql = @sql + @where

select @paramsin = N'@jcco tinyint, @job bJob, @phasegroup tinyint, @phase bPhase, @begmonth bMonth, @endmonth bMonth, @costtype tinyint'

EXECUTE sp_executesql @sql, @paramsin, @jcco, @job, @phasegroup, @phase, @begmonth, @endmonth, @costtype

GO
GRANT EXECUTE ON  [dbo].[bspJCProjDetailGridFill] TO [public]
GO
