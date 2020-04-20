SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspHQPayTermsDateCalc]
/***********************************************************
* CREATED: cjw 7/22/97
* MODIFIED: CJW 10/18/97 
*           SAE 12/06/97
*			SAE  2/20/97
*			bc 09/23/99  happy fall !  added the description
*			DANF 07/18/2003  18691 Correct Default days.
*			DANF 10/2/2003 - 16725 Default date. Any change here may need to be made in bspHQPayTermsDateCalcDisplay
*			DANF 10/7/2004 - 25720 correct Default Due and Discount date
*			DANF 10/18/2004 - 23081 Discount and Due Date enhancement.
*			MV 12/05/08 - #131012 - RollAheadTwoMonths expanded to 3 months
* USAGE:
* Usually called from a transaction date field to bring back default 
* disc and due dates based on payment terms.

* INPUTS:
*   @payterms		Payment Terms
*	@invoicedate	Invoice Date
*   
* OUTPUTS:
*   @discdate		Discount Date
*   @duedate		Due Date
*   @discrate		Discount Rate
*   @msg			Payment Terms description or error message if failure
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
	(@payterms bPayTerms = null, @invoicedate bDate = null, @discdate bDate output,
	 @duedate bDate output, @discrate bPct output, @msg varchar(60) output)
as 
        
set nocount on

declare @rcode int, @type char(1), @daystilldue int, @discday int, 
	@dueopt int, @cuttoffday int, @discopt int, @daystilldisc int,
	@dueday int, @cutoffday int, @day int, @tmpprint varchar(30),
	@basedate bDate, @days int, @monthsout int,@RollAheadTwoMonths tinyint

select @rcode = 0
        
if @payterms is null
	begin
	select @msg = 'Missing Pay Terms', @rcode = 1
	goto bspexit
	end
if @invoicedate is null
	begin
	select @msg = 'Missing Invoice Date', @rcode = 1
	goto bspexit
	end
 
-- get Payment Terms info       
SELECT @discopt = DiscOpt, @daystilldisc = DaysTillDisc, @discday = DiscDay, 
	@dueopt = DueOpt, @dueday = DueDay, @cutoffday=CutOffDay, @discrate = DiscRate, 
	@daystilldue = DaysTillDue, @msg = Description, @RollAheadTwoMonths=RollAheadTwoMonths
FROM dbo.bHQPT with (nolock)
WHERE PayTerms = @payterms
if @@rowcount = 0
	begin
    select @msg = 'Invalid Pay Terms', @rcode = 1
    goto bspexit
    end
    
-- calculate discount and due dates    
SELECT @day = DATEPART(DAY, @invoicedate)		       /*get day of month	*/
/* we need to check cutoff day to see what month to use */
/* if day is past cutoffday then we add 2 months, otherwise just add one */
/* this is only used if doing calculation by date */
if @day > @cutoffday
	begin
	if @RollAheadTwoMonths = 1 select @monthsout=1
	if @RollAheadTwoMonths = 2 select @monthsout=2
	if @RollAheadTwoMonths = 3 select @monthsout=3
	end
--   if @RollAheadTwoMonths ='Y' select @monthsout=2 else select @monthsout=1
else
	begin
	if @RollAheadTwoMonths = 1 select @monthsout=0
	if @RollAheadTwoMonths = 2 select @monthsout=1
	if @RollAheadTwoMonths = 3 select @monthsout=2
	end
--   if @RollAheadTwoMonths ='Y' select @monthsout =1 else select @monthsout =0
    
/* Calculate discount date */

if @discopt = 1 /*number of days after invoice date*/
   begin
   select @discdate = DATEADD (DAY, @daystilldisc, @invoicedate)
   end

if @discopt = 2 /*use discount day */
	begin
	select @basedate = DATEADD(DAY, -(@day)+1, @invoicedate)   /*need to subtract out day of month*/
	select @basedate = DATEADD (MONTH, @monthsout, @basedate)     /*Add number of months to get to month due in*/
	select @discdate = DATEADD(DAY, @discday -1, @discdate)   /*add in due date*/
	select @days=@discday-2, @discdate = DATEADD(DAY, @discday -1, @basedate)     /*add in due date*/
   
	while @discday<>DATEPART(dd,@discdate) and @days>0  /* make sure we did not overstep month */
		select @days=@days-1, @discdate=DATEADD(DAY, @days, @basedate)     /*add in due date*/
	end
        
if @discopt = 3 /* none */
	begin
	select @discdate = NULL
	end
 
/* Calculate due date */
if @dueopt = 1
	begin
    select @duedate = DATEADD (DAY, @daystilldue, @invoicedate)
	end
        
if @dueopt = 2
   begin
   select @basedate = DATEADD(DAY, -(@day)+1, @invoicedate)   /*need to subtract out day of month*/
   select @basedate = DATEADD (MONTH, @monthsout, @basedate)  /*Add months out to get to propper month */
   /* add the month first so when we add in days we will be in the right month */
   select @days=@dueday-1, @duedate = DATEADD(DAY, @dueday -1, @basedate)     /*add in due date*/
      
	while DATEPART(mm,@basedate)<>DATEPART(mm,@duedate) and @days>0  /* make sure we did not overstep month */
         select @days=@days-1, @duedate=DATEADD(DAY, @days, @basedate)     /*add in due date*/
	/* changed to add two months based on request from QA */
	/* SAE changed back to 1 issue 1331 : MORE TO COME */
   end
              
if @dueopt = 3
   begin
   select @duedate = NULL
   end

/* If the default discount date  is greater thant the due date set the discount date equalt to the due date.*/
if isnull(@discdate,'')<>'' and isnull(@duedate,'')<>'' and @discdate>@duedate select @discdate=@duedate
                
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQPayTermsDateCalc] TO [public]
GO
