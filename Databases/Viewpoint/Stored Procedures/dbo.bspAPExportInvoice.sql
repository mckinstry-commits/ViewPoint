SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPExportInvoice    Script Date: 8/28/99 9:33:58 AM ******/
   CREATE            proc [dbo].[bspAPExportInvoice]
   /***********************************************************
    * CREATED BY	: DANF 10/17/01
    * MODIFIED BY	: kb 10/28/2 - issue #18878 - fix double quotes
    *					MV 11/26/03 - #23061 isnull wrap
    *
    * USED IN
    *   AP Invoice Export
    * USAGE:
    * This will create a file of AP Invoices.
    * INPUT PARAMETERS
    *   APCo     APCompany
    *   BDate    Begining Date
    *   EDate    Ending Date
    *   File     Exported File Name
    *
    * OUTPUT PARAMETERS
    *   @msg     If error occurs, Error message goes here
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure  '
    *****************************************************/
   
       (@apco bCompany, @BeginDate bDate, @EndDate bDate, @file varchar(256), @database as varchar(300) ,@msg varchar(100) output )
   
   as
   
   set nocount on
   
   declare @rcode int, @s varchar(60), @n varchar(60), @p varchar(60), @a varchar(36)
   declare @Sel varchar(8000), @XString varchar(8000), @Whr varchar(2000) 
   
   select @s = @@SERVERNAME
   
   
   select @Sel = ' select * from ' + isnull(@database,'') + '.dbo.APExport '
   select @Whr = ' where InvDate >= ' + CHAR(39) + isnull(convert(varchar(10),@BeginDate,101), '')  --#23061
   		 + CHAR(39) + ' AND InvDate < ' + CHAR(39) + isnull(convert(varchar(10),@EndDate,101), '')
   		 + CHAR(39) + ' AND APCo = ' + isnull(convert(varchar(3),@apco), '')
   select @Whr = @Whr + ' order by InvDate '
   
   --select @n = name
   
   --select @p = password 
   
   select @XString = 'bcp ''' + isnull(@Sel,'') + isnull(@Whr,'') + ''' queryout ' +char(34)+ isnull(@file, '')  --#23061
   		 +char(34)+  ' -c -S' + isnull(@s, '') + ' -U' + isnull(@n, '') + ' -P' + isnull(@p, '') 
   --select @XString
   exec master..xp_cmdshell @XString
   
   
   
   bspexit:
     /* reset the ending check to what we ended up using*/
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPExportInvoice] TO [public]
GO
