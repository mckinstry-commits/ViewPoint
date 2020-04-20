SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMSubmittalInitialize    Script Date: 08/11/2005 ******/
CREATE  procedure [dbo].[vspPMSubmittalInitialize]
/*******************************************************************************
* Pass this SP all the info to initialize some Submittals based on a range of
* phases from Standard phase submittals.
* It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
* If there is an error it will display the error message.
*
* Modified By:  GF 10/11/2001 - Use Contact Code from JCJM when initializing submittals. #14840
*				GF 03/27/2002 - Need to set submittal variable to null before formatting. #16752
*				GF 07/29/2002 - Need to set responsible firm when intializing submittals. #18118
*				SR 09/12/2002 - Need to use default beginning status from PMCO if there is one. #18312
*				GF 12/11/2003 - #23212 - check error messages, wrap concatenated values with isnull
*				GF 02/07/2005 - issue #22095 - allow submittl initialize on all Job Status
*				GF 10/23/2008 - issue #130143 expanded description column in temp table to 60
				AR 11/29/2010 - #142278 - removing old style joins replace with ANSI correct form
*
*
* Pass In
*   Connection      Connection to do query on
*   PMCo            PM Company to initialize in
*   Project         Project to initialize Submittals for
*   StartingDoc     Document number to start at
*   DocType         What Document type to initialize(must be Submittal type)
*   VendorGroup     VendorGroup the vendors are in
*   UorV	    If U then initialize for each unique phase only, if 'V'
*		    then initialize using valid part of phase code.
*   StartPhase      Phase to start Initializing from (null for start)
*   EndPhase        Phase to end at
*   ReceiptDate     Date to initialize Activity Date to on new records
*   ActivityDate    Date to initialize Activity Date to on new records
*
* RETURN PARAMS
*   msg           Error Message, or Success message
*
* Returns
*      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
*
********************************************************************************/
(@pmco bCompany, @project bJob, @startingdoc int, @doctype bDocType, @vendorgroup bGroup,
 @UorVflag varchar(1), @phasegroup bGroup, @startphase bPhase = null, @endphase bPhase = null,
 @receiptdate bDate = null, @activitydate bDate = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @docnumber int, @status bStatus, @opencursor int, @phase bPhase,
		@submittaltype bDocType, @description bTransDesc, @vendor bVendor, @initcount int,
		@submittal bDocument, @docstring bDocument, @seq tinyint,
		@archengfirm bFirm, @archengcontact bEmployee, @vendorcontact bEmployee, @reccount int,
		@firmtype bFirmType, @responsiblefirm bFirm, @validphasechars int,
		@inputmask varchar(30), @inputlength varchar(10)

select @rcode=1, @firmtype=null, @msg='Error Initializing!'

-- -- -- get valid part phase characters from JCCO
select @validphasechars=ValidPhaseChars from JCCO where JCCo=@pmco
if isnull(@validphasechars,0) = 0 set @validphasechars = 20
 
-- get project information needed to initialize
select @archengfirm=ArchEngFirm, @archengcontact=ContactCode, @responsiblefirm=OurFirm
from JCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount = 0
    begin
    select @msg='Project: ' + isnull(@project,'') + ' not setup, cannot initialize!',@rcode=1
    goto bspexit
    end

if isnull(@responsiblefirm,'') = ''
	begin
	select @responsiblefirm=OurFirm from PMCO with (nolock) where PMCo=@pmco
	end

if @UorVflag<>'U'
   if @UorVflag<>'V'
      begin
      select @msg='Must be (U)nique phase or (V)alid part of phase.  Cannot initialize!',@rcode=1
      goto bspexit
      end

if not exists (select top 1 1 from PMDT with (nolock) where DocType=@doctype)
    begin
    select @msg='The document type you are trying to initialize submittals with is invalid. Cannot initialize!',@rcode=1
    goto bspexit
    end

exec @rcode = dbo.bspPMDocTypeVal @doctype, 'SUBMIT', @msg=@msg output
if @rcode = 1 goto bspexit

-- -- -- get the mask for bDocument
select @inputmask=InputMask, @inputlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bDocument'
if isnull(@inputmask,'') = '' select @inputmask = 'R'
if isnull(@inputlength,'') = '' select @inputlength = '10'
if @inputmask in ('R','L')
	begin
	select @inputmask = @inputlength + @inputmask + 'N'
	end

select @docnumber=isNull(@startingdoc,1)
if isnull(@docnumber,0) = 0 select @docnumber = 1

-- Default status to first Beginning type status code
-- issue 18312 - use Default Begin status from PMCO if there is one else use from PMSC
select @status = BeginStatus from PMCO with (nolock) where PMCo=@pmco and BeginStatus is not null
if @@rowcount = 0 select @status = min(Status) from PMSC with (nolock) where CodeType = 'B'

-- created temporary table to store phases
create table #SubmitPhases
(
Phase varchar(20) null,
Seq tinyint null,
SubmittalType varchar(10) null,
Description varchar(60) null,
Vendor int null
)

-- fill Submittal Phases for option (U)nique phases
IF @UorVflag = 'U' 
    BEGIN
		INSERT  INTO #SubmitPhases	 (
										Phase,
										Seq,
										SubmittalType,
										[Description],
										Vendor
									)
				--#142278					
                SELECT  j.Phase,
                        p.Seq,
                        p.SubmittalType,
                        p.[Description],
                        NULL
                FROM    dbo.PMPS p WITH ( NOLOCK )
							JOIN dbo.JCJP j WITH ( NOLOCK ) ON j.PhaseGroup = p.PhaseGroup
																AND j.Phase = p.Phase
                WHERE   p.PhaseGroup = @phasegroup
                        AND p.SubmittalType = ISNULL(@doctype, SubmittalType)
                        AND p.Phase BETWEEN ISNULL(@startphase, p.Phase)
                                    AND     ISNULL(@endphase, p.Phase)
                        AND j.JCCo = @pmco
                        AND j.Job = @project
                        AND NOT EXISTS ( SELECT 1
                                         FROM   dbo.PMSM WITH ( NOLOCK )
                                         WHERE  PMCo = @pmco
                                                AND Project = @project
                                                AND SubmittalType = @doctype
                                                AND PhaseGroup = p.PhaseGroup
                                                AND Phase = j.Phase )
    END

-- fill Submittal Phases for option (V)alid part of phase code
IF @UorVflag = 'V' 
    BEGIN
        INSERT  INTO #SubmitPhases	(
										Phase,
										Seq,
										SubmittalType,
										[Description],
										Vendor
									)
				--#142278					
                SELECT  j.Phase,
                        p.Seq,
                        p.SubmittalType,
                        p.[Description],
                        NULL
                FROM    dbo.PMPS p WITH ( NOLOCK )
							JOIN dbo.JCJP j WITH ( NOLOCK ) ON j.PhaseGroup = p.PhaseGroup
                WHERE   p.PhaseGroup = @phasegroup
                        AND p.SubmittalType = ISNULL(@doctype, SubmittalType)
                        AND p.Phase >= ISNULL(@startphase, p.Phase)
                        AND p.Phase <= ISNULL(@endphase, p.Phase)
                        AND j.JCCo = @pmco
                        AND j.Job = @project
                        AND SUBSTRING(j.Phase, 1, @validphasechars) = SUBSTRING(p.Phase,
                                                              1,
                                                              @validphasechars)
                        AND NOT EXISTS ( SELECT 1
                                         FROM   dbo.PMSM WITH ( NOLOCK )
                                         WHERE  PMCo = @pmco
                                                AND Project = @project
                                                AND SubmittalType = @doctype
                                                AND PhaseGroup = p.PhaseGroup
                                                AND Phase = j.Phase )
    END





---- now get applicable vendors from PMMF and add to temporary SubmitPhases table
	INSERT  INTO #SubmitPhases   (
									Phase,
									Seq,
									SubmittalType,
									[Description],
									Vendor
									)
			--#142278
			SELECT  s.Phase,
					s.Seq,
					s.SubmittalType,
					s.[Description],
					m.Vendor
			FROM    dbo.PMMF m WITH ( NOLOCK )
						JOIN #SubmitPhases s ON s.Phase = m.Phase
			WHERE   m.PMCo = @pmco
					AND m.Project = @project
					AND m.PhaseGroup = @phasegroup
					AND m.Vendor IS NOT NULL
					AND NOT EXISTS ( SELECT 1
									 FROM   #SubmitPhases
									 WHERE  Phase = s.Phase
											AND Seq = s.Seq
											AND Vendor = m.Vendor )

---- now get applicable vendors from PMSL and add to temporary SubmitPhases table
	INSERT  INTO #SubmitPhases   (
									Phase,
									Seq,
									SubmittalType,
									[Description],
									Vendor
									)
	--#142278
        SELECT DISTINCT
                s.Phase,
                s.Seq,
                s.SubmittalType,
                s.[Description],
                m.Vendor
        FROM    dbo.PMSL m WITH ( NOLOCK )
					JOIN #SubmitPhases s ON s.Phase = m.Phase
        WHERE   m.PMCo = @pmco
                AND m.Project = @project
                AND m.PhaseGroup = @phasegroup
                AND m.Vendor IS NOT NULL
                AND NOT EXISTS ( SELECT 1
                                 FROM   #SubmitPhases
                                 WHERE  Phase = s.Phase
                                        AND Seq = s.Seq
                                        AND Vendor = m.Vendor )

---- now delete any rows that have a null vendor and valid vendors for a Phase and Seq
delete from #SubmitPhases
where Vendor is null and
exists (select 1 from #SubmitPhases s where s.Phase=#SubmitPhases.Phase and
				s.Seq=#SubmitPhases.Seq and s.Vendor is not null)

-- declare cursor for all rows in SubmitPhases table where phase is not null
-- and SubmittalType is not null
declare bcSubmitPhases cursor LOCAL FAST_FORWARD
for select Phase, Seq, SubmittalType, Description, Vendor
from #SubmitPhases where Phase is not null and SubmittalType is not null

open bcSubmitPhases

-- set open cursor flag to true
select @opencursor = 1, @initcount=0

-- loop through standard Submittal phases
process_loop:

fetch next from bcSubmitPhases into @phase, @seq, @submittaltype, @description, @vendor
if (@@fetch_status <> 0) goto process_loop_end

formatloop:

select @docstring = convert(varchar(10),@docnumber)
select @submittal = null
exec dbo.bspHQFormatMultiPart @docstring, @inputmask, @submittal output

-- make sure document number is valid, if not increment it
if exists (select 1 from PMSM with (nolock) where PMCo=@pmco and Project=@project and
  				SubmittalType=@submittaltype and Submittal=@submittal)
	begin
	if convert(int,@submittal) <> @docnumber
		begin
		select @msg = 'Error getting next submittal number! Submittal: ' + isnull(@submittal,'') + ' DocNumber: ' + convert(varchar(10),isnull(@docnumber,'')) + ' DocString: ' + isnull(@docstring,''), @rcode=1
		goto bspexit
		end

	select @docnumber = @docnumber + 1
	goto formatloop
	end

-- initialize vendor into PMFM if needed
if @vendor is not null
	begin
	exec dbo.bspPMFirmInitialize @vendorgroup, @vendor, @vendor, @firmtype, @msg
	end

-- Default contact from PMPF where vendor is setup and only one contact
select @reccount = 0
select @vendorcontact = min(ContactCode), @reccount = count(*) from PMPF with (nolock) 
where PMCo=@pmco and Project=@project and VendorGroup=@vendorgroup and FirmNumber=@vendor
If @reccount <> 1
	begin
   	select @vendorcontact = null
   	end

insert into PMSM (PMCo, Project, SubmittalType, Submittal, Rev, Description, Issue, Status,
		PhaseGroup, Phase, VendorGroup, ResponsibleFirm, SubFirm, SubContact, ArchEngFirm, ArchEngContact,
  		CopiesRecd, CopiesSent, DateReqd, ActivityDate)
select @pmco, @project, @submittaltype, @submittal, 0, @description, null, @status,
		@phasegroup, @phase, @vendorgroup, @responsiblefirm, @vendor, @vendorcontact, @archengfirm, @archengcontact,
       	0, 0, @receiptdate, @activitydate

select @initcount=@initcount + 1
select @docnumber=@docnumber + 1

goto process_loop


process_loop_end:
	select @msg = convert(varchar(5),@initcount) + ' submittals initialized.', @rcode=0




bspexit:
    if @opencursor=1
       begin
       close bcSubmitPhases
       deallocate bcSubmitPhases
       end

  	if @rcode <> 0 
		select @msg = isnull(@msg,'') 
	else
		select @msg = convert(varchar(6), @initcount) + ' submittals initialized.'
    return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSubmittalInitialize] TO [public]
GO
