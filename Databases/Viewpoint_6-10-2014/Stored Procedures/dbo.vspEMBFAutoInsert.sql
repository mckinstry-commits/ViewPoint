SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[vspEMBFAutoInsert]
/***********************************************************
* CREATED BY: 	TRL 08/06/09 Issue 129345 
* MODIFIED BY:  TRL 12/28/09 Issue 137105, continueatin from 1292345
*				TRL 02/02/10 Issue 137833, Fix MaxPerJob
*				TRL 08/31/10 Issue,  140795 Fix for Job with Est Out Dates with no JTD history
*				TRL  02/03/2011 Issue 143138 Fixed prev and curent mth totals
*				GF 07/16/2012 TK-16407 Cleanup of deleting usage when re-run and attachment delete
*				GF 03/11/2013 TFS-40249 issue 148178 fix for usage calculation daily one day less
*				GF 07/15/2013 TFS-55825 change monthly revenue units calc to use part of month not hours
*
*
*					
* USAGE:  reads records from EMLH and inserts them into EMBF based on the template and category specifications.
*         revenue rates are determined here based on how the user has set up the revenue maintainance programs.
*         one EMBF entry is made for every EMCo/Equipment/ToJCCo/ToJob combination in EMLH
*
* INPUT PARAMETERS
*   EMCo        EM Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*   Beginnign Date
*   Ending Date
*   Beginning Template
*   Ending Template
*   Beginning Category
*   Ending Category
*   Exclude Location
*   Exclude Date 1-6
*   Bill saturdays & sundays
*   Actual Date
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@emco bCompany, 
@mth bMonth, 
@batchid bBatchID,
@period_begindate smalldatetime=null, 
@period_enddate smalldatetime=null, 
@begintemplate varchar(10)=null, @endtemplate varchar(10)=null, 
@begincatgy bCat=null, @endcatgy bCat=null, 
@exloc bLoc=null, @exlocmax bLoc=null, 
@date1 bDate=null, @date2 bDate=null, @date3 bDate=null, @date4 bDate=null, @date5 bDate=null, @date6 bDate=null, 
@billsats bYN, @billsuns bYN, @actdate bDate, @deleteusage bYN = 'N',
@errmsg varchar(max) output
as

set nocount on
 
declare @rcode int, @msg_variable varchar(255),
/*EM Company variables =>*/@emgroup bGroup, @glco bCompany,/*bcEMLH cursor  variables =>*/@opencursor tinyint,@lastrec bYN,
/*Current EM Location Transfer record being process before start of pusedo cursor*/
@to_equip bEquip,  @datein bDate, @timein smalldatetime,@dateout bDate, @timeout smalldatetime,@to_jcco bCompany, @to_job bJob,  @to_loc bLoc, @to_estdateout bDate,

/* Save Equipment/JCCo/Job/Template posting variables used to create batch record*/
/*Variables used to insert EMBF Record after All (per) Equipment/JCCo/Job transfers have been cycled through*/
@save_equip bEquip, @save_jcco bCompany, @save_job bJob, @save_datein smalldatetime, @save_timein smalldatetime, @save_dateout smalldatetime, @save_timeout smalldatetime,
@save_estdateout smalldatetime, @save_prev_mthenddate smalldatetime,
@save_equip_catgy_templt_type char(5),@save_start_billing_on_trnsfr_date_YN bYN, @save_use_est_out_date_YN bYN, @save_rulestable varchar(10),@save_phase bPhase, 
@save_maxperpd bDollar, @save_maxpermth bDollar, @save_maxperjob bDollar,@save_minperpd bDollar,  @post_date bDate, 

/*Calc before batch record is created*/
@totalesthours bHrs,@prev_transfer_mth_post_hours decimal (12,2),@curr_transfer_mth_post_hours decimal (12,2),
@curr_mth_post_hours decimal (12,2),@prev_mth_post_hours decimal (12,2),@curr_transfer_amt decimal (12,2),@prev_transfer_amt decimal (12,2),

/*Start RecInsert: variables*/
 @amount bDollar, @posthours bUnits, @seq int, 
 
 /*Reset after each batch record is inserted */
 @totalhours bHrs, @prev_transfer_billed_mth_amt decimal (12,2),@curr_transfer_billed_mth_amt decimal (12,2),
 
/*Dead or unused Auto Templ variable output parameters*/
 @x_equip_catgy_templt_type char(5),@x_startbillingintrnsfrindate bYN,   @x_useestoutdate bYN, 
 @x_rulestable varchar(10),@x_phase bPhase, @x_maxperpd bDollar, @x_maxpermth bDollar, @x_maxperjob bDollar,@x_minperpd bDollar, 
/*Rules Table variables->*/@hours_opt char(1), @morethan bHrs, @lessthan bHrs, /*Rev Rate variables->*/@rate bDollar, @time_um bUM, 
/*JC Company GL Co*/@offsetglco bCompany, @offsetacct bGLAcct,/*JCCo Phase Group only called when Batch record is created =>*/@phasegroup bGroup, 
@curr_mth_prev_enddate smalldatetime, 
/*End RecInsert variables*/

/*Variables that get reset and recalculated per each location transfer record when changes occur on Equipment, JCCo or Job*/
@jtdamount bDollar, @jtdhours bHrs,@pdhours bHrs, @pdamount bDollar, @mtdamount bDollar,@hours bHrs,@cnt int, @indayflag char(7), @outdayflag char(7), @maxseq int,

/*Equipment variables*/
@catgy bCat, @dept bDept, @status char(1), @type char(1), @jcct bJCCType,@prco bCompany, @employee bEmployee,@odometer bHrs,@hourmeter bHrs,
/*AutoTemplate variables =>*/@autotemplate varchar(10),

--EM Revenue Detial  variables
@emrd_mth bMonth, @trans bTrans,@revcode bRevCode,@actualdate bDate,@timefactor bHrs,@timeunits bUnits,@basis char(1), @emrd_amount bDollar, @monthlyrevcodeYN bYN, 
@mth_begin_date smalldatetime, @mth_end_date smalldatetime,   @prev_mthbegindate smalldatetime, @prev_mthenddate smalldatetime,
@mthenddate_time smalldatetime  

select @rcode = 0,@cnt = 0,@totalhours = 0,@save_equip = null,@save_jcco = null,@save_job = null,@post_date = null,@lastrec = 'N', 
@save_datein= null, @save_dateout =null,@prev_transfer_billed_mth_amt=0,/*<=129345=>*/@curr_transfer_billed_mth_amt=0

--get the EMGroup and  the EM Company GLCo--
select @emgroup = HQCO.EMGroup, @glco=EMCO.GLCo
from dbo.HQCO with(nolock)
Inner Join dbo.EMCO  with(nolock)on EMCO.EMCo=HQCO.HQCo 
where HQCo = @emco

--Get values for any 'first' or 'last' inputs.  First and last Cat and Temp are now passed in null. 
if isnull(lower(@begintemplate),'first') = 'first' select @begintemplate = min(AUTemplate) from dbo.EMUH with(nolock) where EMCo = @emco
if isnull(lower(@endtemplate),'last') = 'last' select @endtemplate = max(AUTemplate) from dbo.EMUH with(nolock) where EMCo = @emco
if isnull(lower(@begincatgy),'first') = 'first' select @begincatgy = min(Category) from dbo.EMCM with(nolock) where EMCo = @emco
if isnull(lower(@endcatgy),'last') = 'last' select @endcatgy = max(Category) from dbo.EMCM with(nolock) where EMCo = @emco

--Search EMLH (Location Transfer History) for records that apply to this period 
-- Declare cursor on EM Batch 
declare bcEMLH cursor local fast_forward for
select h.Equipment, h.DateIn, h.TimeIn, h.DateOut, h.TimeOut, h.ToJCCo, h.ToJob, h.ToLocation,h.EstOut/*129345*/
from dbo.EMLH h 
inner join dbo.EMEM e with (nolock)on e.EMCo = h.EMCo and e.Equipment = h.Equipment 
where h.EMCo = @emco and h.ToJCCo is not null and h.ToJob is not null and isnull(e.AttachToEquip,'') = '' 
and (isnull(h.ToLocation,'~') not between isnull(@exloc,'') and isnull(@exlocmax,'') and isnull(h.ToLocation,'~') not in (isnull(@exloc,''), isnull(@exlocmax,'')))
and ((h.DateIn <= @period_begindate and ((h.DateOut is null) or (h.DateOut is not null and h.DateOut >= @period_enddate))) or
		 (h.DateIn >= @period_begindate and h.DateOut <= @period_enddate) or
		(h.DateIn <= @period_begindate and h.DateOut >= @period_begindate and h.DateOut <= @period_enddate) or
		(h.DateIn >= @period_begindate and h.DateIn <= @period_enddate and ((h.DateOut is null) or (h.DateOut is not null and h.DateOut >= @period_enddate))))
order by h.Equipment, h.ToJCCo, h.ToJob, h.DateIn, h.TimeIn,h.EstOut 
--Open EM Batch cursor
open bcEMLH
select @opencursor = 1


--START CURSOR cycle, loop through all Location Transfer Recordsin EM Batch cursor 
cycle:
fetch next
from bcEMLH
into @to_equip, @datein, @timein, @dateout, @timeout, @to_jcco, @to_job, @to_loc,@to_estdateout
     
if @@fetch_status = -1
begin
	if @totalhours <> 0
		begin
			select @lastrec= 'Y'
			goto recinsert
		end
	else
		begin
			goto loop_end
		end
end
     
if @@fetch_status <> 0 goto cycle

----TFS-40249 For Usage calc, dateout cannot be greater than the Auto Usage Period End Date
IF @dateout IS NOT NULL AND @dateout > @period_enddate 
	BEGIN
	SET @dateout = NULL
	SET @timeout = NULL
	END
			
/* initialize psuedo key of Equip/JCCo/Job */
if @save_equip is null 
begin
	select @save_equip = @to_equip, @save_jcco = @to_jcco, @save_job = @to_job, @post_date = @dateout,
	/*129345 ->*/@save_datein =@datein, @save_dateout =@dateout,@save_estdateout=@to_estdateout/*<-129345*/
end


/********************************************************************************************************************
1.  if the psuedo key has changed and the previous key (Equipment/JCCo/Job) has accumulated hours
 attempt to add the saved key into EMBF 
2.  On the first location transfer record the total hours will be zero so the "recinsert" is skipped
3.  @save_varaibles are used to insert a batch record in EMBF
*******************************************************************************************************************/
--This Label Adds the record into EMBF
recinsert: 
if (@save_equip <> @to_equip or @save_jcco <> @to_jcco or @save_job <> @to_job or @lastrec = 'Y') and @totalhours > 0
begin
	--Reset "recinsert varialbes
	select @posthours = 0, @prev_transfer_mth_post_hours=0,@curr_transfer_mth_post_hours=0, @totalesthours=0, 
	@amount = 0,@revcode = '', /*143138 */@prev_mth_post_hours = 0,@curr_mth_post_hours = 0/*143138*/
	
	--Validate Rules Table and Revenue Code  to get Hours Option from the Rules Tables
	select @hours_opt = JTDorPDFlag from dbo.EMUR 	with(nolock) where EMCo = @emco and RulesTable = @save_rulestable
	if @@rowcount <> 1
	begin
		select @msg_variable = case @save_equip_catgy_templt_type when 'catgy' then 'Category: ' + isnull(@catgy,'') else 'Equipment: ' + isnull(@save_equip,'') end
		select @errmsg = 'RulesTable: ' + isnull(@save_rulestable,'') + ' in auto template: ' + isnull(@autotemplate,'') +
						' for ' + isnull(@msg_variable,'') + ' does not exist.'
		select @rcode = 1
		goto vspexit
	END
				
	 --1. When Est Out Date is not null and Template Use Est Out Date is Yes, get total billable hours from Period Beginning Date to  Est Out Date 
	 --2. The Total billable hours returned here determines the Rules Table/Seq/ Revenue Code to be used  Skip if  Est Out Date has no value  
	 --3.  Auto Template value required, UseEstDateOut Option must equal 'Y' and EM Location Transfer record must have a value in EstOut Date column
	 --4.  @save_... variables are the Previous Equipment/JCCo/Job EM Location Tranfer record
	 --5.  @x_....variables are dead or unused variable/parameter outputs. 
	if isnull(@autotemplate,'') <> '' and isnull(@save_use_est_out_date_YN,'N') = 'Y' 
	and isnull(@save_estdateout,'')<>''	and @save_estdateout >@period_enddate
	BEGIN
		--This gets the total billable hours between the Equipment location transfer date and the estimated out date.
		exec @rcode = dbo.vspEMBFAutoInsertCalcBillHours  @emco, @autotemplate, @save_equip, @catgy, @save_jcco, @save_job, 
		@period_begindate, @save_estdateout, @save_datein,@save_datein, @save_estdateout,@save_estdateout,
		@date1, @date2, @date3, @date4, @date5, @date6, 
		@billsats, @billsuns, @x_equip_catgy_templt_type output,@x_startbillingintrnsfrindate output, @x_useestoutdate output ,  
		@x_rulestable output, @x_phase output, 	@x_maxperpd output, @x_maxpermth output, 
		@x_maxperjob output, @x_minperpd output,@totalesthours output, @errmsg OUTPUT
		if @rcode = 1 
		begin
			goto vspexit
		END
		
		--IF @save_equip = '30103'
		--BEGIN
		--	SELECT @errmsg = CONVERT (varchar,@totalesthours),@rcode = 1
		--	GOTO vspexit
		--END
	end
	
	/*Issue 137105 START*/
	--1.  Start Billing on Transfer Date is intended for Equipment that is on site for extended period of time over multiple billing periods
	--2.  Get Current Billing hours for Transfer Mths. used to determine Max Billed Mth Amts for Prev and Current Transfer Mths
	--3.  If Equipment using this option and is transferred on and off the job multiples times in the billing period will cause Prev/Current Transfer Months Billed Amts
	--to be calculated incorrectly.  There is no way at this time to determine the actual beginning transfer date was.
	--4.  If Billing Period with Max Bill Amounts per month  includes pervious and current months.  Need to determine proper amounts to be billed 
	-- both months.   This is where Revenue amount may not equal revenue units.  
	 if isnull(@save_start_billing_on_trnsfr_date_YN,'N') = 'Y'
	begin
			----This is when Transfer Mth EndDate falls between beg/end priod dates
			--needed with Max Bill Amount per Month opiton form Auto Usage Template for the pervious month
		if @save_datein <= @period_begindate  and @prev_mthbegindate < @mth_begin_date 
		begin
			--Set last date to example:  11/10/2009 23:59:59:, this is to get the correct billable hours for ending period date / previous ending month
			select @mthenddate_time =  dateadd(hour,23,@prev_mthenddate)
			select @mthenddate_time =  dateadd(minute,59, @mthenddate_time)		
					
			--Get the current billing hours for the Previous Transfer Mth
			exec @rcode = dbo.vspEMBFAutoInsertCalcBillHours  @emco, @autotemplate, @save_equip, @catgy, @save_jcco, @save_job, 
			@period_begindate, @period_enddate, @save_datein,@save_timein,@prev_mthenddate,@mthenddate_time,
			@date1, @date2, @date3, @date4, @date5, @date6, 
			@billsats, @billsuns, @x_equip_catgy_templt_type output,@x_startbillingintrnsfrindate output, @x_useestoutdate output ,  
			@x_rulestable output, @x_phase output, 	@x_maxperpd output, @x_maxpermth output, 
			@x_maxperjob output, @x_minperpd output,@prev_transfer_mth_post_hours output, @errmsg output
			if @rcode = 1
			begin
				goto vspexit
			end
		end 
			
		--Set last date to example:  11/10/2009 23:59:59:, this get the correct billable hours for ending period date / current period month
		--needed with Max Bill Amount per Month opiton form Auto Usage Template for the current month
		select @mthenddate_time =  dateadd(hour,23,@mth_end_date)
		select @mthenddate_time =  dateadd(minute,59,@mthenddate_time)
			
		--Get the current billing hours for the Current Transfer Mth
		exec @rcode = dbo.vspEMBFAutoInsertCalcBillHours  @emco, @autotemplate, @save_equip, @catgy, @save_jcco, @save_job, 
		@period_begindate, @period_enddate, @mth_begin_date , @mth_begin_date ,@mth_end_date , @mthenddate_time,
		@date1, @date2, @date3, @date4, @date5, @date6, 
		@billsats, @billsuns, @x_equip_catgy_templt_type output,@x_startbillingintrnsfrindate output, @x_useestoutdate output ,  
		@x_rulestable output, @x_phase output, 	@x_maxperpd output, @x_maxpermth output, 
		@x_maxperjob output, @x_minperpd output,@curr_transfer_mth_post_hours output, @errmsg output
		if @rcode = 1
		begin
			goto vspexit
		end
	end
	/*Issue 137105 END*/
		
	--Get the last seq in the Rules Table
	select @maxseq = max(Sequence) from dbo.EMUD with(nolock)where EMCo = @emco and RulesTable = @save_rulestable
	--Set @cnt varialbe to cycle through Rules Table
	select @cnt = 1

--1.  Select Revenue Code
	--2.  Cycle through the Sequences in the Rules Table until the on-site(job) hours fall within morethan/less than range
	While @cnt <= @maxseq
	Begin
		If IsNull(@save_use_est_out_date_YN,'N') = 'Y' 
			--Est Out Date required to use Auto Template Option
			and isnull(@save_estdateout,'')<>'' 	and 
			((/*(Check to see if equipment is still on site*/
		      isnull(@save_dateout ,'')=''
			/*Check to see if Equipment is intended to be on site longer than billing period*/
			and isnull(@save_estdateout,'01/01/1950') > @period_enddate)
			or
			/*This allows Equipment transfers that have been on and off the same job site multiple times
			in the billing period to be billed with the same revenue code*/
			( isnull(@save_dateout ,'')<>'' and @save_dateout <= @period_enddate ))
			begin
				--1. Get Rev Code if EstDateOutYN is checked "Yes" use the matching Seq in the Rules Table 
				--based on (more than hours)/ (less then hours)
				select @cnt = Sequence ,@revcode = RevCode, @morethan = MoreThanHrs, @lessthan = LessThanHrs
				 from dbo.EMUD with(nolock)	where EMCo = @emco and RulesTable = @save_rulestable 
				/*Less than hours should be 999,999.99 on the last Rules Table Seq*/
				-- 140795 
				AND @totalesthours> MoreThanHrs   and   @totalesthours<= LessThanHrs
				--and  ((@totalesthours> MoreThanHrs   and   @totalesthours<= LessThanHrs) OR @totalesthours=0)
				if @@rowcount = 1
					--2.  Now exit while statement
					begin 
						select  @maxseq  = @cnt
					end
				--else
				--	begin
				--		--3.  If  the Rules table doesn't have a qualifying sequence based on (more than hours)/ (less then hours)
				--		--then select the last sequence in the Rules Table.  This may occur if the (Less Than) value isn't 999,999.99'
				--		select @revcode = RevCode,@morethan = MoreThanHrs, @lessthan = LessThanHrs	from dbo.EMUD with(nolock)
				--		where EMCo = @emco and RulesTable = @save_rulestable and Sequence = @maxseq
				--	end
			end
		else
			begin
				select @revcode = RevCode,@morethan = MoreThanHrs, @lessthan = LessThanHrs	from dbo.EMUD with(nolock)
				where EMCo = @emco and RulesTable = @save_rulestable and Sequence = @cnt
			END
			
			--Check Job to Date and Total Hours to select appropriate Rev Code
				if @hours_opt = 'J' and (@jtdhours + @totalhours) > @morethan and (@jtdhours + @totalhours) <= @lessthan
				begin
					select @revcode = RevCode from dbo.EMUD with(nolock) where EMCo = @emco and RulesTable = @save_rulestable and Sequence = @cnt
					select @cnt = @maxseq
				end
				--Check Period to Date and Total Hours to select appropriate Rev Code
				if @hours_opt = 'P' and @pdhours + @totalhours  > @morethan and @pdhours  +@totalhours <= @lessthan
				begin
					select @revcode = RevCode from dbo.EMUD with(nolock) where EMCo = @emco and RulesTable = @save_rulestable and Sequence = @cnt
					select @cnt = @maxseq
				end
			
		select @cnt = @cnt + 1
	end
	
	--1.  Calculate billing rate 
	--2.  Get Revenue Code Info hours per time units factor, Basis and MonthlyRevCodeYN
	select @timefactor = HrsPerTimeUM ,@basis = Basis,@monthlyrevcodeYN = MonthlyRevCodeYN from dbo.EMRC with(nolock)
	where EMGroup = @emgroup and RevCode = @revcode
     
     --If Hours/time units in EMRC = 0 throw error.
	if @@rowcount <> 1 or (@@rowcount = 1 and @basis = 'U') or (@timefactor = 0 and @basis = 'H')
	begin
		select @errmsg = 'Revenue code: ' + isnull(@revcode,'') + ' in rules table: ' + isnull(@save_rulestable,'') + ' is invalid.', @rcode = 1
		goto vspexit
	end
        	
---- Get Revenue Rate and UM values based on Usage Setup Tables
exec @rcode = dbo.bspEMRevRateUMDflt @emco, @emgroup, 'J', @save_equip, @catgy, @revcode, @save_jcco, @save_job,
	@rate = @rate output, @time_um = @time_um output, @msg = @errmsg output
if @rcode <> 0
	BEGIN
	GOTO vspexit
	END
     
	--Convert hours based on the Time Factor in EMRC (Revenue Code).  Can't divide by 0 - backed out
	select @posthours = @totalhours/@timefactor

	/*Issue 137105 START*/	
	--Conver hous based on the Time Factor for Previous and Current Transfer Mths
	If isnull(@save_start_billing_on_trnsfr_date_YN,'N') = 'Y'
	begin
	/*Issue 137105*/
	select @prev_mth_post_hours = (isnull(@prev_mth_post_hours,0)+isnull(@prev_transfer_mth_post_hours,0))/@timefactor,
		@curr_mth_post_hours = (isnull(@curr_mth_post_hours,0)+isnull(@curr_transfer_mth_post_hours,0))/@timefactor
	end

		--calculate this period's bill amount 
	--Issue 131667 If Monthly Rev Code HrsPerTimeUM is 1
		If IsNull(@monthlyrevcodeYN,'N') = 'Y' 
		begin
			If @posthours > 0 and @posthours/160 < 1
				begin
				--Adjusts Billing Rate when billing Monthly Rev Code on Weekly/Bi-Weekly Periods
				----TFS-55825
				SET @posthours = (@posthours/160 )
				SET @amount = @rate * @posthours
				----select @amount =  @rate * (@posthours/160 )
				end
			else
				begin
				--Issue 131667 If Monthly Rev Code HrsPerTimeUM is 1
				select @amount = @rate, @posthours = 1
				end
			
			--calculate previous and current transfer mths bill amounts
			If isnull(@save_start_billing_on_trnsfr_date_YN,'N') = 'Y'  
				begin
				If @prev_mth_post_hours > 0 and @prev_mth_post_hours/160 < 1 
					begin
					--Adjusts Billing Rate when billing Monthly Rev Code on Weekly/Bi-Weekly Periods
					----TFS-55825
					SET @prev_mth_post_hours = (@prev_mth_post_hours/160)
					SET @prev_transfer_amt = @rate * @prev_mth_post_hours
					----select @prev_transfer_amt = @rate * (@prev_mth_post_hours/160 )
					end
				else
					begin
					--Issue 131667 If Monthly Rev Code HrsPerTimeUM is 1
					select @prev_transfer_amt = @rate, @prev_mth_post_hours = 1 
					end
					
				If @curr_mth_post_hours > 0 and @curr_mth_post_hours/160 < 1
					begin
					--Adjusts Billing Rate when billing Monthly Rev Code on Weekly/Bi-Weekly Periods
					----TFS-55825
					SET @curr_mth_post_hours = (@curr_mth_post_hours/160)
					SET @curr_transfer_amt = @rate * @curr_mth_post_hours
					----select @curr_transfer_amt =  @rate * (@curr_mth_post_hours/160 )
					end
				else
					begin
					--Issue 131667 If Monthly Rev Code HrsPerTimeUM is 1
					select @curr_transfer_amt = @rate , @curr_mth_post_hours = 1 
					end
			end
		end
	else
		begin
				--Normal Calculation
				select @amount = @rate * @posthours
				
				select @prev_transfer_amt = @rate * @prev_mth_post_hours
				select @curr_transfer_amt =  @rate * @curr_mth_post_hours
			end
     
     --Make sure the Auto Template's requirements are met 
	if isnull(@save_minperpd,0) <> 0 and @amount + @pdamount < @save_minperpd select @amount = @save_minperpd - @pdamount
	if isnull(@save_maxperpd,0) <> 0 and @amount + @pdamount > @save_maxperpd select @amount = @save_maxperpd - @pdamount
	
	--This where we calc @maxpermth to either @mtdamount (batch) or @transmtdamount (transfer date)
	If isnull(@save_start_billing_on_trnsfr_date_YN,'N') = 'N'  
		--Standard Max Billed Mth amount Calc
		begin
			if isnull(@save_maxpermth,0) <> 0 and @amount + @mtdamount > @save_maxpermth 
			begin 
				select @amount = @save_maxpermth - @mtdamount		
			end
		end
	else
		--Prev and Curent  Max Billed Mth amount Calc
		begin
			if isnull(@save_maxpermth,0) <> 0 and   @prev_transfer_amt+@prev_transfer_billed_mth_amt  > @save_maxpermth   
			begin
					select @prev_transfer_amt =  @save_maxpermth -@prev_transfer_billed_mth_amt 
			end
			
			if isnull(@save_maxpermth,0) <> 0 and   @curr_transfer_amt+@curr_transfer_billed_mth_amt> @save_maxpermth   
			begin
				select @curr_transfer_amt =  @save_maxpermth - @curr_transfer_billed_mth_amt 
			end
			
			select @amount = @prev_transfer_amt + @curr_transfer_amt 
		end
		
	/*Issue 137105 END*/
	
	--Determine Max Amount Per Job (Issue 137833)
	if isnull(@save_maxperjob,0) <> 0 and @amount + @jtdamount > @save_maxperjob select @amount = @save_maxperjob - @jtdamount
     
	--Validate the Job/Phase/Cost type
	exec @rcode = dbo.bspARMRDefaultGLAcctGet @save_jcco, @save_job, @save_phase, @jcct, @defglacct=@offsetacct output, @msg=@errmsg output
	if @rcode <> 0 
	begin
		goto vspexit
	end
	
----TK-16407
BEGIN TRY				
if @posthours <> 0
	BEGIN
	select @phasegroup = PhaseGroup from dbo.bHQCO with(nolock) where HQCo = @save_jcco
				
	----Delete any duplicate auto usage transactions incase of previously run EM Auto Usage batch
	if @deleteusage = 'Y'
		BEGIN
		declare @usagedate bDate
		SELECT @usagedate = CASE WHEN ISNULL(@post_date,'') <> '' THEN @post_date ELSE @actdate END
		
		---- delete EMBF records
		DELETE FROM dbo.EMBF
		WHERE Co = @emco AND Mth = @mth 
			AND BatchId = @batchid 
			AND ActualDate = @usagedate
			AND isnull(JCCo,'') = isnull(@save_jcco,'') 
			AND isnull(Job,'') = isnull(@save_job,'')
			AND Equipment = @save_equip 
			AND RevCode = @revcode
			AND Source = 'EMRev' 
		
		---- delete EMBF records for attached equipment
		DELETE FROM dbo.bEMBF
		FROM dbo.bEMBF EMBF
		INNER JOIN dbo.bEMEM EMEM ON EMEM.EMCo = EMBF.Co AND EMEM.Equipment = EMBF.Equipment
		WHERE EMBF.Co = @emco AND EMBF.Mth = @mth
			AND EMBF.BatchId = @batchid
			AND EMBF.ActualDate = @usagedate
			AND isnull(EMBF.JCCo,'') = isnull(@save_jcco,'') 
			AND isnull(EMBF.Job,'') = isnull(@save_job,'') 
			AND EMEM.AttachToEquip= @save_equip
			AND isnull(EMEM.AttachPostRevenue,'N') = 'Y'
			AND EMBF.RevCode = @revcode 
			AND EMBF.Source = 'EMRev'

		---- pull in EMRD records for delete that are found
		---- add Transaction to batch 
		INSERT INTO	dbo.bEMBF (Co, Mth, BatchId, BatchSeq, Source, Equipment, RevCode, EMTrans, BatchTransType,
				EMTransType, ComponentTypeCode, Component, EMGroup, CostCode, EMCostType, ActualDate,
				Description, GLCo, GLOffsetAcct, PRCo, PREmployee, WorkOrder, WOItem, UM, JCCo, Job, 
				PhaseGrp, JCPhase, JCCostType, RevRate, MeterTrans, CurrentOdometer, PreviousOdometer,
				CurrentHourMeter, PreviousHourMeter, RevWorkUnits, RevTimeUnits, RevDollars, OffsetGLCo, 
				RevUsedOnEquipCo, RevUsedOnEquipGroup, RevUsedOnEquip, TimeUM, OldEquipment, OldRevCode, 
				OldEMTrans,OldEMTransType, OldComponentTypeCode, OldComponent, OldEMGroup, OldCostCode, 
				OldEMCostType, OldActualDate, OldGLCo, OldGLTransAcct, OldGLOffsetAcct, OldPRCo, OldPREmployee, 
				OldWorkOrder, OldWOItem, OldUM, OldRevTransType, OldJCCo, OldJob, OldPhaseGrp, OldJCPhase, 
				OldJCCostType, OldRevRate, OldCurrentOdometer, OldPreviousOdometer, OldCurrentHourMeter, 
				OldPreviousHourMeter, OldRevWorkUnits, OldRevTimeUnits, OldRevDollars, OldOffsetGLCo, 
				OldRevUsedOnEquipCo, OldRevUsedOnEquipGroup, OldRevUsedOnEquip, OldTimeUM, UniqueAttchID, PRCrew)

		SELECT EMRD.EMCo, @mth, @batchid,
				---- TK-16407 use row number to get batch seq. possible there is more than one EMRD record		
				ISNULL(max(h.BatchSeq),0) + ROW_NUMBER() OVER(ORDER BY EMRD.EMCo ASC, EMRD.Mth ASC, EMRD.Equipment ASC),
				'EMRev', EMRD.Equipment, EMRD.RevCode, EMRD.Trans, 'D', EMRD.TransType, EMRD.UsedOnComponentType,			    
				EMRD.UsedOnComponent, EMRD.EMGroup, EMRD.EMCostCode, EMRD.EMCostType, EMRD.ActualDate,EMRD. Memo,
				EMRD.GLCo, EMRD.ExpGLAcct, EMRD.PRCo, EMRD.Employee, EMRD.WorkOrder, EMRD.WOItem, EMRD.UM, EMRD.JCCo,
				EMRD.Job, EMRD.PhaseGroup, EMRD.JCPhase, EMRD.JCCostType, EMRD.RevRate, EMRD.MeterTrans,
				EMRD.OdoReading, EMRD.PreviousOdoReading, EMRD.HourReading, EMRD.PreviousHourReading,
				EMRD.WorkUnits, EMRD.TimeUnits, EMRD.Dollars, EMRD.ExpGLCo, EMRD.UsedOnEquipCo, EMRD.UsedOnEquipGroup,
				EMRD.UsedOnEquipment, EMRD.TimeUM, EMRD.Equipment, EMRD.RevCode, EMRD.Trans, EMRD.TransType,
				EMRD.UsedOnComponentType, EMRD.UsedOnComponent, EMRD.EMGroup, EMRD.EMCostCode, EMRD.EMCostType,
				EMRD.ActualDate, EMRD.GLCo, EMRD.RevGLAcct, EMRD.ExpGLAcct, EMRD.PRCo, EMRD.Employee, EMRD.WorkOrder,
				EMRD.WOItem, EMRD.UM, EMRD.TransType, EMRD.JCCo, EMRD.Job, EMRD.PhaseGroup, EMRD.JCPhase,
				EMRD.JCCostType, EMRD.RevRate, EMRD.OdoReading, EMRD.PreviousOdoReading, EMRD.HourReading,
				EMRD.PreviousHourReading, EMRD.WorkUnits, EMRD.TimeUnits, EMRD.Dollars,EMRD. ExpGLCo,
				EMRD.UsedOnEquipCo, EMRD.UsedOnEquipGroup, EMRD.UsedOnEquipment, EMRD.TimeUM, EMRD.UniqueAttchID,
				EMRD.PRCrew 
		FROM dbo.bEMRD EMRD
		LEFT JOIN dbo.bEMBF h ON h.Co = EMRD.EMCo AND h.Mth = EMRD.Mth AND h.BatchId = @batchid
		WHERE EMRD.EMCo = @emco AND EMRD.Mth = @mth AND EMRD.ActualDate = @usagedate
			AND EMRD.InUseBatchID IS NULL 
			AND isnull(EMRD.JCCo,'') = isnull(@save_jcco,'')
			AND isnull(EMRD.Job,'') = isnull(@save_job,'') 
			AND EMRD.Equipment = @save_equip
			AND EMRD.RevCode = @revcode
			AND EMRD.Source = 'EMRev'
		GROUP BY EMRD.EMCo, EMRD.Mth, EMRD.Equipment, EMRD.RevCode, EMRD.TransType,
				EMRD.UsedOnComponentType, EMRD.UsedOnComponent,	EMRD.EMGroup, EMRD.EMCostCode, EMRD.EMCostType, 
				EMRD.ActualDate, EMRD.Memo, EMRD.GLCo, EMRD.ExpGLAcct, EMRD.PRCo, EMRD.Employee,
				EMRD.WorkOrder, EMRD.WOItem, EMRD.UM, EMRD.JCCo, EMRD.Job, EMRD.PhaseGroup, EMRD.JCPhase, 
				EMRD.JCCostType, EMRD.RevRate, EMRD.MeterTrans, EMRD.OdoReading, EMRD.PreviousOdoReading, 
				EMRD.HourReading, EMRD.PreviousHourReading, EMRD.WorkUnits, EMRD.TimeUnits, EMRD.Dollars, 
				EMRD.ExpGLCo, EMRD.UsedOnEquipCo, EMRD.UsedOnEquipGroup, EMRD.UsedOnEquipment, EMRD.TimeUM,
				EMRD.Equipment, EMRD.RevCode, EMRD.Trans, EMRD.TransType, EMRD.UsedOnComponentType,
				EMRD.UsedOnComponent,	EMRD.EMGroup, EMRD.EMCostCode, EMRD.EMCostType, EMRD.ActualDate, 
				EMRD.GLCo, EMRD.RevGLAcct, EMRD.ExpGLAcct, EMRD.PRCo, EMRD.Employee, EMRD.WorkOrder, EMRD.WOItem, 
				EMRD.UM, EMRD.TransType, EMRD.JCCo, EMRD.Job, EMRD.PhaseGroup, EMRD.JCPhase, EMRD.JCCostType, 
				EMRD.RevRate, EMRD.OdoReading, EMRD.PreviousOdoReading, EMRD.HourReading, EMRD.PreviousHourReading,
				EMRD.WorkUnits, EMRD.TimeUnits, EMRD.Dollars, EMRD.ExpGLCo, EMRD.UsedOnEquipCo, EMRD.UsedOnEquipGroup,
				EMRD.UsedOnEquipment, EMRD.TimeUM, EMRD.UniqueAttchID, EMRD.PRCrew
		IF @@ROWCOUNT <> 0
			BEGIN
			----Need for deleting Revenue for Attached Equipoment
			-- add Transaction to batch 
			insert into dbo.bEMBF (Co, Mth, BatchId, BatchSeq, Source, Equipment, RevCode, EMTrans, BatchTransType,
					EMTransType, ComponentTypeCode, Component, EMGroup, CostCode, EMCostType, ActualDate, Description, GLCo,
					GLOffsetAcct, PRCo, PREmployee, WorkOrder, WOItem, UM, JCCo, Job, PhaseGrp, JCPhase, JCCostType,
					RevRate, MeterTrans, CurrentOdometer, PreviousOdometer, CurrentHourMeter, PreviousHourMeter,
					RevWorkUnits, RevTimeUnits, RevDollars, OffsetGLCo, RevUsedOnEquipCo, RevUsedOnEquipGroup,
					RevUsedOnEquip, TimeUM, OldEquipment, OldRevCode, OldEMTrans,OldEMTransType, OldComponentTypeCode,
					OldComponent, OldEMGroup, OldCostCode, OldEMCostType, OldActualDate, OldGLCo, OldGLTransAcct,
					OldGLOffsetAcct, OldPRCo, OldPREmployee, OldWorkOrder, OldWOItem, OldUM, OldRevTransType,
					OldJCCo, OldJob, OldPhaseGrp, OldJCPhase, OldJCCostType, OldRevRate,
					OldCurrentOdometer, OldPreviousOdometer, OldCurrentHourMeter, OldPreviousHourMeter,
					OldRevWorkUnits, OldRevTimeUnits, OldRevDollars, OldOffsetGLCo, OldRevUsedOnEquipCo,
					OldRevUsedOnEquipGroup, OldRevUsedOnEquip, OldTimeUM, UniqueAttchID,PRCrew)

			SELECT EMRD.EMCo, @mth, @batchid,
					---- TK-16407 use row number to get batch seq. possible there is more than one attachment		
					ISNULL(max(h.BatchSeq),0) + ROW_NUMBER() OVER(ORDER BY EMRD.EMCo ASC, EMRD.Mth ASC, EMRD.Equipment ASC),
					'EMRev', EMRD.Equipment, EMRD.RevCode, EMRD.Trans, 'D', EMRD.TransType,
					EMRD.UsedOnComponentType, EMRD.UsedOnComponent,	EMRD.EMGroup, EMRD.EMCostCode, EMRD.EMCostType, 
					EMRD.ActualDate, EMRD.Memo, EMRD.GLCo, EMRD.ExpGLAcct, EMRD.PRCo, EMRD.Employee,
					EMRD.WorkOrder, EMRD.WOItem, EMRD.UM, EMRD.JCCo, EMRD.Job, EMRD.PhaseGroup, EMRD.JCPhase, 
					EMRD.JCCostType, EMRD.RevRate, EMRD.MeterTrans, EMRD.OdoReading, EMRD.PreviousOdoReading, 
					EMRD.HourReading, EMRD.PreviousHourReading, EMRD.WorkUnits, EMRD.TimeUnits, EMRD.Dollars, 
					EMRD.ExpGLCo, EMRD.UsedOnEquipCo, EMRD.UsedOnEquipGroup, EMRD.UsedOnEquipment, EMRD.TimeUM,
					EMRD.Equipment, EMRD.RevCode, EMRD.Trans, EMRD.TransType, EMRD.UsedOnComponentType,
					EMRD.UsedOnComponent,	EMRD.EMGroup, EMRD.EMCostCode, EMRD.EMCostType, EMRD.ActualDate, 
					EMRD.GLCo, EMRD.RevGLAcct, EMRD.ExpGLAcct, EMRD.PRCo, EMRD.Employee, EMRD.WorkOrder, EMRD.WOItem, 
					EMRD.UM, EMRD.TransType, EMRD.JCCo, EMRD.Job, EMRD.PhaseGroup, EMRD.JCPhase, EMRD.JCCostType, 
					EMRD.RevRate, EMRD.OdoReading, EMRD.PreviousOdoReading, EMRD.HourReading, EMRD.PreviousHourReading,
					EMRD.WorkUnits, EMRD.TimeUnits, EMRD.Dollars, EMRD.ExpGLCo, EMRD.UsedOnEquipCo, EMRD.UsedOnEquipGroup,
					EMRD.UsedOnEquipment, EMRD.TimeUM, EMRD.UniqueAttchID, EMRD.PRCrew 
			FROM dbo.bEMRD EMRD
			INNER JOIN dbo.bEMEM EMEM ON EMRD.EMCo=EMEM.EMCo and EMRD.Equipment = EMEM.Equipment
			LEFT JOIN dbo.bEMBF h ON h.Co = EMRD.EMCo AND h.Mth = EMRD.Mth AND h.BatchId = @batchid
			WHERE EMRD.EMCo = @emco and EMRD.Mth = @mth 
					and EMRD.ActualDate = @usagedate 
					and isnull(EMRD.JCCo,'') = isnull(@save_jcco,'') 
					and isnull(EMRD.Job,'') = isnull(@save_job,'') 
					AND EMEM.AttachToEquip = @save_equip 
					and isnull(EMEM.AttachPostRevenue,'N')='Y' 
					and EMRD.RevCode = @revcode 
					and EMRD.Source = 'EMRev' 
			GROUP BY EMRD.EMCo, EMRD.Mth, EMRD.Equipment, EMRD.RevCode, EMRD.TransType,
					EMRD.UsedOnComponentType, EMRD.UsedOnComponent,	EMRD.EMGroup, EMRD.EMCostCode, EMRD.EMCostType, 
					EMRD.ActualDate, EMRD.Memo, EMRD.GLCo, EMRD.ExpGLAcct, EMRD.PRCo, EMRD.Employee,
					EMRD.WorkOrder, EMRD.WOItem, EMRD.UM, EMRD.JCCo, EMRD.Job, EMRD.PhaseGroup, EMRD.JCPhase, 
					EMRD.JCCostType, EMRD.RevRate, EMRD.MeterTrans, EMRD.OdoReading, EMRD.PreviousOdoReading, 
					EMRD.HourReading, EMRD.PreviousHourReading, EMRD.WorkUnits, EMRD.TimeUnits, EMRD.Dollars, 
					EMRD.ExpGLCo, EMRD.UsedOnEquipCo, EMRD.UsedOnEquipGroup, EMRD.UsedOnEquipment, EMRD.TimeUM,
					EMRD.Equipment, EMRD.RevCode, EMRD.Trans, EMRD.TransType, EMRD.UsedOnComponentType,
					EMRD.UsedOnComponent,	EMRD.EMGroup, EMRD.EMCostCode, EMRD.EMCostType, EMRD.ActualDate, 
					EMRD.GLCo, EMRD.RevGLAcct, EMRD.ExpGLAcct, EMRD.PRCo, EMRD.Employee, EMRD.WorkOrder, EMRD.WOItem, 
					EMRD.UM, EMRD.TransType, EMRD.JCCo, EMRD.Job, EMRD.PhaseGroup, EMRD.JCPhase, EMRD.JCCostType, 
					EMRD.RevRate, EMRD.OdoReading, EMRD.PreviousOdoReading, EMRD.HourReading, EMRD.PreviousHourReading,
					EMRD.WorkUnits, EMRD.TimeUnits, EMRD.Dollars, EMRD.ExpGLCo, EMRD.UsedOnEquipCo, EMRD.UsedOnEquipGroup,
					EMRD.UsedOnEquipment, EMRD.TimeUM, EMRD.UniqueAttchID, EMRD.PRCrew
			END
			
	-- if @deleteusage <> 'N''
	END	
							
	--Get the latest sequence number 
	select @seq = isnull(max(BatchSeq),0) + 1 from bEMBF where Co = @emco and Mth = @mth and BatchId = @batchid

	insert into bEMBF (Co, Mth, BatchId, BatchSeq, EMGroup, BatchTransType, EMTransType, Source, Equipment, RevCode,
			ActualDate, GLCo, GLOffsetAcct, PRCo, PREmployee,
			JCCo, Job, PhaseGrp,
			JCPhase, JCCostType, RevRate, UM, RevWorkUnits, TimeUM, RevTimeUnits,
			RevDollars, OffsetGLCo, PreviousHourMeter, CurrentHourMeter, PreviousOdometer, CurrentOdometer,AutoUsage)
	values(@emco, @mth, @batchid, @seq, @emgroup, 'A', 'J', 'EMRev', @save_equip, @revcode,
			case when isnull(@post_date,'') <> '' then @post_date else @actdate end, @glco, @offsetacct, @prco, @employee,
			@save_jcco, @save_job, @phasegroup,
			@save_phase, @jcct, @rate, null, 0, @time_um, @posthours,
			@amount, @offsetglco, isnull(@hourmeter,0), isnull((@hourmeter + @totalhours),0), @odometer, 0,'Y')
	END
	
---- end of post hours	
-- if @posthours <> 0
END TRY
BEGIN CATCH
	-- RETURN FAILURE --
	SET @rcode = 1
	SET @errmsg = ERROR_MESSAGE()
	GOTO vspexit
END CATCH
----TK-16407
		
--Reset Equipment/JCCo/Job totalhours variable 
select @totalhours = 0,@prev_transfer_billed_mth_amt =0/*<=129345 =>*/ ,@curr_transfer_billed_mth_amt =0
if @lastrec = 'Y'
	begin
	goto loop_end
	END
END	

/********************************************************************************
1. The following section calculates the number of job hours for one EMLH record 
                                                                              
2. If more than one EMLH record is assigned to a single psuedo key,             
the code flow will continue to cycle through the cursor while @totalhours    
will store the running total for that equipment's time on the job            
*******************************************************************************/
--Start reset psuedo key 
select @save_equip = @to_equip, @save_jcco = @to_jcco, @save_job = @to_job, @post_date = @dateout,
@save_datein =@datein, @save_timein = @timein,@save_dateout =@dateout, @save_timeout = @timeout, @save_estdateout=@to_estdateout,
@save_use_est_out_date_YN = 'N' , @save_start_billing_on_trnsfr_date_YN = 'N',@save_equip_catgy_templt_type = '', 
--Reinitialize Equipment, AutoTemplate, JTD, PTD, MTD, and Rev variables 
@jtdamount = 0, @jtdhours = 0, @pdhours = 0, @pdamount = 0, @mtdamount = 0, @emrd_amount = 0,
@hours = 0, @cnt = 0, @indayflag = null, @outdayflag = null, @maxseq = 0,
@mth_begin_date = null, @mth_end_date=null,   @prev_mthbegindate =null, @prev_mthenddate =null  

--Get EM Equipment Master Info
select @catgy = Category, @dept = Department, @status = Status, @type = Type,@prco = PRCo, @employee = Operator, 
@jcct = UsageCostType, @odometer = OdoReading, @hourmeter = HourReading from dbo.EMEM with(nolock)
where EMCo = @emco and Equipment = @to_equip
if @@rowcount = 0 or @status = 'I' or @type = 'C' or (@@rowcount = 1 and isnull(@catgy,'') < isnull(@begincatgy,'')) 
or (@@rowcount = 1 and isnull(@catgy,'') > isnull(@endcatgy,'')) 
begin
	goto cycle
End

--JC Cost Type required form EM Equipment Master 
if @jcct is null
begin
	select @errmsg = 'Missing Usage Cost Type in Equip Master for Equip ' + isnull(@to_equip,'') + '.', @rcode = 1
	goto vspexit
end

--Get the JCCo  GL Company
select @offsetglco = GLCo from dbo.JCCO with(nolock) where JCCo = @to_jcco

--Get Job Templates  (Auto Use and Revenue Templates
select @autotemplate = EMJT.AUTemplate from dbo.EMJT with(nolock) where EMCo = @emco and JCCo = @to_jcco and Job = @to_job
if @@rowcount = 0 or (@@rowcount = 1 and @autotemplate < @begintemplate)  or (@@rowcount = 1 and @autotemplate > @endtemplate) 
begin
	goto cycle
end

if isnull(@autotemplate,'') <> ''
begin
	--Calculates and gets Billable Hours for Billing Period
	--Returns Auto Template info to create EMBF Auto Uasage batch record
	exec @rcode = dbo.vspEMBFAutoInsertCalcBillHours @emco, @autotemplate, @to_equip, @catgy, @to_jcco, @to_job, 
	@period_begindate, @period_enddate, @datein,@timein, @dateout,@timeout,
	@date1, @date2, @date3, @date4, @date5, @date6, @billsats, @billsuns, 
	@save_equip_catgy_templt_type output, @save_start_billing_on_trnsfr_date_YN output,@save_use_est_out_date_YN output , @save_rulestable output, @save_phase output, 
	@save_maxperpd output, @save_maxpermth output, @save_maxperjob output, @save_minperpd output,
	@hours output, @errmsg output
	if @rcode = 1
	begin
		goto vspexit
	end
end

--Start Billing on Transfer Date is intended for Equipment that is on site for extended period of time over multiple billing periods
--Determine Current Transfer Billing Month beginning and ending dates
if isnull(@save_start_billing_on_trnsfr_date_YN,'N') = 'Y'
begin
	Select @mth_begin_date = case 
	when IsNull(@save_dateout,@period_enddate) =DateAdd(Month, DateDiff(Month,@save_datein,IsNull(@save_dateout,@period_enddate)),@save_datein)	then
			IsNull(@save_dateout,@period_enddate) 
	when IsNull(@save_dateout,@period_enddate) >DateAdd(Month, DateDiff(Month,@save_datein,IsNull(@save_dateout,@period_enddate)),@save_datein)	then 
			DateAdd(Month, DateDiff(Month,@save_datein,IsNull(@save_dateout,@period_enddate)),@save_datein)
	else 
			DateAdd(Month,DateDiff(Month,DateAdd(Month,1,@save_datein),IsNull(@save_dateout,@period_enddate)),@save_datein) 
	end,
	@mth_end_date=case 
	when IsNull(@save_dateout,'') = ''  and @period_enddate <=  DateAdd(Day,-1,DateAdd(month, DateDiff(Month,@save_datein,IsNull(@save_dateout,@period_enddate)),@save_datein)) then
		DateAdd(Day,-1,DateAdd(month, DateDiff(Month,@save_datein,IsNull(@save_dateout,@period_enddate)),@save_datein)) 
	when IsNull(@save_dateout,'') = ''  and @period_enddate > DateAdd(Day,-1,DateAdd(month, DateDiff(Month,@save_datein,IsNull(@save_dateout,@period_enddate)),@save_datein)) then
		DateAdd(day, -1,DateAdd(Month, DateDiff(Month,@save_datein,DateAdd(Month,1,IsNull(@save_dateout,@period_enddate))),@save_datein))
	when	IsNull(@save_dateout,@period_enddate) >= DateAdd(Month, DateDiff(Month,@save_datein,IsNull(@save_dateout,@period_enddate)),@save_datein)	then
		DateAdd(day, -1,DateAdd(Month, DateDiff(Month,@save_datein,DateAdd(Month,1,IsNull(@save_dateout,@period_enddate))),@save_datein))
			else
		DateAdd(Day,-1,DateAdd(month, DateDiff(Month,@save_datein,IsNull(@save_dateout,@period_enddate)),@save_datein)) end
	--determine previous transfer month	
	if @mth_begin_date>= @period_begindate and @mth_begin_date <= @period_enddate
		begin
			select @prev_mthbegindate = dateadd(Month,-1,@mth_begin_date) , @prev_mthenddate = dateadd(Month,-1,@mth_end_date) 
		end
	else
		begin 
			select @prev_mthbegindate = @mth_begin_date, @prev_mthenddate =@mth_end_date 
		end
End    
 

/****************************************************************************
Accumulate EMRD revenue values for a piece of equipment and or a job 
for the batch month/job  or transfer month*
***************************************************************************/
select @cnt = 0
select @emrd_mth = min(Mth) from dbo.EMRD with(nolock)
where EMCo = @emco and Equipment = @to_equip and JCCo = @to_jcco and Job = @to_job
WHILE @emrd_mth is not null
BEGIN
	select @trans = min(Trans) from dbo.EMRD with(nolock)
	where EMCo = @emco and Equipment = @to_equip and JCCo = @to_jcco and Job = @to_job and Mth = @emrd_mth
	While @trans is not null
	Begin
		select @actualdate = ActualDate, @revcode = RevCode, @timeunits = TimeUnits, @emrd_amount = isnull(Dollars,0)	from dbo.EMRD with(nolock)
		where EMCo = @emco and Equipment = @to_equip and JCCo = @to_jcco and Job = @to_job and Mth = @emrd_mth and Trans = @trans
     
		--get hours per unit for revcode
		select @timefactor = HrsPerTimeUM ,@basis = Basis,@monthlyrevcodeYN = MonthlyRevCodeYN from dbo.bEMRC with(nolock)
		where EMGroup = @emgroup and RevCode = @revcode     

		-- rev code must be hour based to be included
		if @@rowcount = 1 and @basis = 'H'
		begin
			if @actualdate <= @period_enddate 
			begin
				select @jtdamount = @jtdamount + @emrd_amount	
			end
			
			if @actualdate <= @period_enddate 
			begin
				select @jtdhours = @jtdhours + (@timeunits * @timefactor)
			end
			
			if @actualdate >= @period_begindate and @actualdate <= @period_enddate
			begin
				select @pdhours = @pdhours + (@timeunits * @timefactor)
				select @pdamount = @pdamount + @emrd_amount
			end
			
			If @emrd_mth = @mth 
			begin
				--Calc Amounts Billed Month in Batch Mth.  Original--
				select @mtdamount = @mtdamount + @emrd_amount
			end
			
			--Start Billing on Transfer Date is intended for Equipment that is on site for extended period of time over multiple billing periods
			IF  isnull(@save_start_billing_on_trnsfr_date_YN,'N') = 'Y'
			BEGIN
				--Calc Amounts Billed in Transfer Mth.  New
				If  @actualdate>=  @prev_mthbegindate and  @actualdate<= @prev_mthenddate 
				begin
					select @prev_transfer_billed_mth_amt =@prev_transfer_billed_mth_amt + @emrd_amount,
					@prev_mth_post_hours = @prev_mth_post_hours+ (@timeunits * @timefactor) /*Issue 137105*/
					
				end
				
				If  @actualdate>=  @mth_begin_date and  @actualdate<= @mth_end_date 
				begin
					select @curr_transfer_billed_mth_amt = @curr_transfer_billed_mth_amt+ @emrd_amount,
					@curr_mth_post_hours=@curr_mth_post_hours+ (@timeunits * @timefactor) /*Issue 137105*/
				end
			end 
		end
     
		select @trans = min(Trans)	from dbo.EMRD with(nolock)
		where EMCo = @emco and Equipment = @to_equip and JCCo = @to_jcco and Job = @to_job and Mth = @emrd_mth and Trans > @trans
	End

	select @emrd_mth = min(Mth)	from dbo.EMRD with(nolock)
	where EMCo = @emco and Equipment = @to_equip and JCCo = @to_jcco and Job = @to_job and Mth > @emrd_mth
END

--keep running total of this period's hours
select @totalhours = isnull(@totalhours,0) + isnull(@hours,0)

goto cycle

--GET OUT OF cycle CURSOR 
loop_end:

/* check to see if anything was added to the batch table */
if not exists(select 1 from dbo.EMBF where Co = @emco and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'No Equipment codes fall within Auto Usage specifications.' + char(13) + 'No records have been processed', @rcode = 1
	end
     
vspexit:
	if @opencursor = 1
		BEGIN
		close bcEMLH
		deallocate bcEMLH
		END

	return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspEMBFAutoInsert] TO [public]
GO
