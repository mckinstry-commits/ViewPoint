SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMFormatStripZeros]
   /************************************************************************
   * CREATED:    MH 7/26/00
   * MODIFIED:   CC 3/19/2008 - Issue #122980 - Add support for notes/large fields
   *			 CC 02/03/2009 - Issue #130094 - Changed select to set to prevent optimizations
   *
   * Purpose of Stored Procedure
   *
   *    Remove zeros from in input value depending on a side indicated.
   *
   *
   * Notes about Stored Procedure
   *
   *
   * returns 0 if successfull
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@side varchar(1), @invalue varchar(max), @outvalue varchar(max) output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @valuelen int, @complete int, @pos int, @testval varchar(max)
   
       select @rcode = 0, @complete = 0, @outvalue = ''
   
       --Strip leading zeros
       if @side = 'L'
           begin
               SET @outvalue = @invalue
               while @complete = 0
                   begin
                       if left(@outvalue, 1) = '0'
                           begin
                               SET @pos = (len(@outvalue) - 1)
                               SET @outvalue = right(@outvalue, @pos)
                           end
                       else
                       SET @complete = 1
                   end
           end
   
       --Strip trailing zeros
       if @side = 'R'
           begin
               SET @outvalue = @invalue
               while @complete = 0
                   begin
                       if right(@outvalue, 1) = '0'
                           begin
                               SET @pos = (len(@outvalue) - 1)
                               SET @outvalue = left(@outvalue, @pos)
                           end
                       else
                       SET @complete = 1
                   end
           end
   
       --Strip all zeros
       if @side = 'A'
           begin
               SET @valuelen = len(@invalue)
               while @valuelen > 0
                   begin
                       SET @testval = substring(@invalue, 1, 1)
                       if @testval <> '0'
                           begin
                               SET @outvalue = @outvalue + @testval
                           end
   
                       SET @invalue = substring(@invalue, 2, (len(@invalue)-1))
                       SET @valuelen = len(@invalue)
                   end
           end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMFormatStripZeros] TO [public]
GO
