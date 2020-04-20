SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPTHOpenUpdate    Script Date: 8/28/99 9:34:05 AM ******/
   CREATE  proc [dbo].[bspAPTHOpenUpdate]
   /********************************************
    *  Created: GG 6/22/99
    *  Modified by: kb 10/29/2 - issue #18878 - fix double quotes
    *		ES 03/12/04 - #23061 isnull wrapping
    *
    *  Used to fix APTH OpenYN flag.
    *  Set to 'Y' if transaction has not been fully paid or cleared
    *  Set to 'N' if transaction is fully paid or cleared
    *
    **********************************************/
   as
   
   declare @co bCompany, @mth bMonth, @aptrans bTrans, @openyn bYN,
   @cnt int, @fixcnt int, @saveopen bYN
   
   set nocount on
   
   select @cnt = 0, @fixcnt = 0
   select 'Fixing the Open flag in bAPTH. Please wait...'
   
	
   declare bcAPTH cursor for
   select APCo, Mth, APTrans, OpenYN from bAPTH
   
   open bcAPTH
   
   APTH_loop:
       fetch next from bcAPTH into @co, @mth, @aptrans, @saveopen
   
       if @@fetch_status <> 0 goto APTH_end
   
       select @openyn = 'N'
       if exists(select * from bAPTD where APCo = @co and Mth = @mth and APTrans = @aptrans
                               and Status < 3) select @openyn = 'Y'
   
       update bAPTH
       set OpenYN = @openyn
       where APCo = @co and Mth = @mth and APTrans = @aptrans
   
       select @cnt = @cnt + 1
       if @openyn <> @saveopen select @fixcnt = @fixcnt + 1
       goto APTH_loop
   
   APTH_end:
       close bcAPTH
       deallocate bcAPTH
       select '# of rows in bAPTH:' + isnull(convert(varchar(10),@cnt), '')
       select '# of rows fixed:' + isnull(convert(varchar(10),@fixcnt), '')

GO
GRANT EXECUTE ON  [dbo].[bspAPTHOpenUpdate] TO [public]
GO
