SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Create Increment function
  CREATE function [dbo].[Increment](@TableName varchar(30), @Lookup varchar(30), @Variable varchar(30))
      returns int
      as
      begin
          return (convert(int,@Variable) + 1)
      end
  
  -- declare @Table varchar(30), @LU varchar(30), @Var varchar(30)
  /*
  set @Table='bPREA'
  set @LU=' 1'
  set @Var='39'
  select dbo.Increment(@Table, @LU, @Var)
  */

GO
