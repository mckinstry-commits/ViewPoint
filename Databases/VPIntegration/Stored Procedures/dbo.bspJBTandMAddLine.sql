SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMAddLine Script Date: 8/28/99 9:32:34 AM ******/
      CREATE proc [dbo].[bspJBTandMAddLine]
      /***********************************************************
       * CREATED BY	: kb 7/24/00
       * MODIFIED BY : kb 2/8/2 - issue #16068
       *
       * USED IN:
       *
       * USAGE:
       *
       * INPUT PARAMETERS
       *
       * OUTPUT PARAMETERS
       *   @msg      error message if error occurs
       * RETURN VALUE
       *   0         success
       *   1         Failure
       *****************************************************/
   
          (@co bCompany, @billmth bMonth, @billnum int, @linekey varchar(100),
          @fromlines bYN, @template varchar(10), @templateseq int, @line int output,
          @msg varchar(255) output)
      as
   
      set nocount on
   
      declare @rcode int, @minline int, @maxline int, @mintempseq int, @maxtempseq int,
      @maxitem bContractItem, @linetype char(1)
   
      select @rcode = 0
   
      select @linetype = Type from bJBTS where JBCo = @co and Template = @template
        and Seq = @templateseq
   
      select @line = Line from bJBIL where JBCo = @co and BillMonth = @billmth
        and BillNumber = @billnum and LineKey = @linekey --and LineType = 'S'
        and LineType = @linetype
   
      if @line is not null
        begin
        if @fromlines = 'N'
            begin
            goto AddLine
            end
        end
   
      select  @minline = max(Line) from bJBIL where JBCo = @co and
        BillMonth = @billmth and BillNumber = @billnum
        and LineKey <= @linekey /*and LineType <> 'T'*/ --and LineType = @linetype
   
      select @minline
   
      select @maxline = min(Line) from bJBIL where JBCo = @co and
        BillMonth = @billmth and BillNumber = @billnum
        and LineKey > @linekey /*and LineType <> 'T'*/ and LineType = @linetype
   
        select @maxline
   
      if @minline is null and @maxline is null
        begin
        select @line = 10
        goto AddLine
        end
   
      if @maxline is not null
        begin
        select @line = isnull(@minline,0) + (@maxline - isnull(@minline,0))/2
        goto AddLine
       end
   
       if @maxline is null
        begin
        NextLine:
        select @line = isnull(@minline,0) + 3
        if exists(select * from bJBIL where JBCo = @co and BillMonth = @billmth
          and BillNumber = @billnum and Line = @line)
           begin
           select @minline = @line
           goto NextLine
           end
        goto AddLine
        end
   
      AddLine:
   
      bspexit:
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMAddLine] TO [public]
GO
