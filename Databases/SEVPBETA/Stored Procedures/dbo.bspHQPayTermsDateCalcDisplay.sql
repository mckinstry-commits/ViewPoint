SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQPayTermsDateCalcDisplay    Script Date: 8/28/99 9:34:53 AM ******/
CREATE  proc [dbo].[bspHQPayTermsDateCalcDisplay]
/***********************************************************
* CREATED BY	: DANF 07/11/2003
*				: DANF 10/7/2004 - 25720 correct Default Due and Discount date
*				: DANF 10/18/2004 - 23081 Discount and Due Date enhancement.
*				: TJL  08/31/2006 - 27639 6x Recode HQPT.  Add Column Names to Select at end
*				TJL 10/07/08 - Issue #129777, Form Coding for International Dates
*				MV 12/05/08 - #131012 - RollAheadTwoMonths expanded to 3 months
* USAGE:
* Display a list of due dates and discount dates based on payment term selected.
* INPUT PARAMETERS
*   payterms
*   transaction date
*   
* USED BY

* 
* OUTPUT PARAMETERS
*   Invoice date
*   due date
*   discount rate
*	     
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@payterms bPayTerms = null, @discopt int,@daystilldisc int, @discday int, @dueopt int,
	@dueday int, @cutoffday int, @discrate bPct, @daystilldue int, @RollAheadTwoMonths tinyint,
	@errmsg varchar(255) output)

as 

set nocount on

declare @rcode int, @invoicedate bDate, @discdate bDate, @duedate bDate,
	@month int, @type char(1), @day int, @tmpprint varchar(30), @basedate bDate, @days int, @monthsout int

select @rcode = 0

declare @TermsDates table
(
Invoice		datetime NULL,
Discount	datetime NULL,
Due			datetime NULL
)
     
--select @invoicedate = convert(datetime,convert(varchar(2),DATEPART ( mm , getdate() )) + '/01/' + convert(varchar(4),DATEPART ( yy , getdate() )),101)
select @invoicedate = convert(datetime,'02/01/' + convert(varchar(4),DATEPART ( yy , getdate() )),101)
     
select @month = month(@invoicedate)
     
while @month = month(@invoicedate)
	begin

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
	-------------------------------------------------------------------------------------                
	INSERT INTO @TermsDates VALUES (@invoicedate, @discdate, @duedate )
 
	--select @invoicedate, @discdate, @duedate
	--select 'Invoice' = @invoicedate, 'Discount' = @discdate, 'Due' = @duedate
 
	select @invoicedate = dateadd(d,1,@invoicedate)
 
 	end		-- End While

select  Invoice Invoice,
 		Discount Discount,
 		Due Due 
from @TermsDates
     
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQPayTermsDateCalcDisplay] TO [public]
GO
