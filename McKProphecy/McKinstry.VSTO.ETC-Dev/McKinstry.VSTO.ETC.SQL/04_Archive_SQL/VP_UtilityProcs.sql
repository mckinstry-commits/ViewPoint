-- Create Batch

declare @p9 varchar(255)
set @p9=NULL
exec bspHQBCInsert @co=1,@month='2016-02-01 00:00:00',@source='JC Projctn',@batchtable='JCPB',@restrict='N',@adjust='N',@prgroup=NULL,@prenddate=NULL,@errmsg=@p9 output
select @p9

-- Set User Options
declare @p30 varchar(255)
set @p30=NULL
exec dbo.bspJCUOInsert @jcco=1,@form='JCProjection',@username='MCKINSTRY\billo',@changedonly='N',@itemunitsonly='N',@phaseunitsonly='N',@showlinkedct='N',@showfutureco='N',@remainunits='N',@remainhours='N',@remaincosts='N',@openform='N',@phaseoption='N',@begphase='',@endphase='',@costtypeoption='0',@selectedcosttypes='',@visiblecolumns='',@columnorder='',@thrupriormonth='',@nolinkedct='N',@projmethod=NULL,@production='',@writeoverplug='',@initoption='',@projinactivephases='N',@orderby='P',@cyclemode='N',@columnwidth='',@msg=@p30 output
select @p30

--Get User Options
declare @p4 varchar(1)
set @p4=NULL
declare @p5 varchar(1)
set @p5=NULL
declare @p6 varchar(1)
set @p6=NULL
declare @p7 varchar(1)
set @p7=NULL
declare @p8 varchar(1)
set @p8=NULL
declare @p9 varchar(1)
set @p9=NULL
declare @p10 varchar(1)
set @p10=NULL
declare @p11 varchar(1)
set @p11=NULL
declare @p12 varchar(1)
set @p12=NULL
declare @p13 varchar(1)
set @p13=NULL
declare @p14 varchar(20)
set @p14=NULL
declare @p15 varchar(20)
set @p15=NULL
declare @p16 varchar(1)
set @p16=NULL
declare @p17 varchar(1000)
set @p17=NULL
declare @p18 varchar(1000)
set @p18=NULL
declare @p19 varchar(1000)
set @p19=NULL
declare @p20 varchar(1)
set @p20=NULL
declare @p21 varchar(1)
set @p21=NULL
declare @p22 varchar(1)
set @p22=NULL
declare @p23 varchar(1)
set @p23=NULL
declare @p24 varchar(1)
set @p24=NULL
declare @p25 varchar(1)
set @p25=NULL
declare @p26 varchar(1)
set @p26=NULL
declare @p27 varchar(1)
set @p27=NULL
declare @p28 varchar(1)
set @p28=NULL
declare @p29 varchar(8000)
set @p29=NULL
declare @p30 varchar(255)
set @p30=NULL
exec dbo.vspJCUOGet @jcco=1,@form='JCProjection',@username='MCKINSTRY\billo',@changedonly=@p4 output,@itemunitsonly=@p5 output,@phaseunitsonly=@p6 output,@showlinkedct=@p7 output,@showfutureco=@p8 output,@remainunits=@p9 output,@remainhours=@p10 output,@remaincosts=@p11 output,@openform=@p12 output,@phaseoption=@p13 output,@begphase=@p14 output,@endphase=@p15 output,@costtypeoption=@p16 output,@selectedcosttypes=@p17 output,@visiblecolumns=@p18 output,@columnorder=@p19 output,@thrupriormonth=@p20 output,@nolinkedct=@p21 output,@projmethod=@p22 output,@production=@p23 output,@writeoverplug=@p24 output,@initoption=@p25 output,@projinactivephases=@p26 output,@orderby=@p27 output,@cyclemode=@p28 output,@columnwidth=@p29 output,@msg=@p30 output
select @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17, @p18, @p19, @p20, @p21, @p22, @p23, @p24, @p25, @p26, @p27, @p28, @p29, @p30


-- Retrieves Actual Date from an existing batch
declare @p5 smalldatetime
set @p5=NULL
declare @p6 varchar(10)
set @p6=NULL
declare @p7 varchar(255)
set @p7=NULL
exec vspJCProActualDateGet @co=1,@batchid=19,@mth='2016-02-01 00:00:00',@table='JCPB',@date=@p5 output,@job=@p6 output,@msg=@p7 output
select @p5, @p6, @p7

-- Validate Project to Add to Batch (Included test for existing batch)
declare @p6 varchar(10)
set @p6=NULL
declare @p7 varchar(60)
set @p7=NULL
declare @p8 numeric(12,3)
set @p8=NULL
declare @p9 numeric(6,4)
set @p9=NULL
declare @p10 int
set @p10=NULL
declare @p11 varchar(500)
set @p11=NULL
declare @p12 varchar(60)
set @p12=NULL
declare @p13 varchar(16)
set @p13=NULL
declare @p14 varchar(16)
set @p14=NULL
declare @p15 varchar(20)
set @p15=NULL
declare @p16 varchar(20)
set @p16=NULL
declare @p17 varchar(255)
set @p17=NULL
exec bspJCJMValForProj @jcco=1,@job=' 10353-001',@batch=20,@mth='2016-02-01 00:00:00',@actualdate='2016-03-29 00:00:00',@contract=@p6 output,@contractdesc=@p7 output,@hrspermanday=@p8 output,@projminpct=@p9 output,@wcode=@p10 output,@wmsg=@p11 output,@jobdesc=@p12 output,@begitem=@p13 output,@enditem=@p14 output,@begphase=@p15 output,@endphase=@p16 output,@msg=@p17 output
select @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16, @p17

--Fill Projection Table with Job Information
declare @p10 varchar(255)
set @p10=NULL
exec dbo.bspJCProjTableFill @username='MCKINSTRY\billo',@co=1,@mth='2016-02-01 00:00:00',@batchid=20,@job=' 10353-001',@phasegroup=1,@actualdate='2016-03-29 00:00:00',@projminpct=NULL,@form='JCProjection',@msg=@p10 output
select @p10

--Caclulate Projections Button
declare @p12 varchar(255)
set @p12=''''''
exec bspJCProjInitialize @jcco=1,@bjob=' 10353-001',@ejob=' 10353-001',@projectmgr=0,@phasegroup=1,@actualdate='2016-03-29 00:00:00',@writeoverplug=2,@mth='2016-02-01 00:00:00',@batchid=20,@username='MCKINSTRY\billo',@detailinit=2,@msg=@p12 output
select @p12

--Detail Screen
--Lookup PRCo
declare @p4 varchar(512)
set @p4=NULL
exec vspDDUserLookupUpdate @lookup='PRCO',@position='150,150,350, 383',@rowheight=15,@errmsg=@p4 output
select @p4

--Lookup Craft
declare @p4 varchar(512)
set @p4=NULL
exec vspDDUserLookupUpdate @lookup='PRCM',@position='25,25,350, 383',@rowheight=15,@errmsg=@p4 output
select @p4

--Lookup Class
declare @p4 varchar(512)
set @p4=NULL
exec vspDDUserLookupUpdate @lookup='PRCC',@position='75,75,350, 383',@rowheight=15,@errmsg=@p4 output
select @p4

--Lookup UoM
declare @p4 varchar(512)
set @p4=NULL
exec vspDDUserLookupUpdate @lookup='HQUM',@position='125,125,350, 383',@rowheight=15,@errmsg=@p4 output
select @p4

--Projection Detail Insert

--Insert JCPD Entry
exec sp_executesql N'insert JCPD ([Co],[DetSeq],[Mth],[BatchId],[BatchSeq],[Source],[JCTransType],[TransType],[ResTrans],[Job],[PhaseGroup],[Phase],[CostType],[BudgetCode],[EMCo],[Equipment],[PRCo],[Craft],[Class],[Employee],[Description],[DetMth],[FromDate],[ToDate],[Quantity],[Units],[UM],[UnitHours],[Hours],[Rate],[UnitCost],[Amount],[Notes]) values (@Co,@DetSeq,@Mth,@BatchId,@BatchSeq,@Source,@JCTransType,@TransType,@ResTrans,@Job,@PhaseGroup,@Phase,@CostType,@BudgetCode,@EMCo,@Equipment,@PRCo,@Craft,@Class,@Employee,@Description,@DetMth,@FromDate,@ToDate,@Quantity,@Units,@UM,@UnitHours,@Hours,@Rate,@UnitCost,@Amount,@Notes)',N'@BatchSeq int,@Co tinyint,@DetSeq int,@Mth datetime,@BatchId int,@Source varchar(10),@JCTransType varchar(2),@TransType varchar(1),@ResTrans int,@Job varchar(10),@PhaseGroup tinyint,@Phase varchar(20),@CostType int,@BudgetCode varchar(8000),@EMCo tinyint,@Equipment varchar(8000),@PRCo tinyint,@Craft varchar(4),@Class varchar(5),@Employee int,@Description varchar(3),@DetMth datetime,@FromDate datetime,@ToDate datetime,@Quantity float,@Units float,@UM varchar(3),@UnitHours float,@Hours float,@Rate float,@UnitCost float,@Amount float,@Notes varchar(8000)',@BatchSeq=254,@Co=1,@DetSeq=276,@Mth='2016-02-01 00:00:00',@BatchId=20,@Source='JC Projctn',@JCTransType='PB',@TransType='A',@ResTrans=NULL,@Job='105819-001',@PhaseGroup=1,@Phase='0100-0000-      -   ',@CostType=1,@BudgetCode=NULL,@EMCo=NULL,@Equipment=NULL,@PRCo=1,@Craft='0001',@Class='501PC',@Employee=NULL,@Description='MIS',@DetMth='2016-02-01 00:00:00',@FromDate=NULL,@ToDate=NULL,@Quantity=0,@Units=0,@UM='HRS',@UnitHours=1,@Hours=50,@Rate=75,@UnitCost=0,@Amount=3750,@Notes=NULL

-- Post JCPD Values to JCPB
exec sp_executesql N'update JCPB set [Plugged]= @Plugged,[ProjFinalHrs]= @ProjFinalHrs,[ProjFinalCost]= @ProjFinalCost from JCPB where JCPB.Mth = ''2016/02/01'' and JCPB.BatchId = 20 and [Co]=1 and [BatchSeq]=254',N'@Plugged varchar(1),@ProjFinalHrs float,@ProjFinalCost float',@Plugged='Y',@ProjFinalHrs=150,@ProjFinalCost=11250

declare @p16 varchar(255)
set @p16=NULL
exec dbo.bspJCProjUpdateData @jcco=1,@job='105819-001',@phasegroup=1,@phase='0100-0000-      -   ',@costtype=1,@mth='2016-02-01 00:00:00',@batchid=20,@plugged='Y',@buyout='N',@projnotes=NULL,@pctcalcunits=0,@pctcalchours=0,@pctcalccosts=0,@projmethod='2',@prevprojflag='N',@msg=@p16 output
select @p16
