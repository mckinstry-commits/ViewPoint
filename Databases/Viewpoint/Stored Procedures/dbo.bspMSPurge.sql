SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          procedure [dbo].[bspMSPurge]
   /************************************************************************
    * Created By: GF 01/23/2001
    * Modified By: RM 03/01/01 - Include deleted tickets in purge
    *				GG 05/30/01 - Use LocGroup and Loc restrictions in bMSTX purge, add purge counts to @msg
    *				GF 05/16/2005 - issue # 28697 if no location or locgroup restriction will not find invoice. null <> null
    *			    
    *
    * Called by the MS Purge program to delete detail based on the parameters
    * passed in. Month Closed must be equal to or earlier than the Last Month
    * Closed in SubLedgers.
    *
    * Input parameters:
    *  @msco           MS Company
    *  @purgetickets   Flag to indicate whether to purge tickets
    *  @purgehaulers   Flag to indicate whether to purge hauler time sheets
    *  @purgeinvoices  Flag to indicate whether to purge invoices
    *  @purgesales     Flag to indicate wheter to purge monthly sales
    *  @purgedeletedtickets - Flag to indicate whether to purge deleted tickets
    *  @xlocgroup      Location group purge restriction
    *  @xlocation      Location purge restriction
    *  @throughmth     Selected month to purge MS data through
    *
    * Output parameters:
    *  @rcode      0 =  successful, 1 = failure
    *
    *************************************************************************/
   (@msco bCompany = null, @purgetickets bYN = null, @purgehaulers bYN = null,
    @purgeinvoices bYN = null, @purgesales bYN = null, @purgedeletedtickets bYN = null,  @xlocgroup bGroup = null,
    @xfromloc bLoc = null, @throughmth bMonth, @msg varchar(500) output)
   as
   set nocount on
   
   declare @rcode int, @status tinyint, @mthclosed bMonth, @inusemth bMonth, @inusebatchid bBatchID,
           @glco bCompany, @clsdmth bMonth, @openhauler tinyint, @validcnt1 int, @validcnt2 int,
           @mth bMonth, @haultrans bTrans, @openinvoice tinyint, @msinv varchar(10), @purgecnt int

   
   select @rcode = 0, @openhauler = 0, @openinvoice = 0, @msg = 'Successful purge.' + char(13)
   
   if @msco is null
    	begin
    	select @msg = 'Missing MS Company!', @rcode = 1
    	goto bspexit
    	end
   if @throughmth is null
    	begin
    	select @msg = 'Missing purge through month!', @rcode = 1
    	goto bspexit
    	end
   -- get GL Company
   select @glco=GLCo from bMSCO where MSCo=@msco
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid MS Company', @rcode = 1
   	goto bspexit
   	end
   -- validate month closed
   select @clsdmth = LastMthSubClsd from bGLCO where GLCo=@glco
   if @@rowcount = 0
       begin
       select @msg = 'Invalid GL Company!', @rcode = 1
       goto bspexit
       end
   if @throughmth > @clsdmth
   	begin
   	select @msg = 'Month must be closed!', @rcode = 1
   	goto bspexit
   	end
   



   -- delete tickets if @purgetickets = 'Y'
   if @purgetickets = 'Y'
   BEGIN
       -- update purge flag in bMSTD to prevent auditing during delete
       update bMSTD set Purge='Y'
       from bMSTD
       join bINLM b on b.INCo=MSCo and b.Loc=FromLoc
       where MSCo=@msco and Mth<=@throughmth and HaulTrans is null and MSInv is null
       and InUseBatchId is null and FromLoc=isnull(@xfromloc,FromLoc)
       and b.LocGroup=isnull(@xlocgroup,b.LocGroup)
       select @validcnt1 = @@rowcount
   
       -- delete MSTD records
       delete bMSTD
       where MSCo=@msco and Mth<=@throughmth and HaulTrans is null and MSInv is null
       and InUseBatchId is null and Purge='Y'
       select @validcnt2 = @@rowcount
   
       if @validcnt1 <> @validcnt2 goto purge_error
   
       select @msg = isnull(@msg,'') + char(13) + char(10) + convert(varchar(10),@validcnt2) + ' Tickets purged.'
   	
   END
   
   
   -- delete haul time sheets if @purgehaulers = 'Y' - bMSHH & bMSTD
   if @purgehaulers = 'Y'
   BEGIN
       -- declare cursor on bMSHH
       declare Hauler cursor LOCAL FAST_FORWARD
   	for select Mth, HaulTrans
       from bMSHH
       where MSCo = @msco and Mth <= @throughmth and InUseBatchId is null
   
       -- open MS Hauler cursor
       open Hauler
       select @openhauler = 1, @purgecnt = 0
   
       -- loop through entries in bMSHH
       Hauler_loop:
       fetch next from Hauler into @mth, @haultrans
   
       if @@fetch_status = -1 goto Hauler_end
       if @@fetch_status <> 0 goto Hauler_loop
   
       -- check that all hauler detail from bMSTD meets the restrictions before setting the purge flags.
       -- Do this so that a partial hauler detail delete will not occur for a haul header (MSHH).
       select @validcnt1 = Count(*) from bMSTD
       where MSCo=@msco and Mth=@mth and HaulTrans=@haultrans
   
       select @validcnt2 = Count(*) from bMSTD d
       join bINLM b on b.INCo=d.MSCo and b.Loc=d.FromLoc
       where d.MSCo = @msco and d.Mth = @mth and d.HaulTrans = @haultrans and d.MSInv is null
   	and d.InUseBatchId is null and d.FromLoc=isnull(@xfromloc,d.FromLoc)
   	and b.LocGroup=isnull(@xlocgroup,b.LocGroup)
   
       -- if counts do not match, goto next Haul time sheet record
       if @validcnt1<>@validcnt2 goto Hauler_loop
   
       -- update bMSTD purge flag
       update bMSTD set Purge='Y'
       where MSCo=@msco and Mth=@mth and HaulTrans=@haultrans
       if @@error <> 0 goto purge_error
       -- update bMSHH purge flag
       update bMSHH set Purge='Y'
       where MSCo=@msco and Mth=@mth and HaulTrans=@haultrans
       if @@error <> 0 goto purge_error
   
       -- delete bMSTD records
       delete bMSTD
       where MSCo=@msco and Mth=@mth and HaulTrans=@haultrans and Purge='Y'
       if @@error <> 0 goto purge_error
       -- delete bMSHH record
       delete bMSHH
       where MSCo=@msco and Mth=@mth and HaulTrans=@haultrans and Purge='Y'
       if @@error <> 0 goto purge_error
       select @purgecnt = @purgecnt + 1	-- increment purge count
   
       goto Hauler_loop
   
       Hauler_end:
           if @openhauler = 1
               begin
               close Hauler
               deallocate Hauler
   	    select @openhauler = 0
               end
   	select @msg = isnull(@msg,'') + char(13) + char(10) + convert(varchar(10),@purgecnt) + ' Hauler Time Sheets purged.'
   END
   
   
   -- delete Invoices if @purgeinvoices = 'Y' - bMSIH, bMSIL, & bMSTD
   if @purgeinvoices = 'Y'
   BEGIN
       -- declare cursor on bMSIH
       declare Invoice cursor LOCAL FAST_FORWARD
   	for select MSInv, Mth
       from bMSIH
       where MSCo=@msco and Mth<=@throughmth and InUseBatchId is null
   	and isnull(Location,'')=isnull(@xfromloc,isnull(Location,''))
   	and isnull(LocGroup,'')=isnull(@xlocgroup,isnull(LocGroup,''))
       -- -- -- and Location=isnull(@xfromloc,Location) and LocGroup=isnull(@xlocgroup,LocGroup)
   
       -- open MS Invoice cursor
       open Invoice
       select @openinvoice = 1, @purgecnt = 0
   
       -- loop through entries in bMSIH
       Invoice_loop:
       fetch next from Invoice into @msinv, @mth
   
       if @@fetch_status = -1 goto Invoice_end
       if @@fetch_status <> 0 goto Invoice_loop
   
       -- check that all invoice detail from bMSTD can be deleted before setting the purge flags.
       select @validcnt1=Count(*) from bMSTD
       where MSCo=@msco and Mth=@mth and MSInv=@msinv and InUseBatchId is null
   
       select @validcnt2=Count(*) from bMSTD
       where MSCo=@msco and Mth=@mth and MSInv=@msinv
   
       -- if counts do not match, goto next Haul time sheet record
       if @validcnt1<>@validcnt2 goto Invoice_loop
   
       -- update bMSTD purge flag
       update bMSTD set Purge='Y'
       where MSCo=@msco and Mth=@mth and MSInv=@msinv and InUseBatchId is null
       if @@error <> 0 goto purge_error
   
       -- delete bMSTD records
       delete bMSTD
       where MSCo=@msco and Mth=@mth and MSInv=@msinv and Purge='Y'
       if @@error <> 0 goto purge_error
       -- delete bMSIL record
       delete bMSIL
       where MSCo=@msco and MSInv=@msinv
       if @@error <> 0 goto purge_error
       -- delete bMSIH record
       delete bMSIH
       where MSCo=@msco and MSInv=@msinv and Mth=@mth
       if @@error <> 0 goto purge_error
       select @purgecnt = @purgecnt + 1	-- increment purge count
   
       goto Invoice_loop
   
       Invoice_end:
           if @openinvoice = 1
               begin
               close Invoice
               deallocate Invoice
   	    select @openinvoice = 0
               end
   	select @msg = isnull(@msg,'') + char(13) + char(10) + convert(varchar(10),@purgecnt) + ' Invoices purged.'
   END
   
   
   -- Purge Sales Activity (bMSSA)
   if @purgesales = 'Y'
   BEGIN
       -- delete MSSA records
       delete bMSSA
       from bMSSA a
       join bINLM b on b.INCo=a.MSCo and b.Loc=a.Loc
       where a.MSCo=@msco and a.Mth<=@throughmth and a.Loc=isnull(@xfromloc,a.Loc)
       	and b.LocGroup=isnull(@xlocgroup,b.LocGroup)
       select @purgecnt = @@rowcount
       select @msg = isnull(@msg,'') + char(13) + char(10) + convert(varchar(10),@purgecnt) + ' Sales Activity entries purged.'
   END
   
   -- Purge Deleted Tickets (bMSTX)
   if @purgedeletedtickets = 'Y'
   begin
   	--purge deleted tickets
   	delete bMSTX
   	from bMSTX x
       	join bINLM b on b.INCo = x.MSCo and b.Loc = x.FromLoc
       	where x.MSCo = @msco and x.Mth <= @throughmth and x.FromLoc = isnull(@xfromloc,x.FromLoc)
       		and b.LocGroup = isnull(@xlocgroup,b.LocGroup)
   	select @purgecnt = @@rowcount
   	select @msg = isnull(@msg,'') + char(13) + char(10) + convert(varchar(10),@purgecnt) + ' Deleted Tickets purged.'
   end
   
   -- -- -- select @msg = @msg + char(13) + char(10)	-- add an extra line to message
   goto bspexit




purge_error:
	select @rcode = 1, @msg = 'Problems with purge - one or more errors detected.'


bspexit:
       if @openhauler = 1
           begin
           close Hauler
           deallocate Hauler
           end
       if @openinvoice = 1
           begin
           close Invoice
           deallocate Invoice
           end
       if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPurge] TO [public]
GO
